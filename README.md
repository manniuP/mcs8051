# mcs251

面向 Intel 8051（MCS-51）/ 80251（MCS-251）的 Zig + C 工具链工作区，目标为 STC 系列芯片。

## 文档入口（已全部集中到 `docs/`）

- [`docs/README.md`](docs/README.md) —— **文档总目录**（阅读顺序 + 全部篇目索引）
- [`docs/01-环境准备.md`](docs/01-环境准备.md) —— 工具链、路径、验证环境
- [`docs/07-调试笔记-ptr_rt自举崩溃定位.md`](docs/07-调试笔记-ptr_rt自举崩溃定位.md)
  —— 自举崩溃定位、磁盘清理、以及 **ptr_rt 间接寻址跑通** 的完整记录
- [`docs/PLAN-计划.md`](docs/PLAN-计划.md) —— 总体计划、ABI 冻结、里程碑

顶层目录按类别组织：`compiler/`（Zig + MCS 后端源码）、`lib/`（库与头文件，含 `cobs/`）、
`examples/`（示例工程）、`docs/`（文档）、`tools/`（脚本与预编译工具链）。
编译器用**系统 zig 从 `compiler/` 源码重建**（产物 `compiler/zig-out/bin/zig.exe`），
管线为「zig 编译 Zig 源 + sdcc 编译 C + 链接」。

## 快速开始

```powershell
# 配置到 mcs251（xmake v3 用下划线）
xmake f --mcs_arch=mcs251

# C + Zig 3 字节指针互操作验证（M3）
xmake build ptrtest
# -> build\examples\ai8051u\ptrtest\ptrtest.ihx
```

---

## 许可

本仓以 **Apache License 2.0** 发布（见 [`LICENSE`](LICENSE)）。
含少量 **STC 官方版权 / 衍生**内容（`lib/stc-hal/`、`examples/ai8051u/usb_{cdc,hid}/src/`、
`lib/include/ai8051u_sfr.h`），**不适用 Apache-2.0**，版权与条款详见
[`THIRD-PARTY.md`](THIRD-PARTY.md)。

---

All documentation now lives under [`docs/`](docs/README.md) (English overview:
[`docs/仓库说明-English.md`](docs/仓库说明-English.md)).
