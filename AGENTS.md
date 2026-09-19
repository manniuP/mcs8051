# AGENTS.md — yuyan 工作区

> AI 助手上手须知。**完整约定见 [`docs/AI-协作约定.md`](docs/AI-协作约定.md)**（先读它）。
> **最近交接（先看）**：[`docs/交接-2026-09-18-QEMU效果与真机调试线索.md`](docs/交接-2026-09-18-QEMU效果与真机调试线索.md)
> —— **VSCode 扩展装错配置档（工作区绑 `16d3d1de`「51单片机」，须 `--profile`）；QEMU「效果」补全：
> 串口转发 + 端口 P0–P7（RSP 掩 24 位读不到 SFR，改走 QMP `xp`）；真机调试线索＝Keil Monitor-251
> （`MON251`@`FF:0000`+`STCMON251.DLL`，专有二进制协议）；新增 UART RSP 调试桩设计草案 + 上游询问草稿**。
> 上一份：[`docs/交接-2026-09-18-ZigCDB与VSCode调试.md`](docs/交接-2026-09-18-ZigCDB与VSCode调试.md)
> —— **Zig 后端调试档(`-ODebug`)输出 SDCC 风格调试符号 → `sdld -y` 产 `.cdb`；外部调试器
> `tools/mcs_dbg.py`（CDB + QEMU GDB RSP）、DAP 适配器 `tools/mcs_dap.py` + VSCode 扩展
> `tools/vscode-mcs251/`（可打源码断点）；`opt-tags` 并入 `mcs251-backend`、去 sdcc 个人 fork**。
> 上一份：[`docs/交接-2026-09-18-周期与循环优化与CI.md`](docs/交接-2026-09-18-周期与循环优化与CI.md)
> —— **指令周期参考(`tools/mcs_cycles.py`) + bench 验证 + 循环「下行计数+DJNZ」(`tools/mcs_loop.py`) +
> mcs251 隐私清理(filter-repo) + 后端 `opt-tags` 实验分支(`experimental/`)、双分支 CI；旧项目回归核验**
> （含修复 `irq_all` 空 XSEG 链接 bug、真机 zigmem `a1 ok b2 ok c3 ok d4 ok`）。
> 上一份：[`docs/交接-2026-09-18-优化标签与合规.md`](docs/交接-2026-09-18-优化标签与合规.md)
> —— **优化标签体系（放置 `data/idata/edata/xdata/exdata` + 等级 `O0–O3/Ofast/Os`，GCC 对齐）
> + `@tag` IR 提示 + `zigopt`/`zigbench` 示例；THIRD-PARTY 合规、SSH(443)、Release v0.1.0**、关键坑、复现。
> 上一份交接：[`docs/交接-2026-09-17-开源发布与CI.md`](docs/交接-2026-09-17-开源发布与CI.md)
> （三仓开源 + 便携工具链 CI，注意英文 Windows cp1252 坑）。
> **工作清单 / 下一步**见 [`docs/待推进-2026-09-19.md`](docs/待推进-2026-09-19.md)
> （等级细化、调试支持、外部存储、设备表/便携余项、旧优化脚本复查…）。
> 发布同步：`docs/发布同步策略.md`。更早：`docs/交接-2026-09-16-便携工具链与中断.md` 等。

速览：

- 全程**中文**；代码注释/笔记也中文；未经明确要求**不要 commit**；**push（含强推/推 tag）每次都先问**；结论要简短。
- **隐私红线（必守）**：**路径一律用相对路径**；文档/注释/笔记**不得有隐私**——**重点是本机
  文件路径**（`C:\Users\<名>`、工作区绝对路径、用户名、邮箱、授权码）；举例用
  `<workspace>`/`<user>` 占位；生成物（`.asm` 注释、日志、`.map`）入库前也要脱敏。
- **Zig 代码保持 0.16 兼容**：编译器与编辑器 LSP（ZLS）都是 Zig **0.16**；勿用 0.17+ 语法/API，
  也不用 0.16 已移除的（如 `std.fs.cwd()`），保证 ZLS 不报错。
- **已开源（2026-09-17）**：`manniuP/zig-mcs51-backend`（Zig MCS 后端，MIT）、
  `manniuP/sdcc-c251`（SDCC fork，**未改源码**）、`manniuP/mcs8051`（顶层集成仓：
  项目内容 + 两编译器子模块 + 便携工具链 CI，Apache-2.0）。详见最近交接。
