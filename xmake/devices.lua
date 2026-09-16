-- xmake/devices.lua —— 设备表驱动的构建目标
--
-- 用法：
--   xmake f --mcs_arch=mcs251 --device=devices/stc/ai8051u-34k64.toml
--   xmake build devhdr     # 生成 SFR 头(C) / Zig 地址模块 / crt0 / .lk 到 build/devices/
--   xmake build devled     # 用设备表推导的链接布局，构建 C 点灯（mcs251）
--
-- 设备描述是链接布局/启动/SFR 的唯一真源；不再在各目标里硬编码
-- --code-loc/--data-loc/--xram-loc。

target("devhdr")
    set_kind("phony")

    on_build(function(target)
        local projdir = os.projectdir()
        local device = path.join(projdir, get_config("device"))
        if not os.isfile(device) then
            raise("找不到设备描述：" .. device .. "（用 --device 指定）")
        end
        local out = path.join(projdir, "build/devices")
        if not os.isdir(path.join(projdir, "build")) then os.mkdir(path.join(projdir, "build")) end
        if not os.isdir(out) then os.mkdir(out) end

        local helpers = import("xmake.helpers", {rootdir = projdir})
        print("设备: " .. get_config("device"))
        helpers.device_sfr_header(projdir, device, path.join(out, "device_sfr.h"))
        helpers.device_sfr_zig(projdir, device, path.join(out, "device_sfr.zig"))
        helpers.device_emit(projdir, device, "lk", path.join(out, "device.lk"), {"--ihx", "app.ihx"})
        helpers.device_emit(projdir, device, "crt0", path.join(out, "crt0_device.asm"))
        print("OK -> " .. out .. "（device_sfr.h / device_sfr.zig / device.lk / crt0_device.asm）")
    end)

    on_run(function(target)
        local out = path.join(os.projectdir(), "build/devices")
        if not os.isdir(out) then raise("先 xmake build devhdr") end
        print("产物目录：" .. out)
    end)

-- devzig：纯 Zig（无 C）示例，演示「新编译器」：
--   1) SFR 地址来自生成的 dev 模块；2) 变量放置由 MCS_DEVICE 自动决定。
target("devzig")
    set_kind("phony")

    on_build(function(target)
        local arch = get_config("mcs_arch")
        if arch ~= "mcs251" then
            raise("devzig 仅支持 mcs251（加 --mcs_arch=mcs251）")
        end
        local projdir = os.projectdir()
        local scriptdir = path.join(projdir, "examples/ai8051u_dev")
        local sdcc = get_config("sdcc251")
        local sdas = path.join(path.directory(sdcc), "sdas251.exe")
        local zig = get_config("zig")
        for _, tool in ipairs({sdcc, sdas, zig}) do
            if not os.isfile(tool) then raise("找不到工具：" .. tool) end
        end
        local device = path.join(projdir, get_config("device"))
        if not os.isfile(device) then raise("找不到设备描述：" .. device) end

        local helpers = import("xmake.helpers", {rootdir = projdir})
        local genout = path.join(projdir, "build/devices")
        if not os.isdir(path.join(projdir, "build")) then os.mkdir(path.join(projdir, "build")) end
        if not os.isdir(genout) then os.mkdir(genout) end
        helpers.device_sfr_zig(projdir, device, path.join(genout, "device_sfr.zig"))

        -- [1/5] Zig -> asm（携带设备内存模型 + dev 模块）
        print("[1/5] Zig -> asm  : led.zig（MCS_DEVICE 驱动放置）")
        os.setenv("ZIG_LIB_DIR", path.join(projdir, "compiler/lib"))
        local zig_cache = path.join(projdir, ".zig-cache")
        if not os.isdir(zig_cache) then os.mkdir(zig_cache) end
        os.setenv("ZIG_GLOBAL_CACHE_DIR", zig_cache)
        os.setenv("MCS_DEVICE", helpers.device_json(projdir, device))
        local led_zig = path.join(scriptdir, "led.zig")
        local led_asm = path.join(scriptdir, "led.asm")
        os.vrunv(zig, {"build-obj", (get_config("mcs_small") and "-OReleaseSmall" or "-ODebug"),
                       "-target", "mcs251-freestanding",
                       "--dep", "mcs", "--dep", "dev",
                       "-Mroot=" .. led_zig,
                       "-Mmcs=" .. path.join(projdir, "lib/mcs251.zig"),
                       "-Mdev=" .. path.join(genout, "device_sfr.zig"),
                       "-femit-bin=" .. led_asm})

        -- [2/5] 后处理（修标签重名 + 瘦身）
        helpers.postprocess_asm(projdir, led_asm)

        -- [3/5] asm -> rel
        local led_rel = path.join(scriptdir, "led.rel")
        print("[3/5] asm -> rel : led.asm")
        os.vrunv(sdas, {"-plosgffw", led_rel, led_asm})

        -- [4/5] crt0 -> rel
        local crt0_rel = path.join(scriptdir, "crt0.rel")
        print("[4/5] crt0 -> rel: crt0.asm")
        os.vrunv(sdas, {"-plosgffw", crt0_rel, path.join(scriptdir, "crt0.asm")})

        -- [5/5] link（参数来自设备表）
        local ihx = path.join(scriptdir, "dev.ihx")
        local devargs = helpers.device_sdcc_args(projdir, device)
        table.insert(devargs, 1, "-mmcs251")
        print("[5/5] link -> ihx : dev.ihx")
        os.vrunv(sdcc, table.join(devargs, {crt0_rel, led_rel, "-o", ihx}))

        target:set("targetfile", ihx)
        print("OK -> " .. ihx)
    end)

    on_clean(function(target)
        local scriptdir = path.join(os.projectdir(), "examples/ai8051u_dev")
        for _, n in ipairs({"led.asm", "led.rel", "crt0.rel", "dev.ihx", "dev.lk", "dev.map", "dev.mem"}) do
            os.tryrm(path.join(scriptdir, n))
        end
    end)

    on_run(function(target)
        local ihx = target:get("targetfile")
        if not ihx or not os.isfile(ihx) then
            raise("还没构建，先 xmake f --mcs_arch=mcs251; xmake build devzig")
        end
        print("产物：" .. ihx .. "（" .. os.filesize(ihx) .. " 字节）")
    end)

