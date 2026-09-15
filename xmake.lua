-- mcs251/xmake.lua
-- Zig + C 混合构建，目标 Intel 8051（MCS-51）与 80251（MCS-251）。
--
-- 用法：
--   xmake build blink                          # 默认 mcs51，用系统 SDCC
--   xmake build --mcs-arch=mcs251 blink        # 切到 mcs251，用预编译 sdcc-mcs251
--   xmake build --mcs-arch=mcs251 --sdcc=/path/sdcc.exe blink
--   xmake run blink                            # 输出 blink.ihx 路径
--
-- 工具链默认路径（可被 --xxx 选项或 XXX 环境变量覆盖）：
--   --mcs-arch    MCS 架构，mcs51（默认）或 mcs251
--   --sdcc        sdcc 主驱动器
--   --zig         自举 zig 编译器（用于后端生成 ASxxxx 汇编）
--   --sdcc251     mcs251 模式下的 sdcc.exe（默认：预编译包）
--   --crt0        启动汇编文件路径
--
-- 流水线：
--   C    -> .rel  : sdcc -mmcs{51,251} --model-large -c
--   Zig  -> .asm  : zig build-obj -target mcs{51,251}-freestanding -femit-bin
--   .asm -> .rel  : sdas{8051,251} -plosgffw
--   .rel -> .ihx  : sdcc -mmcs{51,251} --model-large (自动带启动代码 + 运行时库)

option("mcs_arch")
    set_values("mcs51", "mcs251")
    set_default("mcs51")
    set_showmenu(true)
    set_description("目标架构：mcs51（默认）或 mcs251")

option("sdcc")
    set_default(os.getenv("SDCC") or "C:\\Program Files (x86)\\SDCC\\bin\\sdcc.exe")
    set_showmenu(true)
    set_description("SDCC 主驱动器路径（mcs51 模式用）")

option("zig")
    set_default(os.getenv("ZIG") or
        (os.isfile(path.join(os.projectdir(), "zig/zig-out/bin/zig.exe"))
            and path.join(os.projectdir(), "zig/zig-out/bin/zig.exe"))
        or path.join(os.projectdir(), "tools/zig-bootstrap/zig.exe"))
    set_showmenu(true)
    set_description("自举 zig 编译器路径（优先 zig/zig-out/bin/zig.exe，退回 tools/zig-bootstrap）")

option("sdcc251")
    set_default(os.getenv("SDCC251") or path.join(os.projectdir(),
        "sdcc-mcs251-windows-x64/sdcc-mcs251/bin/sdcc.exe"))
    set_showmenu(true)
    set_description("mcs251 模式下的 sdcc.exe（预编译包路径）")

option("python")
    set_default(os.getenv("PYTHON") or "python")
    set_showmenu(true)
    set_description("Python 解释器（跑 tools/fix_mcs_labels.py，修局部标签重名）")