- **单仓（2026-09-19）**：`mcs251` 与 `mcs8051` **合并为同一历史**——`mcs251` = 本地工作树、
  `origin = manniuP/mcs8051`（公开，`main`），**内容以公开仓为准**；发布 = `git push origin main`，
  流程见 `docs/发布同步策略.md`。
- **GitHub SSH 已配置**：`~/.ssh/id_ed25519_github`（ed25519，无口令）；远程用 `git@github.com:...`。
  旧优化脚本见工作区 `old-scripts/`（新旧版 + 已知问题标注）。
- 工作区：`<workspace>\`（本身非 git），含 `mcs251\`（**主项目** = `manniuP/mcs8051`，
  `origin` 即公开仓、分支 `main`；编译器在 `compiler/` 子模块 → `zig-mcs51-backend`）、
  `zig\`（fork 的旧 clone，现冗余，可作上游镜像）、`sdcc-c251\`（SDCC 源码镜像）、
  `docs\`（工作区文档）。主项目文档在 `mcs251\docs\README.md`；**跟上游方案/协定见
  `docs/26-上游跟进方案.md`、`docs/27-上游迁移协定.md`**（改编译器前先看 27）。
- **可自举（已解决）**：用**系统 zig**（0.16.0，`zig` 已在 PATH）从源码重建编译器，
  不再依赖那个会崩的 55MB bootstrap：
  `cd mcs251\compiler; zig build -Doptimize=ReleaseFast -Dno-lib -Dmcs-only --zig-lib-dir <workspace>\mcs251\compiler\lib`
  → 产物 `mcs251\compiler\zig-out\bin\zig.exe`（0.16.1），mcs51/mcs251 都能编。运行前设 `ZIG_LIB_DIR=<workspace>\mcs251\compiler\lib`。
  **`-Dmcs-only`**：只编入 MCS 后端（跳过 x86_64 等巨大后端的分析，构建更快；产物 ~6.7MB vs 全量 24MB）。
  已用 `.ihx` 逐字节对比确认它与全量编译器**收敛（输出完全一致）**；要完整多后端编译器时不带该选项即可。
  **重编编译器（自举）前需经用户确认**；本机工具清单见 `docs/AI-协作约定.md` 末尾。
  **改源码文件务必用编辑工具（Edit/Write），不要用 PowerShell `Get-Content|Set-Content` 回写**——
  PS5.1 默认按 GBK 解码会把 UTF-8 中文写乱、甚至并掉换行（本会话踩过）。
- 构建（在 `mcs251\` 下）：`xmake f --mcs_arch=mcs251`（下划线）→ `xmake build <目标>`；
  目标：`ptrtest`（C↔Zig 指针）、`uart`/`led`（C）、`zigled`/`zigasm`（**纯 Zig**，无 C）；
  可用 `--zig=<路径>` 指定编译器（默认优先 `zig\zig-out\bin\zig.exe`，退回 bootstrap）。
- **无板验证**：8 位 **mcs51** 可在软件仿真里跑通（WSL 构建的 ucsim_51 执行 `.ihx`）；
  自检工程 `examples/at89c52/sim`（`xmake build --mcs_arch=mcs51 simtest`）。
  **251 核在 ucsim 里是空壳**，只能靠真实硬件。做法/坑见 `mcs251\docs\07`。
  **STC15/IAP15 模拟**：UCsim 自带版**没有** STC 模型，但 GitHub `CrispStrobe/ucsim-stc`
  （GPL-2，**只当外部工具，勿并进 MIT 产物**）补了 `STC12/STC15/STC89/STC15W` 四个模型
  （`STC15F2K60S2`，1T、AUXR、Timer2、PCA、ADC、端口模式、双 DPTR）。
  **定位：只近似「8051 核 + STC15/STC8/AI8051U 共有的经典 SFR 与时序」，不能替代真机**——
  STC8 之后与 AI8051U 的新 SFR/外设（DMA/增强PWM/USB/IAP 细节/时钟树/更多定时器串口…）
  STC15 模型里没有或不同，必须真机。已构建在 WSL
  `~/ucsim-stc/ucsim/src/sims/s51.src/ucsim_51`，用法 `-t STC15`（或 STC12/STC89/STC15W），
  其余同 ucsim_51（`-S in=/dev/null,out=-` + 命令文件）。搜索 GitHub 用 `webfetch` 打
  `https://api.github.com/search/...` 即可，无需 GitHub MCP。
