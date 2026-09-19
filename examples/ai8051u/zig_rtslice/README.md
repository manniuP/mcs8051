# ai8051u_zig_rtslice — 运行期切片值自检

MCS-251（AI8051U）纯 Zig 示例：验证后端对**运行期切片值** `[]u8 = &全局数组` 的支持。
与 `ai8051u_zig_slice`（编译期切片 `const s: []const u8 = &arr`）互补。

## 覆盖

- `const s: []u8 = &buf;`：切片描述符（`ptr` + `len`）物化进帧槽；
- `s.len`：运行期长度；
- 运行期下标读 / 写 `s[i]`（按长度展开分派）；
- `&s[i]`：取元素指针再解引用；
- 切片逐项拷贝到另一个全局数组（`.data` 空间）。

## 期望输出（UART1，9600）

```
runtime slice:
40 41 42 43 44 45
s[3]=43
42434445
```

## 构建 / 运行（QEMU 无板，需 WSL + qemu-system-mcs251）

```powershell
cd <workspace>\mcs251
xmake f --mcs_arch=mcs251
xmake build zigrtslice        # 产物 build\examples\ai8051u\zig_rtslice\rtslice.ihx
```

```bash
# QEMU（stc32g144k246）
cp build/examples/ai8051u/zig_rtslice/rtslice.ihx /tmp/rtslice.hex
~/qemu-mcs/build/qemu-system-mcs251 -M stc32g144k246 -bios /tmp/rtslice.hex \
  -serial stdio -display none -monitor none
```

真机：STC-ISP 选 AI8051U-34K64，烧 `rtslice.ihx`，串口 9600。
