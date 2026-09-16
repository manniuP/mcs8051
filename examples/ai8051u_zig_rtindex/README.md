# ai8051u_zig_rtindex — 运行期下标跨数据空间

验证 MCS-251 后端对**运行期下标**在四个数据空间的寻址是否各自正确：

| 空间 | 声明 | 解引用寻址 |
| --- | --- | --- |
| `data`  | `linksection(".data")`  | 低位字节装入 R0，`mov a/@r0`（8 位 idata 间接） |
| `idata` | `linksection(".idata")` | 同上 |
| `xdata` | `linksection(".xdata")` | 24 位绝对地址装入 DR28，`@dr28` |
| `edata` | 固定地址 `0x0200`（`@ptrFromInt`） | 装入 DPTR，`movx @dptr` |

每个数组用运行期下标 `i` 写入互异模式再回读，经 UART1（P3.1）@9600 反复打印：

```
runtime index x spaces:
a0b0c0d0 a1b1c1d1 a2b2c2d2 a3b3c3d3
```

**任何空间/寻址错误**都会让对应字节肉眼可见地不对（不是靠“灯闪”蒙混）。多字节元素
（`u16` 数组）与多字节下标（`u16` 索引）走同一 `emitAbsElemPtr` 缩放路径。

## 构建

```powershell
xmake f --mcs_arch=mcs251
xmake build zigrtindex      # 产物 examples/ai8051u_zig_rtindex/rtindex.ihx
```

## 真机

用 STC-ISP（AiCube）打开 `rtindex.ihx`，芯片选 `AI8051U-34K64`，下载后串口（COMx @9600）
应持续打印上面的行。复位地址 `FF:0000`、`--code-loc 0xff0000` 已由 `crt0.asm` +
xmake 链接参数固定。

## QEMU 无板仿真

```bash
wsl -e bash <workspace>/mcs251/tools/qemu_mcs_run.sh \
  <workspace>/mcs251/examples/ai8051u_zig_rtindex/rtindex.ihx
```
