# ai8051u_zig_slice — 编译期切片的运行期下标 / 迭代

验证 MCS-251 后端对**编译期切片值**（`const s: []const u8 = &arr;`，没有对应 AIR 指令）
的运行期下标与 `for` 迭代，覆盖三种数据空间：

| 空间 | 声明 | 元素读取寻址 |
| --- | --- | --- |
| `xdata` | `linksection(".xdata")` | `mov dptr,#_arr+off; mov dpxl,#(_arr>>16); mov a,@dpx` |
| `data`  | `linksection(".data")`  | `mov a, dir8`（直接寻址） |
| `idata` | `linksection(".idata")` | `mov r0,#addr; mov a,@r0` |

三个 `[8]u8` 写入互异模式，用运行期下标逐项读，再 `for` 求和；UART1（P3.1）@9600
反复打印：

```
slice runtime idx:
102030 112131 122232 132333 142434 152535 162636 172737
sum=9c
```

（每列 = `sx[i]`/`sd[i]`/`si[i]`；`sum` = `0x10..0x17` 之和 = `0x9C`。）

## 构建

```powershell
xmake f --mcs_arch=mcs251
xmake build zigslice       # 产物 build/examples/ai8051u/zig_slice/slice.ihx
```

## 真机

STC-ISP（AiCube）选 `AI8051U-34K64`，烧 `slice.ihx`，串口（COMx @9600）应持续打印上面的行。

## QEMU 无板仿真

```bash
wsl -e bash tools/qemu_mcs_run.sh \
  build/examples/ai8051u/zig_slice/slice.ihx
```
