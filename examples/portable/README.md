# AI8051U 便携构建集（共享工具链 + 四个独立示例）

从主工程提取的**最小可编译集**：内置 `zig.exe`（含 MCS-251 后端）+ SDCC mcs251 工具与运行库
+ **`mcstools.exe`（构建层 Python 工具已冻结为独立 exe）**。在**未安装任何工具链、未安装
Python、且没有任何预设环境变量**的 Windows 上也能编译。

四个示例**互相隔离**，各自有独立的 `build.cmd` / 目录（Zig 示例另有 `build.zig`），只**共享**
根目录下的 `toolchain/`（不重复拷贝 300MB 工具链）。

## 目录
```
build.cmd              根调度：build.cmd [usb_cdc|ziglog|t0print|uart_echo|all] [额外参数]
toolchain/             共享工具链
  zig/                 自带 zig.exe + lib（build 驱动 + MCS 后端）
  sdcc/                自带 sdcc/sdas251/sdas8051/sdld + mcs251 运行库
  mcstools/            mcstools.exe（fix/opt/ir/overlay/dce，无需 Python）
usb_cdc/               示例一：C USB-CDC（纯 C，SDCC 直接编译，支持 -Darch=mcs51）
  build.cmd            直接调 sdcc（-mmcs251/-mmcs51；不经 zig）
  build.zig            可选，等价的 zig 构建脚本
  include/  src/
ziglog/                示例二：纯 Zig COBS 二进制日志（仅 mcs251）
  build.cmd            默认直接调 zig build-obj + mcstools + sdas + sdcc（不经 build runner）
  build_runner.exe     预编译的构建 runner（供 build.cmd --runner 用，免宿主重编）
  build.zig            可选，等价的 zig 构建脚本（供 `zig build` / --runner 用）
  log.zig mcs251.zig cobs.zig crt0.asm
  decode.py/.ps1       主机端帧解码
  device.json          设备存储表（单行 JSON；build.cmd 用 set /p 注入 MCS_DEVICE）
t0print/               示例三：纯 Zig 定时器中断打印（支持 -Darch=mcs51）
  build.cmd build_runner.exe build.zig
  t0print.zig mcs251.zig crt0.asm crt0_mcs51.asm
  device.json          设备存储表（同上）
uart_echo/             示例四：纯 Zig UART1 接收中断回环（支持 -Darch=mcs51）
  build.cmd build_runner.exe build.zig
  uart_echo.zig mcs251.zig crt0.asm crt0_mcs51.asm
  device.json          设备存储表（同上）
```

> 注：Zig 示例的 `device.json` 使变量放置与主工程一致——`ziglog`/`t0print` 的 `.asm`/`.ihx`
> 与主工程（xmake）产出**逐字节相同**。`device.json` 为单行 JSON，便于 `build.cmd` 用
> `set /p MCS_DEVICE=<device.json` 注入；其取值与多行版相同（见 `tools/make_portable.ps1`）。

## 用法（Windows，无需任何环境配置）
```
build.cmd                  :: 四个都编（默认 all）
build.cmd usb_cdc          :: 只编 USB-CDC  -> usb_cdc\usb_cdc.ihx
build.cmd ziglog           :: 只编 ziglog   -> ziglog\log.ihx
build.cmd t0print          :: 只编 t0print  -> t0print\t0print.ihx
build.cmd uart_echo        :: 只编 uart_echo -> uart_echo\uart_echo.ihx
build.cmd t0print -Dmcs-small=true     :: Zig 侧走 -OReleaseSmall
build.cmd usb_cdc -Dcode-loc=0x0000    :: 覆盖代码基址（mcs251 默认 0xff0000；mcs51 默认 0x0000）
build.cmd usb_cdc -Darch=mcs51         :: 8 位 MCS-51（usb_cdc/t0print/uart_echo 支持）
build.cmd t0print -Darch=mcs51
build.cmd uart_echo -Darch=mcs51
build.cmd ziglog --runner              :: 走预编译 build_runner.exe（等价 `zig build`）
```
也可进入任一示例目录单独构建（自带工具链在上一级 `..\toolchain`）：
```
cd usb_cdc
.\build.cmd                               :: 直接调 SDCC，不经过 zig
cd ziglog
.\build.cmd                               :: 默认直接管线；或 .\build.cmd --runner
```

## Zig 示例怎么编译（为什么默认不走 `zig build`）
`toolchain/zig` 是 `have_llvm=false` 构建，编译 **x86_64 宿主**代码只能走后端自研的
x86_64 后端；而 `zig build` 每次都必须先把 `build.zig` 编成宿主程序 `build.exe`
（build runner），这一段就可能硬崩（整数除零 `0xC0000094`，即 `exit code 148`）。

因此 `ziglog` / `t0print` / `uart_echo` 的 `build.cmd` **默认把 `build.zig` 的每一步直接拆到命令行**：

1. `zig build-obj -target <mcs251|mcs51>-freestanding ...`（只走 MCS 后端，不碰宿主后端）
2. `mcstools.exe fix / opt / ir / overlay <name>.asm`
3. `sdas251|sdas8051` 汇编 + `sdcc` 链接 `crt0.asm`/`crt0_mcs51.asm` → `.ihx`

