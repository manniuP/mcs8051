-- vscode_mixed_xmake_zig —— C + Zig 混合工程，**独立**的 xmake 工程。
--
-- 用法：
--   xmake f --mcs_small=n        # 可选：y 走 -OReleaseSmall
--   xmake build app              # 产物 app.ihx
--
-- C 走 SDCC，Zig 走仓库自举编译器（compiler/zig-out/bin/zig.exe），最后 sdcc 链接。
-- 与同目录的 build.zig **互不干扰**（各自可独立完成整套构建）。

set_project("vscode_mixed_xmake_zig")
set_version("0.1.0")

local PROJ = os.projectdir()
local REPO = path.join(PROJ, "../..")

option("zig")
    set_default(os.getenv("MCS_ZIG") or path.join(REPO, "compiler/zig-out/bin/zig.exe"))
    set_showmenu(true)
    set_description("MCS 自举 zig 编译器路径")

option("sdcc251")
    set_default(os.getenv("SDCC251") or path.join(REPO, "tools/sdcc-mcs251-windows-x64/sdcc-mcs251/bin/sdcc.exe"))
    set_showmenu(true)
    set_description("SDCC (mcs251) 路径")

option("python")
    set_default(os.getenv("PYTHON") or "python")
    set_showmenu(true)
    set_description("Python 解释器（tools/fix_mcs_labels.py、mcs_opt.py）")

option("mcs_small")
    set_default(false)
    set_showmenu(true)
    set_description("Zig 后端激进尺寸（-OReleaseSmall）")

target("app")
    set_kind("phony")

    on_build(function(target)
        local projdir = os.projectdir()
        local repo = path.join(projdir, "../..")
        local sdcc = get_config("sdcc251")
        local sdas = path.join(path.directory(sdcc), "sdas251.exe")
        local zig = get_config("zig")
        local py = get_config("python")
        local inc = path.join(repo, "lib/include")

        for _, t in ipairs({sdcc, sdas, zig}) do
            if not os.isfile(t) then raise("找不到工具：" .. t) end
        end

        local main_c  = path.join(projdir, "src/main.c")
        local zig_src = path.join(projdir, "src/lib.zig")
        local main_rel = path.join(projdir, "main.rel")
        local zig_asm  = path.join(projdir, "lib.asm")
        local zig_rel  = path.join(projdir, "lib.rel")
        local ihx      = path.join(projdir, "app.ihx")

        print("[1/4] C -> rel    : src/main.c")
        os.vrunv(sdcc, {"-mmcs251", "--model-large", "--stack-auto",
                        "-I", inc, "-c", main_c, "-o", main_rel})

        print("[2/4] Zig -> asm  : src/lib.zig")
        os.setenv("ZIG_LIB_DIR", path.join(repo, "compiler/lib"))
        local zig_cache = path.join(repo, ".zig-cache")
        if not os.isdir(zig_cache) then os.mkdir(zig_cache) end
        os.setenv("ZIG_GLOBAL_CACHE_DIR", zig_cache)
        os.vrunv(zig, {"build-obj", (get_config("mcs_small") and "-OReleaseSmall" or "-ODebug"),
                       "-target", "mcs251-freestanding", "-femit-bin=" .. zig_asm, zig_src})

        print("[3/4] asm 后处理 + -> rel : lib.asm")
        os.vrunv(py, {path.join(repo, "tools/fix_mcs_labels.py"), zig_asm})
        os.vrunv(py, {path.join(repo, "tools/mcs_opt.py"), zig_asm})
        os.vrunv(sdas, {"-plosgffw", zig_rel, zig_asm})

        print("[4/4] link -> ihx: app.ihx")
        os.vrunv(sdcc, {"-mmcs251", "--model-large", "--code-loc", "0xff0000",
                        "--data-loc", "0x30", "--idata-loc", "0x80",
                        main_rel, zig_rel, "-o", ihx})

        target:set("targetfile", ihx)
        print("OK -> " .. ihx)
    end)

    on_clean(function(target)
        for _, n in ipairs({"main.rel", "lib.asm", "lib.rel", "lib.lst", "lib.sym", "lib.rst",
                            "app.lk", "app.ihx", "app.map", "app.mem"}) do
            os.tryrm(path.join(os.projectdir(), n))
        end
    end)