target("blink")
    set_kind("phony")

    on_build(function(target)
        local arch = get_config("mcs_arch")
        local projdir = os.projectdir()
        local scriptdir = path.join(projdir, "projects/ai8051u_blink")
        local incdir = path.join(projdir, "include")
        local haldir = path.join(projdir, "port/stc-hal")

        -- 按 arch 选工具链与参数
        local sdcc, sdas, model_opt, target_flag
        if arch == "mcs251" then
            sdcc = get_config("sdcc251")
            sdas = path.join(path.directory(sdcc), "sdas251.exe")
            model_opt = "-mmcs251"
            target_flag = "mcs251-freestanding"
        else
            sdcc = get_config("sdcc")
            sdas = path.join(path.directory(sdcc), "sdas8051.exe")
            model_opt = "-mmcs51"
            target_flag = "mcs51-freestanding"
        end
        local zig = get_config("zig")

        -- 工具链存在性检查
        for _, tool in ipairs({sdcc, sdas, zig}) do
            if not os.isfile(tool) then
                raise("找不到工具：" .. tool .. "（用 --sdcc / --zig / --sdcc251 覆盖路径）")
            end
        end

        -- 输入与中间产物路径
        local main_c   = path.join(scriptdir, "main.c")
        local delay_c  = path.join(haldir, "AI8051U_Delay.c")
        local led_zig  = path.join(scriptdir, "led.zig")
        local main_rel  = path.join(scriptdir, "main.rel")
        local delay_rel = path.join(scriptdir, "delay.rel")
        local led_asm   = path.join(scriptdir, "led.asm")
        local led_rel   = path.join(scriptdir, "led.rel")
        local ihx       = path.join(scriptdir, "blink.ihx")

        local inc_args = {"-I", incdir, "-I", haldir}

        -- [1/4] C -> .rel
        print(("[1/4] C -> rel   : %s, %s"):format(path.filename(main_c), path.filename(delay_c)))
        os.vrunv(sdcc, table.join({model_opt, "--model-large"}, inc_args, {"-c", main_c, "-o", main_rel}))
        os.vrunv(sdcc, table.join({model_opt, "--model-large"}, inc_args, {"-c", delay_c, "-o", delay_rel}))

        -- [2/4] Zig -> .asm
        print(("[2/4] Zig -> asm  : %s"):format(path.filename(led_zig)))
        os.setenv("ZIG_LIB_DIR", path.join(projdir, "zig/lib"))
        -- zig 默认全局缓存在 %LOCALAPPDATA%\zig\tmp，沙盒或只读环境不可写；
        -- 重定向到当前项目的 .zig-cache 目录。
        local zig_cache = path.join(projdir, ".zig-cache")
        if not os.isdir(zig_cache) then os.mkdir(zig_cache) end
        os.setenv("ZIG_GLOBAL_CACHE_DIR", zig_cache)
        os.vrunv(zig, {"build-obj", "-target", target_flag, "-femit-bin=" .. led_asm, led_zig})

        -- [2.5/4] 修局部标签重名：后端每个函数从 0 重新编号 L<n>，同一 .asm 内
        -- 多个含分支的函数会撞名（sdas 报 multiple definitions / phase error）。
        local fixer = path.join(projdir, "tools/fix_mcs_labels.py")
        if os.isfile(fixer) then
            os.vrunv(get_config("python"), {fixer, led_asm})
        end

        -- [3/4] .asm -> .rel
        print(("[3/4] asm -> rel  : %s"):format(path.filename(led_asm)))
        os.vrunv(sdas, {"-plosgffw", led_rel, led_asm})

        -- [4/4] link -> .ihx
        print(("[4/4] link -> ihx : %s"):format(path.filename(ihx)))
        local link_args = table.join({model_opt, "--model-large"}, {main_rel, delay_rel, led_rel, "-o", ihx})
        if arch == "mcs251" then
            -- AI8051U 程序存储器在 FF:0000-FF:FFFF，复位 PC=FF:0000
            table.insert(link_args, #link_args - 1, "--code-loc")
            table.insert(link_args, #link_args - 1, "0xff0000")
        end
        os.vrunv(sdcc, link_args)

        -- 把产物登记到 target，让 xmake 知道有文件输出了
        target:set("targetfile", ihx)
        print("OK -> " .. ihx)
    end)

    on_clean(function(target)
        local projdir = os.projectdir()
        local scriptdir = path.join(projdir, "projects/ai8051u_blink")
        for _, name in ipairs({"main.rel", "main.asm", "main.ihx", "main.lk", "main.lst", "main.sym", "main.rst", "main.mem",
                              "delay.rel", "delay.asm", "delay.ihx", "delay.lk", "delay.lst", "delay.sym", "delay.rst", "delay.mem",
                              "led.rel", "led.asm", "led.ihx", "led.lst", "led.sym", "led.rst",
                              "blink.ihx", "blink.lk", "blink.map", "blink.mem", "blink.lst", "blink.sym", "blink.rst"}) do
            os.tryrm(path.join(scriptdir, name))
        end
    end)

    on_run(function(target)
        local ihx = target:get("targetfile")
        if not ihx or not os.isfile(ihx) then
            raise("还没构建，先 xmake build blink")
        end
        print("产物：" .. ihx .. "（" .. os.filesize(ihx) .. " 字节）")
    end)

-- ptrtest：M3 里程碑的 C + Zig 混编验证（3 字节指针互操作）。
-- 只走“zig 编译 zig 源 -> sdas251 -> sdcc 编译 C -> sdcc 链接”的直连管线，
-- 不使用自举编译器。
-- 用法：xmake build --mcs-arch=mcs251 ptrtest
target("ptrtest")
    set_kind("phony")

    on_build(function(target)
        local arch = get_config("mcs_arch")
        if arch ~= "mcs251" then
            raise("ptrtest 仅支持 mcs251（加 --mcs-arch=mcs251）")
        end
        local projdir = os.projectdir()
        local scriptdir = path.join(projdir, "projects/ai8051u_ptrtest")
        local incdir = path.join(projdir, "include")
        local uartdir = path.join(projdir, "port/uart251")
        local haldir = path.join(projdir, "port/stc-hal")

        local sdcc = get_config("sdcc251")
        local sdas = path.join(path.directory(sdcc), "sdas251.exe")
        local zig = get_config("zig")

        for _, tool in ipairs({sdcc, sdas, zig}) do
            if not os.isfile(tool) then
                raise("找不到工具：" .. tool .. "（用 --sdcc251 / --zig 覆盖路径）")
            end
        end

        local main_c   = path.join(scriptdir, "main.c")
        local uart_c   = path.join(uartdir, "uart251.c")
        local delay_c  = path.join(haldir, "AI8051U_Delay.c")
        local zig_src  = path.join(scriptdir, "ptrtest.zig")
        local main_rel = path.join(scriptdir, "main.rel")
        local uart_rel = path.join(scriptdir, "uart251.rel")
        local delay_rel = path.join(scriptdir, "delay.rel")
        local zig_asm  = path.join(scriptdir, "ptrtest.asm")
        local zig_rel  = path.join(scriptdir, "ptrtest.rel")
        local ihx      = path.join(scriptdir, "ptrtest.ihx")

        -- [1/5] C -> .rel
        print("[1/5] C -> rel   : main.c, uart251.c, AI8051U_Delay.c")
        os.vrunv(sdcc, {"-mmcs251", "--model-large", "-I", incdir, "-I", uartdir, "-I", haldir, "-c", main_c, "-o", main_rel})
        os.vrunv(sdcc, {"-mmcs251", "--model-large", "-I", incdir, "-I", uartdir, "-I", haldir, "-c", uart_c, "-o", uart_rel})
        os.vrunv(sdcc, {"-mmcs251", "--model-large", "-I", incdir, "-I", uartdir, "-I", haldir, "-c", delay_c, "-o", delay_rel})

        -- [2/5] Zig -> .asm（ZIG_LIB_DIR 指向带 mcs251 目标定义的 zig/lib）
        print("[2/5] Zig -> asm : ptrtest.zig")
        os.setenv("ZIG_LIB_DIR", path.join(projdir, "zig/lib"))
        local zig_cache = path.join(projdir, ".zig-cache")
        if not os.isdir(zig_cache) then os.mkdir(zig_cache) end
        os.setenv("ZIG_GLOBAL_CACHE_DIR", zig_cache)
        os.vrunv(zig, {"build-obj", "-target", "mcs251-freestanding", "-femit-bin=" .. zig_asm, zig_src})

        -- [3/5] 修局部标签重名（同 blink；见 tools/fix_mcs_labels.py）
        local fixer = path.join(projdir, "tools/fix_mcs_labels.py")
        if os.isfile(fixer) then
            os.vrunv(get_config("python"), {fixer, zig_asm})
        end

        -- [4/5] .asm -> .rel
        print("[4/5] asm -> rel : ptrtest.asm")
        os.vrunv(sdas, {"-plosgffw", zig_rel, zig_asm})

        -- [5/5] link -> .ihx（sdcc 自动补启动与运行库）
        -- AI8051U 程序存储器在 FF:0000-FF:FFFF，复位 PC=FF:0000，故代码必须链到 0xff0000
        print("[5/5] link -> ihx: ptrtest.ihx")
        os.vrunv(sdcc, {"-mmcs251", "--model-large", "--code-loc", "0xff0000",
                        main_rel, uart_rel, delay_rel, zig_rel, "-o", ihx})

        target:set("targetfile", ihx)
        print("OK -> " .. ihx)
    end)

    on_clean(function(target)
        local scriptdir = path.join(os.projectdir(), "projects/ai8051u_ptrtest")
        for _, name in ipairs({"main.rel", "main.asm", "main.lst", "main.rst", "main.sym",
                              "ptrtest.asm", "ptrtest.rel", "ptrtest.ihx", "ptrtest.lk",
                              "ptrtest.lst", "ptrtest.map", "ptrtest.mem", "ptrtest.rst", "ptrtest.sym"}) do
            os.tryrm(path.join(scriptdir, name))
        end
    end)

    on_run(function(target)
        local ihx = target:get("targetfile")
        if not ihx or not os.isfile(ihx) then
            raise("还没构建，先 xmake build --mcs-arch=mcs251 ptrtest")
        end
        print("产物：" .. ihx .. "（" .. os.filesize(ihx) .. " 字节）")
    end)

-- simtest：AT89C52 风格的自检测试（C + Zig），可在 ucsim(s51) 软件仿真里跑。
-- 只用标准 8051 SFR，结果写 XRAM（0x0000 status=0xAA 通过 / 0x0001 failcode）。
-- 用法：xmake build --mcs-arch=mcs51 simtest
target("simtest")
    set_kind("phony")

    on_build(function(target)
        local arch = get_config("mcs_arch")
        if arch ~= "mcs51" then
            raise("simtest 仅支持 mcs51（加 --mcs-arch=mcs51）")
        end
        local projdir = os.projectdir()
        local scriptdir = path.join(projdir, "projects/at89c52_sim")

        local sdcc = get_config("sdcc")
        local sdas = path.join(path.directory(sdcc), "sdas8051.exe")
        local zig = get_config("zig")

        for _, tool in ipairs({sdcc, sdas, zig}) do
            if not os.isfile(tool) then
                raise("找不到工具：" .. tool .. "（用 --sdcc / --zig 覆盖路径）")
            end
        end

        local main_c   = path.join(scriptdir, "main.c")
        local zig_src  = path.join(scriptdir, "led.zig")
        local main_rel = path.join(scriptdir, "main.rel")
        local zig_asm  = path.join(scriptdir, "led.asm")
        local zig_rel  = path.join(scriptdir, "led.rel")
        local ihx      = path.join(scriptdir, "simtest.ihx")

        -- [1/4] C -> .rel（--stack-auto：与 Zig 的栈传参约定对齐，支持多参数）
        print("[1/4] C -> rel   : main.c")
        os.vrunv(sdcc, {"-mmcs51", "--model-large", "--stack-auto", "-c", main_c, "-o", main_rel})

        -- [2/4] Zig -> .asm
        print("[2/4] Zig -> asm : led.zig")
        os.setenv("ZIG_LIB_DIR", path.join(projdir, "zig/lib"))
        local zig_cache = path.join(projdir, ".zig-cache")
        if not os.isdir(zig_cache) then os.mkdir(zig_cache) end
        os.setenv("ZIG_GLOBAL_CACHE_DIR", zig_cache)
        os.vrunv(zig, {"build-obj", "-target", "mcs51-freestanding", "-femit-bin=" .. zig_asm, zig_src})

        -- [2.5/4] 修局部标签重名
        local fixer = path.join(projdir, "tools/fix_mcs_labels.py")
        if os.isfile(fixer) then
            os.vrunv(get_config("python"), {fixer, zig_asm})
        end

        -- [3/4] .asm -> .rel
        print("[3/4] asm -> rel : led.asm")
        os.vrunv(sdas, {"-plosgffw", zig_rel, zig_asm})

        -- [4/4] link -> .ihx
        print("[4/4] link -> ihx: simtest.ihx")
        os.vrunv(sdcc, {"-mmcs51", "--model-large", "--stack-auto", main_rel, zig_rel, "-o", ihx})

        target:set("targetfile", ihx)
        print("OK -> " .. ihx)
    end)

    on_clean(function(target)
        local scriptdir = path.join(os.projectdir(), "projects/at89c52_sim")
        for _, name in ipairs({"main.rel", "main.asm", "main.lst", "main.rst", "main.sym",
                              "led.asm", "led.rel", "simtest.ihx", "simtest.lk", "simtest.lst",
                              "simtest.map", "simtest.mem", "simtest.rst", "simtest.sym"}) do
            os.tryrm(path.join(scriptdir, name))
        end
    end)

    on_run(function(target)
        local ihx = target:get("targetfile")
        if not ihx or not os.isfile(ihx) then
            raise("还没构建，先 xmake build --mcs-arch=mcs51 simtest")
        end
        print("产物：" .. ihx .. "（" .. os.filesize(ihx) .. " 字节）")
    end)

-- led：只点灯——P1.1 上的 LED 以 1Hz 闪烁（纯 C，用 STC HAL 的 delay_ms）。
-- 用法：xmake f --mcs_arch=mcs251; xmake build led
target("led")
    set_kind("phony")

    on_build(function(target)
        local arch = get_config("mcs_arch")
        local projdir = os.projectdir()
        local scriptdir = path.join(projdir, "projects/ai8051u_led")
        local incdir = path.join(projdir, "include")
        local haldir = path.join(projdir, "port/stc-hal")

        local sdcc, model_opt
        if arch == "mcs251" then
            sdcc = get_config("sdcc251")
            model_opt = "-mmcs251"
        else
            sdcc = get_config("sdcc")
            model_opt = "-mmcs51"
        end

        if not os.isfile(sdcc) then
            raise("找不到工具：" .. sdcc .. "（用 --sdcc / --sdcc251 覆盖路径）")
        end

        local main_c   = path.join(scriptdir, "main.c")
        local delay_c  = path.join(haldir, "AI8051U_Delay.c")
        local main_rel = path.join(scriptdir, "main.rel")
        local delay_rel = path.join(scriptdir, "delay.rel")
        local ihx      = path.join(scriptdir, "led.ihx")
        local inc_args = {"-I", incdir, "-I", haldir}

        -- [1/3] C -> .rel
        print("[1/3] C -> rel   : main.c, AI8051U_Delay.c")
        os.vrunv(sdcc, table.join({model_opt, "--model-large"}, inc_args, {"-c", main_c, "-o", main_rel}))
        os.vrunv(sdcc, table.join({model_opt, "--model-large"}, inc_args, {"-c", delay_c, "-o", delay_rel}))

        -- [2/3] link -> .ihx（mcs251 需 --code-loc 0xff0000）
        print("[2/3] link -> ihx: led.ihx")
        local link_args
        if arch == "mcs251" then
            link_args = {model_opt, "--model-large", "--code-loc", "0xff0000",
                         main_rel, delay_rel, "-o", ihx}
        else
            link_args = {model_opt, "--model-large", main_rel, delay_rel, "-o", ihx}
        end
        os.vrunv(sdcc, link_args)

        target:set("targetfile", ihx)
        print("OK -> " .. ihx)
    end)

    on_clean(function(target)
        local scriptdir = path.join(os.projectdir(), "projects/ai8051u_led")
        for _, name in ipairs({"main.rel", "main.asm", "main.lst", "main.rst", "main.sym",
                              "delay.rel", "delay.lst", "delay.rst", "delay.sym",
                              "led.ihx", "led.lk", "led.map", "led.mem", "led.lst", "led.rst", "led.sym"}) do
            os.tryrm(path.join(scriptdir, name))
        end
    end)

    on_run(function(target)
        local ihx = target:get("targetfile")
        if not ihx or not os.isfile(ihx) then
            raise("还没构建，先 xmake build --mcs-arch=mcs251 led")
        end
        print("产物：" .. ihx .. "（" .. os.filesize(ihx) .. " 字节）")
    end)

-- uart：UART1(P3.0/P3.1) 9600bps 打印自检（纯 C，用 port/uart251）。
-- 用法：xmake f --mcs_arch=mcs251; xmake build uart
target("uart")
    set_kind("phony")

    on_build(function(target)
        local arch = get_config("mcs_arch")
        local projdir = os.projectdir()
        local scriptdir = path.join(projdir, "projects/ai8051u_uart")
        local incdir = path.join(projdir, "include")
        local haldir = path.join(projdir, "port/stc-hal")
        local uartdir = path.join(projdir, "port/uart251")

        local sdcc, model_opt
        if arch == "mcs251" then
            sdcc = get_config("sdcc251")
            model_opt = "-mmcs251"
        else
            sdcc = get_config("sdcc")
            model_opt = "-mmcs51"
        end

        if not os.isfile(sdcc) then
            raise("找不到工具：" .. sdcc .. "（用 --sdcc / --sdcc251 覆盖路径）")
        end

        local main_c   = path.join(scriptdir, "main.c")
        local uart_c   = path.join(uartdir, "uart251.c")
        local delay_c  = path.join(haldir, "AI8051U_Delay.c")
        local main_rel = path.join(scriptdir, "main.rel")
        local uart_rel = path.join(scriptdir, "uart251.rel")
        local delay_rel = path.join(scriptdir, "delay.rel")
        local ihx      = path.join(scriptdir, "uart.ihx")
        local inc_args = {"-I", incdir, "-I", haldir, "-I", uartdir}

        -- [1/3] C -> .rel
        print("[1/3] C -> rel   : main.c, uart251.c, AI8051U_Delay.c")
        os.vrunv(sdcc, table.join({model_opt, "--model-large"}, inc_args, {"-c", main_c, "-o", main_rel}))
        os.vrunv(sdcc, table.join({model_opt, "--model-large"}, inc_args, {"-c", uart_c, "-o", uart_rel}))
        os.vrunv(sdcc, table.join({model_opt, "--model-large"}, inc_args, {"-c", delay_c, "-o", delay_rel}))

        -- [2/3] link -> .ihx（mcs251 需 --code-loc 0xff0000）
        print("[2/3] link -> ihx: uart.ihx")
        local link_args
        if arch == "mcs251" then
            link_args = {model_opt, "--model-large", "--code-loc", "0xff0000",
                         main_rel, uart_rel, delay_rel, "-o", ihx}
        else
            link_args = {model_opt, "--model-large", main_rel, uart_rel, delay_rel, "-o", ihx}
        end
        os.vrunv(sdcc, link_args)

        target:set("targetfile", ihx)
        print("OK -> " .. ihx)
    end)

    on_clean(function(target)
        local scriptdir = path.join(os.projectdir(), "projects/ai8051u_uart")
        for _, name in ipairs({"main.rel", "main.asm", "main.lst", "main.rst", "main.sym",
                              "uart251.rel", "uart251.lst", "uart251.rst", "uart251.sym",
                              "delay.rel", "delay.lst", "delay.rst", "delay.sym",
                              "uart.ihx", "uart.lk", "uart.map", "uart.mem", "uart.lst", "uart.rst", "uart.sym"}) do
            os.tryrm(path.join(scriptdir, name))
        end
    end)

    on_run(function(target)
        local ihx = target:get("targetfile")
        if not ihx or not os.isfile(ihx) then
            raise("还没构建，先 xmake build --mcs-arch=mcs251 uart")
        end
        print("产物：" .. ihx .. "（" .. os.filesize(ihx) .. " 字节）")
    end)

-- zigled：纯 Zig 点灯（P1.1，约 1Hz），无 C。
-- zig -> sdas251 -> sdcc 链接（配 projects/ai8051u_zig_led/crt0.asm 提供复位入口，
-- --code-loc 0xff0000 = AI8051U 程序存储器起点）。
-- 用法：xmake f --mcs_arch=mcs251; xmake build zigled
target("zigled")
    set_kind("phony")

    on_build(function(target)
        local arch = get_config("mcs_arch")
        if arch ~= "mcs251" then
            raise("zigled 仅支持 mcs251（加 --mcs-arch=mcs251）")
        end
        local projdir = os.projectdir()
        local scriptdir = path.join(projdir, "projects/ai8051u_zig_led")
        local sdcc = get_config("sdcc251")
        local sdas = path.join(path.directory(sdcc), "sdas251.exe")
        local zig = get_config("zig")
        local crt0 = path.join(scriptdir, "crt0.asm")

        for _, tool in ipairs({sdcc, sdas, zig}) do
            if not os.isfile(tool) then
                raise("找不到工具：" .. tool)
            end
        end

        local led_zig  = path.join(scriptdir, "led.zig")
        local led_asm  = path.join(scriptdir, "led.asm")
        local led_rel  = path.join(scriptdir, "led.rel")
        local crt0_rel = path.join(scriptdir, "crt0.rel")
        local ihx      = path.join(scriptdir, "led.ihx")

        -- [1/5] Zig -> .asm
        print("[1/5] Zig -> asm  : led.zig")
        os.setenv("ZIG_LIB_DIR", path.join(projdir, "zig/lib"))
        local zig_cache = path.join(projdir, ".zig-cache")
        if not os.isdir(zig_cache) then os.mkdir(zig_cache) end
        os.setenv("ZIG_GLOBAL_CACHE_DIR", zig_cache)
        os.vrunv(zig, {"build-obj", "-target", "mcs251-freestanding", "-femit-bin=" .. led_asm, led_zig})

        -- [2/5] 修局部标签重名（tools/fix_mcs_labels.py）
        local fixer = path.join(projdir, "tools/fix_mcs_labels.py")
        if os.isfile(fixer) then
            os.vrunv(get_config("python"), {fixer, led_asm})
        end

        -- [3/5] .asm -> .rel
        print("[3/5] asm -> rel : led.asm")
        os.vrunv(sdas, {"-plosgffw", led_rel, led_asm})

        -- [4/5] crt0 -> .rel
        print("[4/5] crt0 -> rel: crt0.asm")
        os.vrunv(sdas, {"-plosgffw", crt0_rel, crt0})

        -- [5/5] sdcc 链接 -> .ihx（--code-loc 0xff0000 = AI8051U 复位入口）
        print("[5/5] link -> ihx : led.ihx")
        os.vrunv(sdcc, {"-mmcs251", "--model-large", "--code-loc", "0xff0000",
                        crt0_rel, led_rel, "-o", ihx})

        target:set("targetfile", ihx)
        print("OK -> " .. ihx)
    end)

    on_clean(function(target)
        local scriptdir = path.join(os.projectdir(), "projects/ai8051u_zig_led")
        for _, name in ipairs({"led.asm", "led.rel", "led.lst", "led.sym", "led.rst",
                              "crt0.rel", "crt0.lst", "crt0.sym", "crt0.rst",
                              "led.lk", "led.ihx", "led.map", "led.mem"}) do
            os.tryrm(path.join(scriptdir, name))
        end
    end)

    on_run(function(target)
        local ihx = target:get("targetfile")
        if not ihx or not os.isfile(ihx) then
            raise("还没构建，先 xmake build --mcs-arch=mcs251 zigled")
        end
        print("产物：" .. ihx .. "（" .. os.filesize(ihx) .. " 字节）")
    end)