- **251 真机（AI8051U）已验证**：芯片程序存储器在 **FF:0000–FFFF**、复位 PC=**FF:0000**，
  所以 mcs251 必须加 **`--code-loc 0xff0000`**（否则代码链在 0x0000，芯片取不到指令=什么都不跑）；
  `xmake.lua` 的 mcs251 链接步骤已加。`ptrtest` 真机 P1 全 0V = C↔Zig 3 字节指针互操作通过。
  芯片上电 I/O 默认**高阻输入**，要驱动需先配 `PxM0/PxM1`；硬件选项须设 CPU 指令模式=32-Bit。
- **纯 Zig 驱动 GPIO / 内联汇编**（2026-09-15，需重建后的编译器）：
  `@ptrFromInt(0x80–0xFF)` 走 **SFR 直址**（`mov a,dir8`）；`asm volatile("...")` 支持
  **无操作数**形式；`inline fn` 现已真正内联（后端修了 `dbg_inline_block`）。
  用 comptime 拼字符串做「宏」（**别用 `std.fmt.comptimePrint`**，会把整个 std 拖进编译）+
  `inline fn` 把常量编进 asm，可实现 SFR **位操作**等 Zig 不便做的事。
  **共享宏库 `lib/mcs251.zig`**：`sfrWrite/sfrOr/sfrAnd/bitSet/bitClr/bitCpl/sfrPtr/nop` +
  `dataWrite/xdataWrite/idataWrite/dataPtr/xdataPtr`（带 `///` 示例，zls 可见）；
  构建时注入命名模块：`--dep mcs -Mroot=<源> -Mmcs=<仓库>/lib/mcs251.zig`，源码里 `@import("mcs")`
  （`@import` 不能越出模块根，勿用 `../`）。`zigled`/`zigasm` 真机 P1.1 1Hz 闪。
  纯 Zig 链接用 `crt0.asm`（HOME 区，含空 `PSEG/ISEG/BSEG` 声明）+ `--code-loc 0xff0000`。
  详见 `mcs251/docs/06` §1.2。
- **中断 & 数据空间（手动分配）**：
  `@ptrFromInt(0x00–0xFF)` 走 **direct**（`data` 低 RAM + SFR）；`≥0x100` 走 MOVX（`xdata`）；
  `idata` 用内联汇编宏（`idataWrite`；读受限）。地址须 `comptime` 常量。
  中断：ISR 用 `export fn` + 内联汇编（存 ACC/PSW…再 `reti`），向量表写在 `crt0.asm` 的 HOME 区
  （复位用 3 字节 `ljmp`，T0 在 `FF:000B` `ejmp _t0_isr`）。示例 `examples/ai8051u/zig_irq/`
  （`xmake build zigirq`），真机 T0 中断 1Hz 闪灯通过。
  **⚠️ ISR 本身必须无栈帧**：若 ISR 里直接写带局部量的 Zig 代码，后端会加 `add spx,#N` prologue 与
  `sub spx,#N; eret` epilogue，而 `reti` 跳过 epilogue → **每次中断泄漏 N 字节 SPX，很快崩**。
  正确：ISR 只放无帧内联汇编，逻辑放普通 `export fn`，由 `ecall _handler` 调用（有 prologue/epilogue+`ret`）。
  示例 `examples/ai8051u/zig_t0print/`（`xmake build zigprint`）：T0 1ms 中断里每秒 UART1 打印一行；
  QEMU + **真机 AI8051U-34K64**均实测每秒 `t0\r\n`（真机 COM8@115200，行间隔 1.00s）。见 `mcs251/docs/20`。
- **变量按空间分配（`linksection`，已实现）**：`var x: u8 linksection(".data")` → `DSEG`
  （直接寻址）、`.idata` → `ISEG`（`mov r0,#addr; mov a/@r0` 间接）、`.xdata` → `XSEG`
  （**24 位 `mov dpxl,#(sym>>16); mov a,@dpx`**，默认）。数据空间按地址分：`<0x100` direct、
  `0x100–0xFFFF` edata（`movx @dptr`）、`≥0x10000` xdata（`@dpx`）。
  链接加 `--data-loc 0x30 --idata-loc 0x80`，crt0 空声明 `DSEG`；`.data` 仅 0x00–0x7F、基址 0x30。
