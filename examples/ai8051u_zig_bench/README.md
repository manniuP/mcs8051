# ai8051u_zig_bench — 读取延迟 / 运行延迟（周期）测量

用 **Timer0（1T 自由计数）**测「一段代码前后 `TH0/TL0` 之差」，得到**时钟周期数**，UART 打印，供真机对比。

- Timer0：模式0（16 位自动重装载）、`AUXR.T0x12=1`（1T，每时钟 +1）、重装值 0 → 自由计数（模 65536）。
- 测点：`data`/`idata`/`edata`/`xdata` 各读 **500 次**；`O0`/`O5` 函数各调用 **100 次**。
- 每次测量都含同一套循环开销（可横向比较）。

## 构建

```powershell
xmake f --mcs_arch=mcs251
xmake build zigbench     # 产物 bench.ihx
```

## 预期输出（UART1 P3.1 @9600，16 进制）

```
bench
nop=xxxx
rd d=xxxx i=xxxx e=xxxx x=xxxx
exe o0=xxxx o5=xxxx
```

- `nop`：空循环（同 NREAD 次）的总周期，作为**循环开销基线**，可从各项扣减；
- `rd d/i/e/x`：500 次读的总周期（`d` 直址最快，`i`/`e`/`x` 依次；趋势应递增）；
- `exe Ofast/Os`：100 次调用总周期（`Ofast` 速度优先、`Os` 体积优先，可对比）。

> 说明：数值含循环与调用开销，看**相对差异**更有意义；单次测量若超过 65536 会回绕，
> 可把源码里的 `NREAD`/`NEXEC` 调小。UART 打印在测量之外，不影响计时。
> 真机：串口助手 9600 8N1 观察两行；固件持续循环输出。

QEMU 无板（QEMU 无真实时序，仅验证能跑）：`wsl -e bash tools/qemu_mcs_run.sh examples/ai8051u_zig_bench/bench.ihx`。

