# vscode_mixed_xmake_zig — C + Zig 混合工程（xmake 与 build.zig 各管一套）

C 与 Zig 混编（AI8051U / MCS-251）：C 调 Zig 的 `zig_calc()`，UART1 打印结果。
**同目录下 xmake.lua 与 build.zig 互不干扰**，各自都能独立完成整套构建。

```
vscode_mixed_xmake_zig/
  src/main.c              C：UART 打印 + 调 zig_calc()
  src/lib.zig             Zig：export fn zig_calc(u8) u8
  xmake.lua               独立 xmake 工程（C 用 SDCC，Zig 用自举编译器）
  build.zig               独立 build.zig 工程（编排 SDCC + 自举编译器）
  compile_flags.txt       clangd 专用（C 侧）：-include shim + include 路径
  .vscode/                settings/tasks/extensions/c_cpp_properties
```

## 用 xmake 构建

```powershell
cd examples\vscode_mixed_xmake_zig
xmake f -P .                 # 注意：嵌套工程要 `动作 -P .`
xmake build -P . app         # 产物 app.ihx
```

## 用 build.zig 构建（系统 zig 跑，只做编排）

```powershell
cd examples\vscode_mixed_xmake_zig
zig build                    # 产物 app.ihx
zig build -Dmcs-small=true   # Zig 侧 -OReleaseSmall
zig build -Dmcs-zig=<路径>   # 指定 MCS 自举编译器
```

两者步骤相同：`sdcc -c main.c` → `zig build-obj lib.zig`（自举编译器）→
`fix_mcs_labels.py`+`mcs_opt.py` → `sdas251` → `sdcc` 链接（`--code-loc 0xff0000`）。

## 验证（QEMU 无板）

```bash
wsl -e bash tools/qemu_mcs_run.sh examples/vscode_mixed_xmake_zig/app.ihx
# 串口 9600：zig_calc(5)=22
```

## 编辑器（clangd）

C 侧用 **clangd**：读根目录 `compile_flags.txt`，`-include tools/clangd/sdcc_stubs.h`
解析 SDCC 关键字（`__sfr/__at/__xdata/__interrupt…`，不参与构建）。
装扩展 `llvm-vs-code-extensions.vscode-clangd` 与 `ziglang.vscode-zig`（`.vscode/extensions.json`）。

## 说明

- 自举编译器默认 `../../compiler/zig-out/bin/zig.exe`；没构建先按仓库根 README/AGENTS 重建。
- C↔Zig 走 SDCC ABI（首标量 DPL/DPH/B/A，`--stack-auto`）。
- 输出与中间件在本目录（已 `.gitignore`）。