- **放置/优化等级标签（2026-09-17）**：`linksection` 支持**放置** `data`/`idata`/`edata`/`xdata`/`exdata`
  与**优化等级**（与 GCC 对齐）`O0`–`O3`/`Ofast`/`Os`，可空格组合（`lib/mcs251.zig` 导出 `m.data`…`m.Os`）；
  无标签→编译器自决、等级默认 `O3`。后端按标签选体积/速度并把 `; @tag …` 传中间层（`mcs_ir` 消费）。
  示例 `examples/ai8051u/zig_opt/`（`xmake build zigopt`，QEMU/真机 `opt 11223344 060a`）。见 `mcs251/docs/17`。
  周期测量示例 `examples/ai8051u/zig_bench/`（Timer0 1T 自由计数，`xmake build zigbench`，
  真机 UART 打印 data/idata/edata/xdata 读延迟与 O0/O5 运行周期 + 空循环基线）。
  示例 `examples/ai8051u/zig_mem/`（`xmake build zigmem`）：写互异模式回读，UART 打印
  `a1 ok b2 ok c3 ok d4 ok`（真机通过）。普通变量仍建议直接交给编译器分配。
  详见 `docs/session-2026-09-15.md`。
- **运行期下标 + 运行期指针 + 编译期指针物化（mcs251，真机通过，2026-09-15）**：后端支持
  ① 全局/固定地址 **xdata u8 数组**的 `buf[i]`（`i` 运行期）；② **运行期指针** `p[i]`
  （`p: [*]u8` 参数/变量）；③ 把 `&全局数组`/`@ptrFromInt` 存入指针变量（`s_buf = buf`）物化为
  帧内 3 字节地址（否则报 `unsupported constant operand`）。生成的绝对地址均经 `@dr28` 读写
  （`add a,#_buf; addc a,#(_buf>>8); addc a,#(_buf>>16)`，对齐 SDCC）。限制：仅 mcs251、仅 xdata、
  元素 1 字节、下标在帧槽。**同时修了多字节标量写全局/固定/运行期指针的端序 bug**（原按小端写、
  读回按大端，与 SDCC/C 大端不一致）→ 现按 `i → size-1-i` 写。见 `mcs251/docs/06 §1.2`。
- **结构体字段访问（mcs251，2026-09-15）**：后端实现 `struct_field_ptr`/`_index_N` 与
  `struct_field_val`。编译期基址（局部/全局/固定地址）折进偏移；运行期指针基址经 `emitElemPtr`
  物化 `load(base)+off`（可链式 `a.b.c`、字段指针运行期下标 `e.buf[i]`）。另把编译期常量指针
  解析推广为递归 `resolveConstPtr`（沿 `.field`/`.arr_elem`/`.opt_payload`/`.eu_payload` 累加偏移），
  故**普通 `struct`（非 `extern`）的全局字段也走通**（此前只认 `.nav`/`.int` 直接基址）。
  限制：字段为 1~4 字节标量或聚合视图；切片字段值未实现。见 `mcs251/docs/06 §1.2`。
- **COBS 库 `lib/cobs/`（平台无关）**：把 COBS + 轻量日志帧抽成独立库，**只把编码结果写进
  调用方提供的缓冲区**，输出方式由调用方决定。两份等价实现：Zig `cobs.zig`（**可重入**：
  `Encoder` 结构体，多实例；另留绑定模块级实例的免句柄 API）、C `cobs.h`/`cobs.c`
  （可重入，`cobs_enc_t` 句柄）。**注意代码尺寸**：mcs 后端每个内联调用点各生成一份代码，
  全内联时 ziglog 单 `_main` 达 ~64KB 顶满 Flash（AiCube 报溢出、`msg` 帧被截坏）；`Encoder`
  方法用普通 `fn`（非 `inline`）后 CSEG ~12.5KB。同后端按函数名出标签、不修饰命名空间，
  故模块包装与同名方法会重名 → 包装须 `inline`。原始帧
  `0x7E,id(2,LE),参数…,XOR`，整帧 COBS 后以 `0x00` 定界。示例：`xmake build ziglog`（Zig）、
  `xmake build ccobs`（C）+ 主机解码 `decode.ps1`（切帧/COBS 解码再解析；PS，UTF-8 带 BOM）。
  主机测试：`zig run lib/cobs/cobs_zig_test.zig`、`zig cc lib/cobs/cobs_c_test.c lib/cobs/cobs.c`。
  真机 821 帧 `boot/count/xy/cvar/msg/g16` 通过。详见 `lib/cobs/README.md`、`mcs251/docs/06 §1.2`。
