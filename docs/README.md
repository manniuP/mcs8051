# 文档总目录（MCS-51 / MCS-251 / STC AI8051U）

本目录是**仓库全部文档的唯一位置**（原根目录的 PLAN / README、`driver/`、`projects/`、
`examples/` 的 README 都已并入这里，见文末“文档搬迁对照”）。仓库根只留一个入口
`README.md` 指向本页。

## 一、入门与流程（按序阅读）

1. [01-环境准备](01-环境准备.md) —— 工具链、路径、验证环境。
2. [02-工程结构与构建流程](02-工程结构与构建流程.md) —— 仓库布局与 Zig/C/链接三段式流程。
3. [03-C与Zig混编与ABI](03-C与Zig混编与ABI.md) —— 双方如何互相调用、ABI 约定、硬件操作放哪边。
4. [04-驱动脚本用法](04-驱动脚本用法.md) —— `driver/build.ps1` 与自建混编脚本。
5. [05-移植到MCS-251](05-移植到MCS-251.md) —— 从 8051 兼容模式切到 251 核。
6. [06-常见问题与限制](06-常见问题与限制.md) —— 报错排查、后端限制、编码坑。
7. [07-调试笔记-ptr_rt自举崩溃定位](07-调试笔记-ptr_rt自举崩溃定位.md) ——
   自举崩溃定位、磁盘清理、“不再自举、固定预编译编译器”，以及 **ptr_rt 跑通** 的完整记录。

## 二、驱动、工程与示例

- [08-驱动与链接详解](08-驱动与链接详解.md) —— SDCC 编译/链接命令、`.lk` 结构、内存模型（原 `driver/README.md`）。
- [09-工程与示例总览](09-工程与示例总览.md) —— `projects/`、`examples/` 索引与新建工程约定（原 `projects/README.md`）。
- [10-工程-ai8051u_blink](10-工程-ai8051u_blink.md) —— 完整 C + Zig 流水灯工程说明（原 `projects/ai8051u_blink/README.md`）。
- [11-示例-ai8051u_blink](11-示例-ai8051u_blink.md) —— 最小 C + Zig 示例说明（原 `examples/ai8051u_blink/README.md`）。

源码位置：`../projects/ai8051u_blink/`、`../projects/ai8051u_ptrtest/`、
`../examples/ai8051u_blink/`（3 字节指针互操作见 [07](07-调试笔记-ptr_rt自举崩溃定位.md)）。

## 三、计划与仓库说明

- [PLAN-计划](PLAN-计划.md) —— 总体计划、ABI 冻结、里程碑（原根 `PLAN.md`）。
- [PLAN-计划-中英](PLAN-计划-中英.md) —— 中英对照版（原根 `PLAN_zh_en.md`）。
- [仓库说明-中文](仓库说明-中文.md) —— 仓库结构、构建、状态（原根 `readme_zh.md`）。
- [仓库说明-English](仓库说明-English.md) —— English overview（原根 `README.md`）。

## 四、运维

- [12-可清理与重新下载清单](12-可清理与重新下载清单.md) —— 已清理的大件（Keil 安装、
  sdcc-c251 源码、缓存）及日后恢复方法；同时列出“不要删”的必需件。
- 给 AI 助手的协作约定（工作区级）：[`../../docs/AI-协作约定.md`](../../docs/AI-协作约定.md)
  （工作区根另有 `AGENTS.md` 入口）。

## 定位（一句话）

- **Zig**：由 MCS 后端 `zig/src/codegen/mcs/` 直接产出 ASxxxx 汇编（`.asm`），
  用 `../tools/zig-bootstrap/zig.exe`（唯一可用的预编译编译器）编译。
- **C**：由 SDCC（`-mmcs51` / `-mmcs251`）产出 `.rel`。
- **链接**：两者都是 SDCC ASxxxx 目标，用 `sdas` + `sdld`（或 `sdcc` 驱动）链成同一个 Intel HEX。

> **不走自举**：不再尝试用宿主重编 `zig.exe`（会崩，见 07）。只走
> 「zig 编译 Zig 源 + sdcc 编译 C + 链接」的直连管线。

## 文档搬迁对照

| 原位置 | 现位置 |
| --- | --- |
| `driver/README.md` | [08-驱动与链接详解](08-驱动与链接详解.md) |
| `projects/README.md` | [09-工程与示例总览](09-工程与示例总览.md) |
| `projects/ai8051u_blink/README.md` | [10-工程-ai8051u_blink](10-工程-ai8051u_blink.md) |
| `examples/ai8051u_blink/README.md` | [11-示例-ai8051u_blink](11-示例-ai8051u_blink.md) |
| 根 `PLAN.md` | [PLAN-计划](PLAN-计划.md) |
| 根 `PLAN_zh_en.md` | [PLAN-计划-中英](PLAN-计划-中英.md) |
| 根 `readme_zh.md` | [仓库说明-中文](仓库说明-中文.md) |
| 根 `README.md` | [仓库说明-English](仓库说明-English.md)（根 `README.md` 改为入口） |