全程**不产生任何宿主 x86_64 代码**，所以 148 从原理上不会发生；产物与 `zig build`
（以及主工程 xmake）**逐字节相同**（已对 mcs251/mcs51 两个架构逐一比对 SHA-256）。

如确需 `zig build` 语义，用 `build.cmd <name> --runner`：它调用随包附带、**打包时用带
LLVM 的宿主 zig 预编译好**的 `build_runner.exe`，同样不需要在目标机上编译宿主程序。

## 8 位（mcs51）编译
`usb_cdc` / `t0print` / `uart_echo` 支持 `-Darch=mcs51`（默认 `mcs251`）。切到 8 位时自动：

- SDCC 用 `-mmcs51`，汇编器用 `sdas8051`（mcs251 是 `sdas251`），Zig 目标为 `mcs51-freestanding`；
- `t0print` / `uart_echo` 的启动/向量表改用 `crt0_mcs51.asm`（复位 `0x0000`、8 字节中断向量、
  `ljmp` 入口、`mov sp,#0x7f`、`lcall _main`）；ISR 里 `ecall` 换 `lcall`；
- 位操作数汇编语法按架构自动选（sdas8051 `addr^bit` / sdas251 `addr.bit`）；
- `usb_cdc` 是纯 C，仅换 `-mmcs51` 与 `--code-loc`（默认 `0x0000`）。

`ziglog` **仅支持 mcs251**：mcs51 后端的 Zig 每个函数一块静态帧、全部落在内部 RAM 直接区
（≤128B），本示例 DSEG 已 200+B 链不上（主工程 8 位 COBS 因此用 C）。传 `-Darch=mcs51` 会明确报错。

## 程序行为
- **usb_cdc**：上电初始化 USB-CDC，每约 1 秒经虚拟串口（115200 8N1）发送 `hello world`。
- **ziglog**：每约 1 秒经 UART1（P3.1，115200）发送六帧二进制日志（`boot/count/xy/cvar/msg/g16`，
  COBS 编码、`0x00` 定界）。主机端解码：
  ```
  python ziglog\decode.py -p COM8          :: 或 ziglog\decode.ps1 -Port COM8
  ```
- **t0print**：Timer0 每 1ms 中断，在 ISR 里每秒经 UART1（P3.1，115200）打印一行 `t0`。
  ISR 是「无帧」内联汇编，逻辑 `ecall` 到普通 Zig 函数（避免 `reti` 跳过 epilogue 导致 SPX 泄漏）。
- **uart_echo**：UART1 接收中断（中断号 4）回环——PC 经 P3.0/RxD 发什么，就从 P3.1/TxD 回什么
  （115200 8N1）。ISR 无帧，逻辑在普通 Zig 函数里读 SBUF 再回写。

## C / C++ 说明
- **C**：由自带的 **SDCC mcs251** 编译；`usb_cdc` 的 `build.cmd` **直接调用 `sdcc`**（不经 zig），
  Zig 只编 Zig。
- **`zig cc` / `zig c++` 不能编 mcs251 的 C/C++**：`zig cc` 走自研 C 前端 aro，而本版本 aro
  还没实现「生成目标文件」（`error: aro does not support compiling C objects yet`）；编译器又是
  `have_llvm=false` 构建（`-fclang` → "zig was compiled without Clang libraries"），且 LLVM 没有
  MCS-251 后端。详见 `mcs251/docs/06 §7`。

## 已知问题：`zig build` 冷缓存时必然崩（0xC0000094 / exit code 148）
> 这是**工具链自身缺陷**（`have_llvm=false` 的自研 x86_64 后端），**与示例源码无关**。
> 早期文档写成「偶发、重跑即通过」并不准确：它取决于缓存。`toolchain/zig` 在编译 x86_64
> 宿主程序（`build.exe` / `translate-c.exe` 等）时可能硬崩（`error: ... failed with exit code
> 148`，即 `0xC0000094`）。只要构建 runner 命中缓存就不触发；一旦**脱离原工程目录**（缓存
> 失效）或清空缓存，就必须重编 runner，于是**必定**遇到 148。

本便携集已从两方面消除该问题：

- **默认不再走 `zig build`**：`usb_cdc` 纯 C 直接调 SDCC；`ziglog`/`t0print`/`uart_echo` 的
  `build.cmd` 默认直接把各步骤拆到命令行（见上节），完全不编宿主代码。
- **`--runner` 用预编译 runner**：`build_runner.exe` 在打包时由带 LLVM 的宿主 zig 编好，
  目标机只运行不编译，因此 `--runner` 也不会触发 148。

> 若绕过 `build.cmd`、直接运行 `..\toolchain\zig\bin\zig.exe build`，仍可能碰到 148，
> 请改用 `build.cmd [--runner]`。

## 生成便携集
在主工程根目录（`mcs251/`）执行（会重新冻结 `mcstools.exe`、重新预编译 `build_runner.exe`）：
```
powershell -File tools\make_portable.ps1
```
`build_runner.exe` 需要宿主机上有一个带 LLVM 的 `zig`（默认取 PATH 上的 `zig`；没有则退回
捆绑的 `zig.exe` 并给出警告）。没有 `build_runner.exe` 时其余功能不受影响，只是
`build.cmd --runner` 不可用。