- **构建层瘦身工具 `mcs251/tools/mcs_opt.py`（2026-09-15，无需重编 zig.exe）**：
  在 `fix_mcs_labels.py` 之后对 Zig→asm 做局部优化（`xmake.lua` 各 Zig 目标已自动内联调用）：
  **R1** 合并连续 `inc/dec spx,#1|2|4` → 单条 `add/sub spx,#imm16`；**R2** 直块内值编号删冗余 `mov`；
  **R3** `mov a,X; mov Y,a`→`mov Y,X`；**R4** A 为编译期常量时直接写目标寄存器；
  **R5** 回收无用代码/跳转：**R5a** `ejmp L` 紧跟 `L:`（跳到下一行）删掉；**R5b** 无条件转移后、
  下一标签前的不可达指令删掉。只在基本块内、不跨标签/分支/调用，未知指令当屏障；
  自测 `python tools/mcs_opt.py --self-test`（8/8）。实测 CSEG（raw→opt）：`ziglog` 12563→10360（-17.5%）、
  **`zigmem` 10268→6155（-40%）**、`zigbuzz` 13825→11348（-18%）、`ptrtest` 2095→1838（-12%）；mcs51 很小
  （`simtest` 761→753）。验证：mcs51 `simtest`（ucsim）行为不变；**mcs251 真机（AI8051U）通过**——
  `ziglog` 六帧齐全、`zigmem` 四空间 `a1 ok b2 ok c3 ok d4 ok`。完整实测表见 `mcs251/docs/15`。
  这是「不重编编译器也能瘦身」的过渡手段，根治仍靠后端输出更紧凑（`docs/交接` §5.10③）。
- **本轮新工程/目标**：`zigled`/`zigasm`/`zigirq`/`zigprint`/`ziguart`/`zigmem`/`zigbuzz`/`ziglog`（均纯 Zig，mcs251）；`ziguart`=UART1 接收中断回环（中断号 4，`FF:0023`）；
  `uart`/`led`（C）；`ptrtest`（C+Zig）。真机均通过（P1.1 闪灯 / T0 中断 / 三空间 / P3.6 蜂鸣器 / 二进制日志）。
- **设备描述表（芯片契约，2026-09-16）**：`mcs251/devices/stc/`（**176 型号** `model_matrix.toml`
  + 家族/头映射 + `gen/*.toml` + `器件矩阵.md`），工具 `tools/mcs_device.py`（`--expand`、
  `--emit summary|sdcc-args|lk|crt0|compiler-json`）、`tools/mcs_sfr.py`（Keil 头→SFR，`sbit BASE^n`
  `BASE%8≠0` 走掩码）。构建：`xmake f --device=<t.toml>`（默认 `ai8051u-34k64`），`xmake build
  devhdr|devled|devzig`。**编译器按表自动放置变量**：`MCS_DEVICE`=内联 JSON →
  `src/codegen/mcs/device.zig`，显式 `linksection` 优先、否则 ≤2B→data、其余→设备默认 xdata；
  未设 `MCS_DEVICE` 时旧行为不变。坑：`linksection` 是 Zig 关键字、Zig 0.16 无 `std.fs.cwd()`。
  详见 `docs/交接-2026-09-16-设备表与便携构建.md`、`mcs251/devices/README.md`。
