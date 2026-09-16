# vscode_c_cmake — 纯 C 工程（CMake + SDCC + clangd）

只含 **C**，用 **CMake** 驱动 **SDCC (mcs251)** 构建；编辑器用 **clangd**，靠
`tools/clangd/sdcc_stubs.h` 解析 SDCC 关键字。

```
vscode_c_cmake/
  src/main.c                 UART1 周期打印
  CMakeLists.txt
  cmake/sdcc-mcs251.cmake    SDCC 工具链（FORCED 编译器）
  compile_flags.txt          clangd 专用：-include shim + include 路径（不含 SDCC flag）
  .vscode/                   settings/tasks/extensions/c_cpp_properties
```

## 构建（CMake + SDCC）

要求：CMake ≥ 3.20；SDCC 用仓库预编译包（工具链文件默认指向仓库内的
`tools/sdcc-mcs251-windows-x64/sdcc-mcs251/bin/sdcc.exe`，也可通过 `-DMCS_SDCC=<路径>` 覆盖）。

注意：本工程不能直接让 CMake 继续用默认的 Visual Studio / MSVC 生成器；必须明确指定
`Ninja`，并在重试前清理旧的 `build/` 缓存。

在**仓库根目录**执行：

```powershell
cd examples/vscode_c_cmake
Remove-Item -Recurse -Force build -ErrorAction SilentlyContinue
cmake -S . -B build -G Ninja -D CMAKE_TOOLCHAIN_FILE=cmake/sdcc-mcs251.cmake
cmake --build build
# 产物: build/blink.ihx
```

或从仓库根目录一次写成：

```powershell
Remove-Item -Recurse -Force .\examples\vscode_c_cmake\build -ErrorAction SilentlyContinue
cmake -S .\examples\vscode_c_cmake -B .\examples\vscode_c_cmake\build -G Ninja `
      -D CMAKE_TOOLCHAIN_FILE=cmake/sdcc-mcs251.cmake
cmake --build .\examples\vscode_c_cmake\build
```
（`CMAKE_TOOLCHAIN_FILE` 相对 `-S` 的源目录解析。）

> 关键点：`-G Ninja` 和 `-D CMAKE_TOOLCHAIN_FILE=...` 是必须的；若保留旧的 VS 缓存，CMake 会继续回退到 `cl.exe`，从而把 SDCC 选项都当成 MSVC 参数吞掉。

VS Code：打开本目录 → `Ctrl+Shift+B` 跑默认任务 `cmake: build`。

## 编辑器（clangd）

装扩展 `llvm-vs-code-extensions.vscode-clangd`（`.vscode/extensions.json` 已推荐），并关掉
Microsoft C/C++ 的 IntelliSense（`.vscode/settings.json` 里 `C_Cpp.intelliSenseEngine: disabled`）。

clangd 读**根目录 `compile_flags.txt`**（不是 `build/compile_commands.json`）：
```
-include ../../tools/clangd/sdcc_stubs.h   # SDCC 关键字 shim（不参与构建）
-I ../../lib/include
```
若改用 `build/compile_commands.json`（含 `-mmcs251/--model-large/…` 等 clang 不认的 flag），
需在 `.clangd` 里 `CompileFlags.Remove` 掉它们。

## 说明

- 真构建只走 SDCC；`sdcc_stubs.h` 仅编辑器可见，不影响 `.ihx`。
- 多行 `__asm`（如 `lib/mdu/mdu.c`）clang 无法解析会报错；单行已用 `__SDCC_STUB__` 包（`mcs_intrins.h`）。
