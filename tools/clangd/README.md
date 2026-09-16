# tools/clangd — SDCC 关键字 shim（仅供编辑器）

`sdcc_stubs.h` 把 SDCC 扩展关键字映射成 clang 能懂的形式，让 **clangd** 能解析
`c51.h` / `ai8051u_sfr.h` 等头文件、消除红波浪线。**它不参与真实构建**（SDCC 自带这些关键字）。

## 在工程里怎么接

每个 C 工程根目录放 `compile_flags.txt`（clangd 自动读取）：

```
-x
c
-std=c11
-ffreestanding
-include
<相对本工程>/tools/clangd/sdcc_stubs.h
-I
<相对本工程>/lib/include
```

或用 `.clangd`：

```yaml
CompileFlags:
  Compiler: clang
  Add: [ '-include', '<repo>/tools/clangd/sdcc_stubs.h', '-I', '<repo>/lib/include' ]
```

示例：`examples/vscode_c_cmake/`、`examples/vscode_mixed_xmake_zig/`。

## 已处理

`__sfr`/`__sbit`/`__at`/`__data`/`__idata`/`__pdata`/`__xdata`/`__far`/`__code`/`__bit`/
`__interrupt`/`__using`/`__naked`/`__reentrant`/`__critical` 等。

## 内联汇编（`__asm … __endasm;`）

clang 不认 SDCC asm（内容非 C token），本 shim 把 `__asm`/`__endasm` 置空；源码里用
`#ifndef __SDCC_STUB__` 包住 asm 给出编辑器空实现：

- 已处理：`lib/include/mcs_intrins.h`（单行 asm）。
- 未处理：`lib/mdu/mdu.c`（多行 asm 块，clangd 里会报错，可忽略或按同样方式加 guard）。

## 验证（本机 LLVM clang）

```powershell
clang -fsyntax-only -x c -std=c11 -ffreestanding `
  -include tools/clangd/sdcc_stubs.h -I lib/include examples\vscode_c_cmake\src\main.c
```
