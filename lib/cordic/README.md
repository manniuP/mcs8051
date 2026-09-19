# cordic —— Q15 定点 CORDIC + 整数开方（平台无关）

纯软件定点三角/向量库，替代暂缓的 TFPU。**无 SFR、无 libc、不 include config.h**，
可编到 mcs51 / mcs251 / 主机（主机用 `zig cc`）。

## 角度约定：BAM（Binary Angle Measure）
16 位 = 一整圈，角度就是 `int`（-32768..32767）：

| 值 | 角度 |
| --- | --- |
| `0x0000` | 0° |
| `0x4000` (=16384) | 90° |
| `0x8000` | 180° |
| `0xC000` (=-16384) | -90° |

分辨率 ≈ 0.0055°；加减/比较无需浮点或 π 换算。

## API（`cordic.h`）

```c
int cordic_sincos(int ang_bam, int *sin_q15, int *cos_q15);  // 旋转模式，Q15 输出
int cordic_atan2(int y_q15, int x_q15);                      // 向量模式，返回 BAM
unsigned int cordic_mag(int x_q15, int y_q15);               // 幅长 sqrt(x^2+y^2)
unsigned int cordic_isqrt(unsigned long v);                  // floor(sqrt(v))
```

## 精度（`cordic_test.c` 全量扫描，对比 libm）

| 函数 | 实测最大误差 |
| --- | --- |
| `cordic_sincos` | **9 LSB / 32768**（≈0.016°） |
| `cordic_atan2` | **6 BAM / 65536**（≈0.033°） |
| `cordic_mag` | 5（对 ≤46341 的幅长） |
| `cordic_isqrt` | 精确（floor） |

## 主机测试

```powershell
zig cc lib/cordic/cordic_test.c lib/cordic/cordic.c -lm -o cordic_test.exe
.\cordic_test.exe
```

## 实现要点 / 坑

- **象限折叠**：CORDIC 旋转只在 |θ|≤~90° 收敛；>90° 折到 `180°±` 后对 cos/sin **同时取反**。
- **Q15 饱和（重要）**：结果可能到 ±32769，**必须夹到 `[-32768,32767]`**；在 mcs251 上
  `int` 是 16 位，不夹会溢出变号（0° 的 cos 变成 -32766！）。主机 `int` 是 32 位，
  所以**主机测试发现不了这个 bug，是 QEMU 16 位运行才暴露的**（见 `examples/ai8051u/cmd/`）。
- 中间量一律 `long`（32 位）防溢出；增益 K=0.607252935（Q15=19898）。
- 未做：Q31（32 位）变体；`atan2` 的 x=y=0 返回 0。

## 设备端

已在 `examples/ai8051u/cmd` 暴露为命令（`0x0010 cossin` / `0x0011 atan2` / `0x0012 sqrt` /
`0x0013 mag`），可经真机 UART 或 **QEMU 无板仿真**验证：
`cmd.py --tcp 127.0.0.1:5555 cordictest`（随机向量对比 Python math）。
