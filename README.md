# mcs251

面向 Intel 8051（MCS-51）/ 80251（MCS-251）的 **Zig + C 工具链工作区**（集成仓），
目标为 STC / AI 系列芯片。

本仓只放**项目自身内容**（示例、库、设备描述表、构建脚本、文档）；两个编译器以
**git submodule** 引入并固定到具体提交，固定版本记录见 [`versions.toml`](versions.toml)。

| 子模块 | 仓库 | 作用 |
| --- | --- | --- |
| `compiler/` | [manniuP/zig-mcs51-backend](https://github.com/manniuP/zig-mcs51-backend) | Zig 自举后端：Zig 源 → MCS-51/251 汇编（ASxxxx） |
| `sdcc/` | [manniuP/sdcc-c251](https://github.com/manniuP/sdcc-c251) | SDCC（MCS-251 目标）：编译 C、`sdas`/`sdld` 汇编链接 |

## 获取

```bash
git clone --recurse-submodules <this-repo>
# 已 clone 后补子模块：
git submodule update --init --recursive
```

## 目录

| 路径 | 说明 |
| --- | --- |
| `compiler/`（submodule） | Zig + MCS-51/251 后端 |
| `sdcc/`（submodule） | SDCC MCS-251 fork |
| `examples/` | 示例工程（C / 纯 Zig / C+Zig 混编） |
| `lib/` | 库与头文件（`mcs251.zig`、`cobs/`、`uart251/`、`crt0/`、`include/`） |
| `devices/` | STC/AI 设备描述表（TOML）与工具 |
| `tools/` | 构建/辅助脚本（预编译 SDCC 工具链与 `vendor/` 不入库） |
| `docs/` | 项目文档，入口 [`docs/README.md`](docs/README.md) |
| `xmake.lua`、`xmake/` | 构建系统 |

## 构建（概述）

```powershell
# 1) 构建 Zig 后端（用系统 zig 0.16.0；产物 compiler\zig-out\bin\zig.exe）
cd compiler
zig build -Doptimize=ReleaseFast -Dno-lib -Dmcs-only --zig-lib-dir lib

# 2) 构建示例
cd ..
xmake f --mcs_arch=mcs251
xmake build ziglog          # 纯 Zig；C 目标如 uart/led 走 SDCC
```

> 管线：Zig 由 `compiler/` 后端编译成 `.asm`，C 由 SDCC 编译成 `.rel`，再用 `sdas` + `sdld` 链成 `.ihx`。
> 运行 `compiler\zig-out\bin\zig.exe` 前把 `ZIG_LIB_DIR` 指向 `compiler\lib`（含 mcs51/mcs251 目标定义）。

## 文档入口

- [`docs/README.md`](docs/README.md) —— 文档总目录（阅读顺序 + 全篇索引）
- [`docs/01-环境准备.md`](docs/01-环境准备.md) —— 工具链、路径、验证环境
- [`docs/PLAN-计划.md`](docs/PLAN-计划.md) —— 总体计划、ABI 冻结、里程碑

## 许可

- `compiler/`（上游 Zig fork）：**MIT**
- `sdcc/`（上游 SDCC fork）：**GPL-2.0**
- 本仓内容（`examples/`、`lib/`、`devices/`、`tools/`、`docs/`、`xmake/`）：**GPL-2.0**（见 [`COPYING`](COPYING)）
