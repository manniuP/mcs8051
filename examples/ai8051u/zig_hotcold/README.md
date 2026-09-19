# ai8051u_zig_hotcold — 热/冷频次注解

用 Zig 标准 `linksection` 给**变量/函数**标热/冷，后端据此优化：

| 标注 | 对象 | 后端行为 |
| --- | --- | --- |
| `linksection(".hot")` | 变量 | → **DSEG**，直接寻址 `mov a,_sym`（快） |
| `linksection(".cold")` | 变量 | → 独立 **`COLDX` 区**（xdata），`mov dpxl/… @dpx`（省 direct 区，便于整体压缩/后置） |
| `linksection(".hot")` | 函数 | 保持 `CSEG`（热代码）；要真内联请写 `inline fn` |
| `linksection(".cold")` | 函数 | 归入独立 **`COLD` 代码区**（可与热代码分开，便于整体压缩/后置） |

> 语法：函数属性写在**返回类型之前** —— `fn f() linksection(".cold") T { … }`。

```zig
var hot_cnt: u8 linksection(".hot") = 0;             // DSEG 直接寻址
var cold_buf: [8]u8 linksection(".cold") = .{0} ** 8; // XSEG

export fn hot_add(x: u8) linksection(".hot") u8 { return hot_cnt +% x; }
export fn cold_work(x: u8) linksection(".cold") u8 { cold_buf[1] = x; return cold_buf[1]; }
```

## 构建与验证

```powershell
xmake f --mcs_arch=mcs251
xmake build zighotcold       # 产物 hotcold.ihx，串口 9600 打印 `132a`
```

看反汇编（`hotcold.lst`）：
- `_hot_cnt` 在 **DSEG**（0x30 起），`hot_add` 用 `mov a,_hot_cnt`；
- `_cold_buf` 在 **XSEG**，`cold_work` 用 `mov dpxl,#(_cold_buf>>16); mov a,@dpx`；
- `_hotcold_cold_work` 落在 `COLD` 区（`hotcold.map`: `COLD 00FF00xx …`）。

QEMU 无板：`wsl -e bash tools/qemu_mcs_run.sh build/examples/ai8051u/zig_hotcold/hotcold.ihx`。
