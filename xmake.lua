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
    set_default(os.getenv("ZIG") or path.join(os.projectdir(), "zig/zig-out/bin/zig.exe"))
    set_showmenu(true)
    set_description("自举 zig 编译器路径")

option("sdcc251")
    set_default(os.getenv("SDCC251") or path.join(os.projectdir(),
        "sdcc-mcs251-windows-x64/sdcc-mcs251/bin/sdcc.exe"))
    set_showmenu(true)
    set_description("mcs251 模式下的 sdcc.exe（预编译包路径）")

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

        -- [3/4] .asm -> .rel
        print(("[3/4] asm -> rel  : %s"):format(path.filename(led_asm)))
        os.vrunv(sdas, {"-plosgffw", led_rel, led_asm})

        -- [4/4] link -> .ihx
        print(("[4/4] link -> ihx : %s"):format(path.filename(ihx)))
        os.vrunv(sdcc, {model_opt, "--model-large", main_rel, delay_rel, led_rel, "-o", ihx})

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
