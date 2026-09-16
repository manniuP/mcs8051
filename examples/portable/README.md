# AI8051U 便携构建集（共享工具链 + 四个独立示例）

从主工程提取的**最小可编译集**：内置 `zig.exe`（含 MCS-251 后端）+ SDCC mcs251 工具与运行库
+ **`mcstools.exe`（构建层 Python 工具已冻结为独立 exe）**。在**未安装任何工具链、未安装
Python、且没有任何预设环境变量**的 Windows 上也能编译。

四个示例**互相隔离**，各自有独立的 `build.zig` / `build.cmd` / 目录，只**共享**根目录下的
`toolchain/`（不重复拷贝 300MB 工具链）。

## 目录
```
build.cmd              根调度：build.cmd [usb_cdc|ziglog|t0print|uart_echo|all] [额外 zig 参数]
toolchain/             共享工具链
  zig/                 自带 zig.exe + lib（build 驱动 + MCS 后端）
  sdcc/                自带 sdcc/sdas251/sdld + mcs251 运行库
  mcstools/            mcstools.exe（fix/opt/ir/overlay/dce，无需 Python）
usb_cdc/               示例一：C USB-CDC（纯 C，SDCC）
  build.zig build.cmd
  include/  src/
ziglog/                示例二：纯 Zig COBS 二进制日志
  build.zig build.cmd
  log.zig mcs251.zig cobs.zig crt0.asm
  decode.py/.ps1       主机端帧解码
  device.json          设备存储表（build.zig 用 @embedFile 注入 MCS_DEVICE）
t0print/               示例三：纯 Zig 定时器中断打印
  build.zig build.cmd
  t0print.zig mcs251.zig crt0.asm
  device.json          设备存储表（同上）
uart_echo/             示例四：纯 Zig UART1 接收中断回环
  build.zig build.cmd
  uart_echo.zig mcs251.zig crt0.asm
  device.json          设备存储表（同上）
```

> 注：Zig 示例的 `device.json` 使变量放置与主工程一致——`ziglog`/`t0print` 的 `.asm`/`.ihx`
> 与主工程（xmake）产出**逐字节相同**。

## 用法（Windows，无需任何环境配置）
```
build.cmd                  :: 三个都编（默认 all）
build.cmd usb_cdc          :: 只编 USB-CDC  -> usb_cdc\usb_cdc.ihx
build.cmd ziglog           :: 只编 ziglog   -> ziglog\log.ihx
build.cmd t0print          :: 只编 t0print  -> t0print\t0print.ihx
build.cmd uart_echo        :: 只编 uart_echo -> uart_echo\uart_echo.ihx
build.cmd t0print -Dmcs-small=true     :: Zig 侧走 -OReleaseSmall
build.cmd usb_cdc -Dcode-loc=0x0000    :: 覆盖代码基址
```
也可进入任一示例目录单独构建（自带工具链在上一级 `..\toolchain`）：
```
cd ziglog
..\toolchain\zig\bin\zig.exe build        :: 或直接 .\build.cmd
```

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
- **C**：由自带的 **SDCC mcs251** 编译（`usb_cdc` 即如此），Zig 只编 Zig。
- **`zig cc` / `zig c++` 不能编 mcs251 的 C/C++**：`zig cc` 走自研 C 前端 aro，而本版本 aro
  还没实现「生成目标文件」（`error: aro does not support compiling C objects yet`）；编译器又是
  `have_llvm=false` 构建（`-fclang` → "zig was compiled without Clang libraries"），且 LLVM 没有
  MCS-251 后端。详见 `mcs251/docs/06 §7`。

## 生成便携集
在主工程根目录（`mcs251/`）执行（会重新冻结 `mcstools.exe`）：
```
powershell -File tools\make_portable.ps1
```
