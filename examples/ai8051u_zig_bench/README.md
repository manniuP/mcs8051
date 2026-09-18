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

真机核对可用 `tools/bench_verify.py`（抓一帧、解析十六进制、断言六项非零 + 趋势提示）：

```powershell
python tools\bench_verify.py --port COM8 --baud 9600
```

## 真机实测（AI8051U-34K64 @40MHz，2026-09-18）

`o0`=调用 `accFast`、`o5`=调用 `accSmall`（同函数体，仅 `linksection` 等级标签不同）。

**A. 原始标签**（`accFast=.Ofast`、`accSmall=.Os`）：

```
nop=0x4305
rd  d=0x5499 i=0x5881 e=0x5b75 x=0x5d69
exe o0=0x48e1 o5=0x48b5      # Ofast=0x48e1(18657)  Os=0x48b5(18613)
```

- 读延迟趋势正确：`d(0x5499) < i(0x5881) < e(0x5b75) < x(0x5d69)`，
  扣 `nop` 基线后每次读约 **9 / 11 / 12.5 / 13.5** 周期（data 直址 → idata `@r0` → edata `@dptr`
  → xdata `@dpx`）。

**B. 互换标签**（临时把 `accFast=.Os`、`accSmall=.Ofast`；源码默认仍为 A）验证「周期数随标签走」：

```
nop=0x4305
rd  d=0x5499 i=0x5881 e=0x5a75 x=0x5c69
exe o0=0x47b5 o5=0x48e1      # Os(accFast)=0x47b5  Ofast(accSmall)=0x48e1
```

- **`Ofast` 特征值 `0x48e1` 随标签从 `accFast` 移到 `accSmall`**（A 的 `o0`＝B 的 `o5`），
  证明等级标签确实驱动后端选码；`Os` 在两个 build 里都低于同 build 的 `Ofast`。
- 跨 build 的绝对数（`e`/`x` 读、`Os` 执行）有 **0x100** 的同步偏移，疑与代码布局/`t0Now`
  边界有关，故**同 build 内比较**更可靠（趋势与相对差）。

**C. 循环优化**（`MCS_LOOP=1`，构建层 `tools/mcs_loop.py`：计数循环改「下行计数 + `djnz`」，
含调用循环用 DSEG 直接字节计数；并折叠读体的帧溢出）：

```
nop=0x0865
rd  d=0x0e41 i=0x1229 e=0x1bed x=0x1de1
exe o0=0x3a8d o5=0x3db9
```

| 项目 | 优化前 | 优化后 |
| --- | --- | --- |
| `nop` | 0x4305 (17157) | 0x0865 (2149) |
| `rd d` | 0x5499 (21657) | 0x0e41 (3649) |
| `rd i` | 0x5881 (22657) | 0x1229 (4649) |
| `rd e` | 0x5a75 (23157) | 0x1bed (7149) |
| `rd x` | 0x5c69 (23657) | 0x1de1 (7649) |
| `exe o0` | 0x47b5 (18357) | 0x3a8d (14989) |
| `exe o5` | 0x48e1 (18657) | 0x3db9 (15801) |

`data` 每轮 43→7 周期；`d-nop = 3×500`、`i-nop = 5×500`、`e-nop = 10×500`、`x-nop = 11×500`
与周期表吻合（迭代次数/访存不变）。`exec` 每轮 47→16（主要耗在被调函数体内）。
详见 `docs/22-循环下行计数DJNZ.md`。

QEMU 无板（QEMU 无真实时序，仅验证能跑）：`wsl -e bash tools/qemu_mcs_run.sh examples/ai8051u_zig_bench/bench.ihx`。

