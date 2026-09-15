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
    local ovl = path.join(projdir, "tools/mcs_overlay.py")
    if os.isfile(ovl) then
        os.vrunv(python, {ovl, asm})
    end
end