- **便携工具链集（2026-09-16）**：`<workspace>\portable\ai8051u\`——**共享 `toolchain/` +
  四个隔离子目录** `usb_cdc/`（C，`build.cmd` 直接调 SDCC）、`ziglog/`（纯 Zig COBS 日志）、
  `t0print/`（纯 Zig 定时器中断打印）、`uart_echo/`（纯 Zig UART1 接收中断回环），各有独立
  `build.cmd`（Zig 示例另有 `build.zig`）。
  根 `build.cmd [usb_cdc|ziglog|t0print|uart_echo|all]` 调度（默认 all）。
  自带 `toolchain/zig`(全量 24MB) + `toolchain/sdcc`(整棵树，含 `libexec\...\cc1.exe`) +
  `toolchain/mcstools/mcstools.exe`。**零环境变量可用**：各 `build.cmd` 自设 `ZIG_GLOBAL_CACHE_DIR`/`ZIG_LIB_DIR`；
  `build.zig` 用 `b.graph.zig_exe` + `mcstools.exe` 后处理（目标机无需 Python；`mcstools.exe` 由
  `tools/mcstools.py` + `tools/build_mcstools.ps1` 冻结）；Zig 示例另带 `device.json`（设备存储表，
  `make_portable.ps1` 生成、`@embedFile` 注入 `MCS_DEVICE`）→ 放置与主工程一致，**`ziglog`/`t0print`
  的 `.asm` 与 `.ihx` 均与主工程逐字节相同**。USB-CDC 每 ~1s 打 `hello world`
  （CDC IN 走 EP1：`usb_write_reg(INDEX,1)`→`FIFO1`→`INCSR1=INIPRDY`；库**未定义** `usb_bulk_intr_in`）。
  **注意**：`-Dmcs-only` 的 dev env 缺宿主特性（`build_command`/`coff2_linker`…），`zig build` 当驱动
  请用**全量**编译器；`.cmd` 须纯 ASCII+CRLF（`make_portable.ps1` 已是 ASCII 注释）。
  **`zig cc`/`zig c++` 不能编 mcs251 的 C/C++**：走自研 C 前端 aro（未实现目标码生成），且编译器
  `have_llvm=false`、LLVM 也无 MCS-251 后端——C 一律走 **SDCC**（如 `usb_cdc`）。见 `docs/06 §7`。
  **cmd 传参坑**：`%1` 会把 `=` 当分隔符（`-Dmcs-small=true` 变成两个 token），转发参数要用 `%*`
  （`build.cmd` 根调度用 `for /f "tokens=1,*"` 从 `%*` 拆）。Zig 示例可选 `-Dmcs-small=true` 走
  `-OReleaseSmall`（`ziglog` 24852→24309 B）。
  **8 位（mcs51）**：`usb_cdc`/`t0print`/`uart_echo` 支持 `-Darch=mcs51`（默认 mcs251）——SDCC `-mmcs51`
  + `sdas8051` + `mcs51-freestanding`；`t0print`/`uart_echo` 启动/向量改用 `crt0_mcs51.asm`（复位 `0x0000`、
  8 字节向量、`ljmp`、`mov sp,#0x7f`、`lcall _main`），ISR 里 `ecall`→`lcall`；位操作数汇编语法按架构选
  （sdas8051 `addr^bit` / sdas251 `addr.bit`）。**`ziglog` 仅 mcs251**：mcs51 后端每函数一块静态帧、
  全落内部 RAM 直接区（≤128B），其 DSEG 已 200+B 链不上（8 位 COBS 用 C），传 mcs51 会明确报错。
  主工程同步点：`lib/mcs251.zig`（bit 语法 arch 化）、`examples/ai8051u/zig_{t0print,uart_echo}/{*.zig,crt0_mcs51.asm,portable/*}`、
  `examples/ai8051u/usb_cdc/portable/build.cmd`、`examples/ai8051u/zig_log/portable/build.zig`、
  `examples/portable/{README.md,build.cmd}`、`tools/make_portable.ps1`（拷 `crt0_mcs51.asm`）。
- **8 位 C↔Zig 共享 ABI**：C 侧用 `sdcc --stack-auto`。参数0→DPL/DPH/B/A，
  参数2..N 逆序压栈；`__xdata T*` ↔ Zig `[*]T`（2 字节，DPTR+MOVX）；
  全局变量为 xdata 符号（Zig `export var`/`extern var` ↔ C 同名）。已支持
  单标量/多参数/指针/全局；切片、`@ptrFromInt` 未实现。见 `mcs251\docs\06` §1.1。
- MCS-251 指针：用**重建后的编译器**，直接 `buf[i]` 已能生成 DR28 间接寻址
  （`.ptr_rt` 修复生效）；旧的 `(@as(*u8, @ptrCast(buf + i))).*` workaround 只在用
  55MB 坏 bootstrap 时才需要。切片 `Lxx` 标签撞名由构建层 `tools/fix_mcs_labels.py`
  自动修复（xmake/driver 已接入），不再需要“一个 .asm 一个分支函数”。
- 大件与恢复方法见 `mcs251\docs\12-可清理与重新下载清单.md` 与
  `docs\可清理与重新下载清单.md`；删大件前先写清单并问用户。
- STC 工具（MCP）：`stc-manual`=知识库（远程）；`stc-gui`=驱动本机 AiCube-ISP
  （`http://localhost:8051/mcp`，需 AiCube 在运行 + 重启 opencode）。**已接 AI8051U-34K64（USB-Writer）**，
  251 `ptrtest` 真机已跑通（见上条）。
- 用户当场指令优先于本文。
