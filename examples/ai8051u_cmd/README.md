# ai8051u_cmd —— UART 下发指令（主机 → MCU 命令分派）

把「**主机经 UART1 下发 COBS 命令帧、MCU 解析执行并回包**」做成最小闭环（P0，已真机通过）。

- 固件：`main.c`（单编译单元：主循环 + UART1 中断服务）
- 复用：`lib/cobs`（帧格式/编解码，新增 `cobs_decode`）、`lib/uart251`（TX + 新增 RX 中断环缓）
- 主机：`host/cmd.py`（Python + pyserial）
- 构建：`xmake f --mcs_arch=mcs251` → `xmake build cmd` → `cmd.ihx`

## 帧格式（与 `ziglog` / `ccobs` / `usbcdcobs` 同一张表）

```
原始帧：0x7E, id_lo, id_hi, 参数…, XOR        （XOR 从 id_lo 到参数末，不含 0x7E）
线上：整帧 COBS 编码后以 0x00 定界
参数：u8=1B、u16=2B 小端、u32=4B 小端、str=LEB128(len)+字节
```

## 命令 / 应答

| 命令 id | 参数 | 应答 id | 应答 |
| --- | --- | --- | --- |
| `0x0001` ping | — | `0x8001` | u16 `0x1234` |
| `0x0002` mul | u32 a, u32 b | `0x8002` | u32 `a*b` |
| `0x0003` div | u32 a, u32 b | `0x8003` | u32 q, u32 r（b=0 → 均 `0xFFFFFFFF`） |
| `0x0004` led | u8 on | `0x8004` | u8 状态（P1.1） |
| `0x0005` echo | 原始字节 | `0x8005` | 原样回显 |
| `0x0010` cossin | i16 角(BAM) | `0x8010` | i16 cos, i16 sin（Q15） |
| `0x0011` atan2 | i16 y, i16 x | `0x8011` | i16 角(BAM) |
| `0x0012` sqrt | u32 | `0x8012` | u16 |
| `0x0013` mag | i16 x, i16 y | `0x8013` | u16 |
| 其它 | — | `0x7FFF` | u16 原 id, u8 `0xFF` |

> `0x0010`–`0x0013` 走 `lib/cordic`（Q15 定点 CORDIC + 整数开方，见 `lib/cordic/README.md`）。

上电自报：`0x0001` + u16 `0x1234`。

## 接线 / 烧录

- USB-TTL：**RXD→P3.1(TxD)**、**TXD→P3.0(RxD)**、GND 共地；**115200 8N1**。
- AiCube-ISP：型号 `AI8051U-34K64` → 打开 `cmd.ihx` → 硬件选项 **CPU 指令模式 = 32-Bit** → 下载（冷启动上电）。

## 主机用法

```powershell
cd mcs251
python examples\ai8051u_cmd\host\cmd.py --selftest              # 无硬件自测
python examples\ai8051u_cmd\host\cmd.py -p COM8 monitor        # 只打印板子发来的帧
python examples\ai8051u_cmd\host\cmd.py -p COM8 ping
python examples\ai8051u_cmd\host\cmd.py -p COM8 mul 0x12345678 2
python examples\ai8051u_cmd\host\cmd.py -p COM8 div 1000 7
python examples\ai8051u_cmd\host\cmd.py -p COM8 led 1
python examples\ai8051u_cmd\host\cmd.py -p COM8 echo hello
python examples\ai8051u_cmd\host\cmd.py -p COM8 cossin 0x4000        # 90° → cos/sin Q15
python examples\ai8051u_cmd\host\cmd.py -p COM8 atan2 16384 16384    # 45° → 8192 BAM
python examples\ai8051u_cmd\host\cmd.py -p COM8 sqrt 1000000
python examples\ai8051u_cmd\host\cmd.py -p COM8 cordictest           # 随机向量对拍 Python math
```

## QEMU 无板仿真（免烧录，推荐先用它过一遍）

用 Process Mission 的 QEMU 下游（`github.com/processmission/qemu`，加了 MCS-251 机
`stc32g144k246`：复位 `0xff0000`、UART1 中断向量 `0xff0023`，正好对上我们的固件）。
**注意**：那是 STC32G 不是 AI8051U，**只能验证、不能替代真机**；且是 GPLv2 外部工具（勿并入 MIT 产物）。

```bash
# WSL 里（QEMU 已构建，见 docs/交接 §20）
mcs251/tools/qemu_mcs_run.sh --smoke                 # 起 QEMU 跑 ping/mul/div/led/echo 自检
mcs251/tools/qemu_mcs_run.sh                         # 前台起，串口在 127.0.0.1:5555
python3 examples/ai8051u_cmd/host/cmd.py --tcp 127.0.0.1:5555 cordictest
```

- `cmd.py` 新增 `--tcp host:port`：把 QEMU 的 socket 串口当串口用（QEMU 下默认逐字节慢发）。
- 两个 QEMU 坑：① 只有 **`.hex`** 后缀才走 Intel HEX 载入器（`.ihx` 会被当 raw → 表现为"什么都没跑"）；
  ② QEMU **不建模串口位时序**，整块灌会覆盖 `SBUF` → 必须逐字节喂（脚本已处理）。
- 实测：QEMU 结果与真机**逐条一致**（`pong 0x1234` / `mul=0x2468ACF0` / `div q=142 r=6` / `echo "hello"` / `led=1`）。

## 真机结果（AI8051U-34K64，COM8 @115200，2026-09-16）

- `ping` → `pong 0x1234`；`mul 0x12345678*2` → `0x2468ACF0`；`div 1000/7` → `q=142 r=6`；
  `echo hello` → `"hello"`；`led 1/0` → `state=1/0`。
- 边界：`div 100 0` → `0xFFFFFFFF/0xFFFFFFFF`；`mul 0xFFFFFFFF²` → `1`；**连发 20 × ping → 20/20 回包**。

## 说明 / 坑

- **ISR 必须与 `main` 同文件**：SDCC mcs251 的中断向量表只在含 `main` 的编译单元生成（见 `docs/14`），
  所以 `lib/uart251` 只提供环形缓冲与收发前端，UART1 中断函数写在 `main.c`。
- **阻塞 TX + 串口中断**：`ES=1` 时 `TI` 会反复触发中断（RI/TI 共向量）→ `uart_putc` 发送期间临时关 `ES`、
  发完恢复（期间到达的 `RI` 不丢）。
- ISR 与主循环共享变量（`rx_len`/`rx_ready`/`rx_cobs`）必须 `volatile`；帧交接用 `CRITICAL`。
- 帧缓冲固定 `FRAME_MAX=128`，`echo` 超长会被截断/丢弃（按需调大）。
