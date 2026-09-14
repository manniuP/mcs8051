# mcs251

面向 Intel 8051（MCS-51）和 80251（MCS-251）的 Zig + C 工具链工作区，目标为 STC 系列芯片。

计划：Zig 前端 + 一个新的自托管后端，输出 SDCC/ASxxxx 汇编；C 代码通过
`sdcc -mmcs51` / `sdcc -mmcs251` 编译；最终用 SDCC 的 `sdld` 链接并使用 SDCC 运行时。
详见 `PLAN.md`。

## 目录结构

    mcs251/
      PLAN.md          清单、ABI 冻结、里程碑
      docs/            中文指南：如何创建 Zig + SDCC 项目
      projects/        可构建的 C + Zig 项目（例如 ai8051u_blink）
      examples/        最小示例
      include/         SDCC 头文件：c51.h、ai8051u_sfr.h、mcs_intrins.h
      port/            STC AI8051U HAL（SDCC）及目标描述测试
      driver/          构建编排（Zig -> asm -> sdas -> sdld，C -> sdcc）
      zig/             Zig 编译器源码，rebase 到上游分支 `0.16.x`，并带有 MCS 后端
      sdcc-c251/       内嵌的 SDCC fork，包含 MCS-51 + MCS-251 目标，用作后端/参考

## 互操作约定

- 目标选项：`-mmcs251`（SDCC）、`-mmcs51`（SDCC）
- 采用 SDCC MCS251 ABI 第 2 版：`sdcc-c251/doc/mcs251/abi.md`
- 互操作约定：每个翻译单元均使用 `--stack-auto` / `__reentrant`
- 目标文件/可重定位文件：SDCC ASxxxx `.rel`；最终镜像：Intel HEX
- 指令集参考：STC `AI8051U-*.md` 附录 A

## 构建

`zig/` 基于上游 `0.16.x`（`0.16.1-dev.29+7056ba9a5`），因此可由发行版编译器
Zig 0.16.0（通过 winget 安装）构建。将编译器指向本仓库自有的 `lib/`，使
`build.zig` 与 `std` 与源码保持一致：

    $env:ZIG_LIB_DIR = "<workspace>\mcs251\zig\lib"
    & "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\zig.zig_Microsoft.Winget.Source_8wekyb3d8bbwe\zig-x86_64-windows-0.16.0\zig.exe" build -Dno-langref

得到的编译器为 `zig/zig-out/bin/zig.exe`。

冒烟测试（MCS-251，void 叶子函数）：

    & zig/zig-out/bin/zig.exe build-obj -target mcs251-freestanding -femit-bin=empty.asm empty.zig

## 状态

自托管 MCS 后端（`zig/src/codegen/mcs/`）已可构建并为以下功能输出 ASxxxx 汇编：

- 1-4 字节标量参数/返回值，使用 ABI 寄存器槽（`DPL/DPH/B/A`）；
- 第一个标量参数放入寄存器，其余标量按 SDCC `-(2 + Σsize)` 偏移从重入硬件栈读取
  （见 `abi.md`）；
- 1-4 字节整数 `add`/`sub`/`and`/`or`/`xor`（按字节带进位链）、`not`，
  以及常量或变长移位次数的 `shl`/`shr`；
- 乘法（`mul ab`、`mul WR,WR`，以及用于 4 字节的 3×16×16 组合）和
  除法/取模（`div ab`、`div WR,WR`，3/4 字节使用恢复余数除法）；有符号
  除法/取模通过 `|a| / |b|` 加符号修正实现（`@divTrunc`/`@divFloor`、
  `@rem`/`@mod`）；
- MCS-251 上用于临时变量和局部变量的 SPX 栈帧，配套 `inc/dec spx,#n`
  的序言/尾声；
- 控制流：`.block`/`.loop`/`.repeat`/`.br`/`.cond_br`/`.switch_br`，以及整数
  比较（有符号与无符号）、`if`/`while`/`for` 循环、`switch`（等值与范围 case
  展开为比较链）；
- 帧背局部变量（`.alloc`/`.load`/`.store`）、整数类型转换
  （`.intcast`/`.trunc`/`.bitcast`，含符号扩展及 int<->指针物化）、数组
  （编译期下标使用直接帧偏移；运行时下标在常量下标上展开为比较链）、聚合值
  拷贝（常量聚合通过 `Value.writeToMemory`，运行时拷贝按字节进行）；
- 切片（`.array_to_slice`/`.slice`/`.slice_len`/`.slice_ptr`/`.slice_elem_val`/
  `.slice_elem_ptr`/`.ptr_add`）针对定长对象：编译期 `ptr`+`len` 折叠为切片视图；
  物化的切片为 6 字节 `ptr`+`len` 值（3 字节平面指针存于 `DR28`），运行时下标在
  已知长度上展开，指针使用 `@DR28` 解引用；
- 直接调用（`.call`）与递归（第一个标量放入 `DPL/DPH/B/A`，其余标量按逆序压栈）、
  间接调用（3 字节函数指针经 push/pop 载入 `DR28`，再 `ecall @dr28`）、变参调用
  （`@cVaStart`/`@cVaArg`/`@cVaCopy`/`@cVaEnd`；提升后的 `c_int` 变参随固定栈参
  数一起压栈，通过使用 `@DR28` 的 3 字节平面 `va_list` 读取）。

`MCS-51` 保留 1-3 字节标量的寄存器模型，从入口硬件栈获取额外参数，并将局部变量、
参数和中间值保存在**静态 idata 帧**（`.area DSEG` / `_frkN` / `.ds`）中，即 SDCC
默认的非重入布局。调用方按小端序压入参数并在调用后恢复 `SP`。
仍未实现（每项都会报告明确的编译错误）：浮点数、对无界切片/指针值的运行时下标，
以及 MCS-51 切片与间接/变参调用。`sdas`/`sdld` 链接驱动位于 `driver/`。

## 说明

- 这是一个就地 fork 的工作区；`zig/` 和 `sdcc-c251/` 直接被修改。
- 上游版本复制时未带 `.git`。本地改动由根仓库跟踪。
