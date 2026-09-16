# AI8051U USB-CDC 便携构建集

从主工程提取的**最小可编译集**：内置 `zig.exe`（MCS 后端）+ SDCC mcs251 工具与运行库，
在**未安装任何工具链**的 Windows 上也能编译本示例。

## 目录
```
build.cmd            一键构建（调用自带 zig build）
build.zig            构建编排（SDCC 编译 + 链接）
toolchain/zig/       自带 zig.exe + lib（build 驱动）
toolchain/sdcc/      自带 sdcc/sdas251/sdld + mcs251 运行库
include/             芯片头（ai8051u_sfr.h / c51.h / mcs_intrins.h）
src/                 示例源码（单编译单元 usb_cdc_all.c）
```

## 用法
```
build.cmd                       :: 生成 usb_cdc.ihx（代码基址 0xff0000）
build.cmd -Dcode-loc=0x0000     :: 覆盖基址
```

## 程序行为
上电初始化 USB-CDC，**每隔约 1 秒**通过 USB-CDC（虚拟串口）发送 `hello world`。
用 USB 线接 AI8051U，PC 端识别为串口后，用任意串口工具（115200 8N1）即可看到输出。

## 生成便携集
在主工程根目录（`mcs251/`）执行：
```
powershell -File tools\make_portable.ps1
```