target("devled")
    set_kind("phony")

    on_build(function(target)
        local arch = get_config("mcs_arch")
        if arch ~= "mcs251" then
            raise("devled 仅支持 mcs251（加 --mcs_arch=mcs251）")
        end
        local projdir = os.projectdir()
        local scriptdir = path.join(projdir, "examples/ai8051u_led")
        local incdir = path.join(projdir, "lib/include")
        local haldir = path.join(projdir, "lib/stc-hal")
        local sdcc = get_config("sdcc251")
        if not os.isfile(sdcc) then
            raise("找不到工具：" .. sdcc .. "（用 --sdcc251 覆盖路径）")
        end
        local device = path.join(projdir, get_config("device"))
        if not os.isfile(device) then
            raise("找不到设备描述：" .. device .. "（用 --device 指定）")
        end

        local helpers = import("xmake.helpers", {rootdir = projdir})
        local devargs = helpers.device_sdcc_args(projdir, device)
        print("设备链接参数: " .. table.concat(devargs, " "))

        local main_c    = path.join(scriptdir, "main.c")
        local delay_c   = path.join(haldir, "AI8051U_Delay.c")
        local main_rel  = path.join(scriptdir, "main.rel")
        local delay_rel = path.join(scriptdir, "delay.rel")
        local ihx       = path.join(scriptdir, "devled.ihx")
        local cflags    = {"-mmcs251", "--model-large", "-I", incdir, "-I", haldir}

        print("[1/3] C -> rel   : main.c, AI8051U_Delay.c")
        os.vrunv(sdcc, table.join(cflags, {"-c", main_c, "-o", main_rel}))
        os.vrunv(sdcc, table.join(cflags, {"-c", delay_c, "-o", delay_rel}))
        print("[2/3] link -> ihx: devled.ihx（参数来自设备表）")
        if not table.find(devargs, "-mmcs251") then table.insert(devargs, 1, "-mmcs251") end
        os.vrunv(sdcc, table.join(devargs, {main_rel, delay_rel, "-o", ihx}))
        print("[3/3] 设备 SFR 头 -> build/devices")
        local geninc = path.join(projdir, "build/devices")
        if not os.isdir(path.join(projdir, "build")) then os.mkdir(path.join(projdir, "build")) end
        if not os.isdir(geninc) then os.mkdir(geninc) end
        helpers.device_sfr_header(projdir, device, path.join(geninc, "device_sfr.h"))

        target:set("targetfile", ihx)
        print("OK -> " .. ihx)
    end)

    on_clean(function(target)
        local projdir = os.projectdir()
        local scriptdir = path.join(projdir, "examples/ai8051u_led")
        for _, n in ipairs({"main.rel", "delay.rel", "devled.ihx", "devled.lk", "devled.map", "devled.mem"}) do
            os.tryrm(path.join(scriptdir, n))
        end
    end)

    on_run(function(target)
        local ihx = target:get("targetfile")
        if not ihx or not os.isfile(ihx) then
            raise("还没构建，先 xmake f --mcs_arch=mcs251; xmake build devled")
        end
        print("产物：" .. ihx .. "（" .. os.filesize(ihx) .. " 字节）")
    end)
