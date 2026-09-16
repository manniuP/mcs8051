-- 设备描述（devices/**.toml）→ 构建输入。
--   device_sdcc_args : 取 `mcs_device.py --emit sdcc-args` 的链接参数（--code-loc/--data-loc/…）
--   device_emit      : 生成 sdcc 命令文件 / crt0 骨架（写成文件）
--   device_sfr_header: 由 mcs_sfr.py 生成 SDCC SFR 头（写成文件）
function device_sdcc_args(projdir, device)
    local python = get_config("python")
    local tool = path.join(projdir, "tools/mcs_device.py")
    local out = os.iorunv(python, {tool, device, "--emit", "sdcc-args"})
    local args = {}
    for w in tostring(out):gmatch("%S+") do table.insert(args, w) end
    return args
end

function device_emit(projdir, device, emit, outfile, extra)
    local python = get_config("python")
    local tool = path.join(projdir, "tools/mcs_device.py")
    local argv = {tool, device, "--emit", emit}
    if extra then for _, a in ipairs(extra) do table.insert(argv, a) end end
    io.writefile(outfile, os.iorunv(python, argv))
    return outfile
end

-- 设备内存模型 JSON（内联给后端，供 MCS_DEVICE 环境变量；见 codegen/mcs/device.zig）
function device_json(projdir, device)
    local python = get_config("python")
    local tool = path.join(projdir, "tools/mcs_device.py")
    local out = tostring(os.iorunv(python, {tool, device, "--emit", "compiler-json"}))
    return (out:gsub("%s+$", ""))
end

function device_sfr_header(projdir, device, outfile)
    local python = get_config("python")
    local tool = path.join(projdir, "tools/mcs_sfr.py")
    io.writefile(outfile, os.iorunv(python, {tool, "--device", device, "--emit", "c"}))
    return outfile
end

function device_sfr_zig(projdir, device, outfile)
    local python = get_config("python")
    local tool = path.join(projdir, "tools/mcs_sfr.py")
    io.writefile(outfile, os.iorunv(python, {tool, "--device", device, "--emit", "zig"}))
    return outfile
end

-- xmake/helpers.lua —— 供 xmake.lua 的 on_build 通过 import("helpers") 复用。
--
-- 背景：xmake 的 on_build 在沙箱里执行，**看不到 xmake.lua 脚本级函数**，
-- 故公共构建逻辑放本模块，目标里用 `import("helpers")` 引入后调用。

-- 对 Zig→asm 产物做构建层后处理：修局部标签重名 + 局部瘦身 + MCS-51 帧叠加。
-- 各步骤都在 tools/ 下，找不到就跳过（便于裁剪源码树）。
-- mcs_overlay 只处理 `_frkN`（MCS-51 静态帧）；对 mcs251（@spx 帧）是空操作，故可无条件调用。
function postprocess_asm(projdir, asm)
    local python = get_config("python")
    local fixer = path.join(projdir, "tools/fix_mcs_labels.py")
    if os.isfile(fixer) then
        os.vrunv(python, {fixer, asm})
    end
    local opt = path.join(projdir, "tools/mcs_opt.py")
    if os.isfile(opt) then
        os.vrunv(python, {opt, asm})
    end
    -- IR 提示消费 + 死 store 消除（mcs251 有效；mcs51 无 @spx，空操作）。
    local ir = path.join(projdir, "tools/mcs_ir.py")
    if os.isfile(ir) then
        os.vrunv(python, {ir, asm})
    end
    local ovl = path.join(projdir, "tools/mcs_overlay.py")
    if os.isfile(ovl) then
        os.vrunv(python, {ovl, asm})
    end
end

-- 构建层死代码回收（未使用函数/变量）：对一批 .asm 做跨模块可达性分析，
-- 以 keep 文件（入口/main/IVT/crt0）为根删掉不可达的全局符号块，再把**非 keep** 的
-- .asm 重新汇编回 .rel（就地覆盖 SDCC 产出的 .rel）。工具缺失则跳过。
--   entries: { {asm=<path>, rel=<path>}, ... }
--   keep:    { <asm path>, ... }
function dce_rel(projdir, sdas, python, entries, keep)
    local dce = path.join(projdir, "tools/mcs_dce.py")
    if not os.isfile(dce) then return end
    local args = {dce}
    for _, k in ipairs(keep) do
        table.insert(args, "--keep"); table.insert(args, k)
    end
    for _, e in ipairs(entries) do
        table.insert(args, e.asm)
    end
    os.vrunv(python, args)
    for _, e in ipairs(entries) do
        local iskeep = false
        for _, k in ipairs(keep) do if k == e.asm then iskeep = true end end
        if not iskeep then
            os.vrunv(sdas, {"-plosgffw", e.rel, e.asm})
        end
    end
end
