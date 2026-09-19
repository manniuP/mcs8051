# AI 协作约定（yuyan 工作区）

> 目的：让 AI 助手**快速上手、不踩坑**。这是一份“导航 + 捷径”，不是限制。
> **任何与本文冲突的用户当场指令，以用户指令为准。**

## 0. 基本

- 全程用**中文**交流；代码注释、提交说明、笔记也用中文。
- **隐私红线（必守）**：**所有路径一律用相对路径**；文档、注释、笔记、提交说明里
  **不得出现任何隐私信息**，**重点是本机文件路径**（如 `C:\Users\<名>`、工作区绝对路径、
  用户名、邮箱、KEIL/软件授权码等）。必须举例时用 `<workspace>`、`<user>`、`<repo>` 等占位，
  **不要写入真实路径**；生成物（`.asm` 注释、日志、`.map` 等）入库前同样要检查并脱敏。
- 未经用户明确要求，**不要 `git commit`**；**`git push`（含 force push、推 tag）每次都要先问**
  用户，即使任务里带有「发布 / 同步 / 发 tag」等字样。
- **Zig 代码保持 0.16 兼容**：编译器与编辑器 LSP（ZLS）都是 Zig **0.16**；勿用 0.17+ 语法/API，
  也不用 0.16 已移除的（如 `std.fs.cwd()`），保证 ZLS/编辑器不报错。
- 干完给**简短结论**，不要长篇解释（除非用户要细节）。
- 改文件前先读；不要臆测路径，用 Grep/Glob/Read 确认。

## 1. 工作区结构

```
<workspace>\                 （本身不是 git 仓库；只有子目录是）
  docs\                        工作区级文档（本文件在这里）
  mcs251\                      主项目（git，分支 main，origin=manniuP/mcs8051）；compiler/ 子模块 → zig-mcs51-backend
  zig\                         fork 的旧 clone（分支 mcs251-backend），现冗余/可作上游镜像
  sdcc-c251\                   SDCC MCS-251 源码镜像（git；origin=gevico/sdcc-c251）
```

- **主项目 = `mcs251`**，文档入口 `mcs251\docs\README.md`；**编译器源码在 `mcs251\compiler`（子模块）**。
- `zig\`、`sdcc-c251\` 只是源码/镜像，**构建用不到**（工具链是预编译好的）。

## 2. 技术路线（不要偏离）

**不自举**，只走直连管线：

```
Zig 源 --(zig build-obj)--> .asm --(sdas251)--> .rel
C   源 --(sdcc -mmcs251 -c)--> .rel
                       --(sdcc 链接)--> .ihx
```

- 编译器：**可自举了**。用**系统 zig**（0.16.0，`zig` 在 PATH）从源码重建：
  ```powershell
  cd <workspace>\mcs251\compiler
  zig build -Doptimize=ReleaseFast -Dno-lib --zig-lib-dir <workspace>\mcs251\compiler\lib
  # 产物：mcs251\compiler\zig-out\bin\zig.exe（0.16.1）
  ```
  - 运行前设 `ZIG_LIB_DIR=<workspace>\mcs251\compiler\lib`。
  - 旧的 `compiler\zig-out\bin\zig.exe`（55 MB）是坏 bootstrap（会 miscompile stage2 导致崩溃），
    现在只在没重建时兜底；不要再用它当“唯一可用编译器”。
- SDCC mcs251 工具链：`mcs251\tools/sdcc-mcs251-windows-x64\sdcc-mcs251\bin\`
  （`sdcc.exe` / `sdas251.exe` / `sdld.exe`）。

## 3. 常用命令

```powershell
# 工作目录：<workspace>\mcs251
xmake f --mcs_arch=mcs251      # 注意是「下划线」，不是 --mcs-arch
xmake build ptrtest            # C+Zig 混编 -> build\examples\ai8051u\ptrtest\ptrtest.ihx

# 单文件 Zig -> asm（参数用数组传；-femit-bin= 整体加引号）
$env:ZIG_LIB_DIR = "<workspace>\mcs251\compiler\lib"
& compiler\zig-out\bin\zig.exe build-obj -target mcs251-freestanding "-femit-bin=x.asm" x.zig
```

## 4. 代码生成约定（后端，务必看）

- **C↔Zig 共享 ABI（8 位 / mcs51，重建后的编译器）**：C 侧用 `sdcc --stack-auto`。
  参数0→DPL/DPH/B/A；参数2..N 逆序压栈（callee 在入口 `SP-(2+Σsize)` 读取）；返回
  DPL/DPH/B/A；`__xdata T*` ↔ Zig `[*]T`（2 字节，DPTR+MOVX）；全局变量是 xdata 符号
  （Zig `export var`/`extern var` ↔ C 同名）。已支持单标量/多参数/指针/全局；
  切片、`@ptrFromInt(addr).*` 未实现。
- **指针**：mcs251 下直接 `buf[i]` 即生成 `mov @dr28,r3`（重建后的编译器含 `.ptr_rt` 修复）；
  mcs51 下 `[*]T` 是 2 字节 xdata 指针，经 `DPTR + MOVX` 读写（`buf[i]`、`@ptrCast(buf+i).*`、
  `buf+off` 都可用）。
- **不要**用切片 `buf[0..n]` 做元素访问：越界检查会生成 `Lxx` 标签，而后端标签
  **每个函数从 0 重新编号**，同文件多分支函数会撞名，`sdas251` 报
  `multiple definitions` / `phase error`。**此问题已由构建层** `tools/fix_mcs_labels.py`
  自动修复（`xmake` / `driver/build.ps1` 已接入，按函数给 `Lxx` 加前缀），
  同一 `.asm` 放多个含分支的函数现在可以正常汇编。
- **运行期下标 / 运行期指针（mcs251）**：全局或固定地址 xdata u8 数组的 `buf[i]`、以及
  **运行期指针** `p[i]`（`p: [*]u8`）都已支持，物化为 3 字节绝对地址（`add a,#_buf;
  addc a,#(_buf>>8); addc a,#(_buf>>16)`）；`&全局数组`/`@ptrFromInt` 存入指针变量也会物化。
  仅 mcs251 / xdata / u8 元素 / 下标在帧槽。**多字节标量写全局/固定/指针按大端**
  （`i → size-1-i`，与 SDCC/C 一致）。
- **结构体字段访问（mcs251）**：`struct_field_ptr`/`_index_N` + `struct_field_val`；编译期基址折
  进偏移、运行期指针经 `emitElemPtr` 物化，支持链式 `a.b.c` 与字段指针运行期下标 `e.buf[i]`。
  递归 `resolveConstPtr` 解析 `.field`/`.arr_elem` 等链，普通 `struct` 全局字段也可用。
- **COBS 库 `lib/cobs/`**：平台无关，只把编码结果写进**调用方提供的缓冲区**；Zig（`Encoder`
  结构体，可重入）与 C（可重入）双接口；Zig 另留免句柄单实例 API。示例 `ziglog`/`ccobs`。
  详见 `mcs251/lib/cobs/README.md`。
- 背景、能力矩阵与验证见 `mcs251\docs\06-常见问题与限制.md`、`07-调试笔记-ptr_rt自举崩溃定位.md`。

## 5. 磁盘 / 大文件

- 被 `.gitignore` 忽略、**不入库**的大件：`mcs251\compiler（系统 zig 重建）\`、
  `mcs251\tools/sdcc-mcs251-windows-x64\`、`mcs251\vendor\`、`.zig-cache*`，
  以及工作区的 `yuyan\zig\`、`yuyan\sdcc-c251\`。
- 清理清单与恢复方法：
  `mcs251\docs\12-可清理与重新下载清单.md`、`docs\可清理与重新下载清单.md`。
- 删大件前**先写清单、并确认用户**；能重下/重克隆的才删。

## 6. PowerShell 5.1 坑

- 给原生程序传参用数组 `& $exe @args`，避免 PS 截获 `-xxx`。
- `cmd /c` 在沙箱里不可用。
- 含中文的 `.ps1` 必须 **UTF-8 带 BOM**，否则乱码/语法错误。
- 控制台里的中文可能显示成乱码，但**文件内容是对的**；判断内容用 Read/Grep，
  不要凭控制台乱码下结论。

## 7. 文档位置（全部集中，别再散落）

- 工作区文档：`<workspace>\docs\`（本文件所在）。
- 主项目文档：`<workspace>\mcs251\docs\`（入口 `README.md`）。
- 历史会话录音：`<workspace>\docs\session-*.md`、`docs\记录点.md`、
  `docs\初步确定方案.md`（仅供追溯，非当前事实）。

## 8. 遇到不确定

- 先读 `mcs251\docs\` 与两份清理清单；再查历史录音。
- 破坏性/大范围操作（删除、git 历史、批量移动）**先问用户**。
- 信息可能过期：以仓库当前状态（文件、git log）为准。

## 9. STC 工具（MCP）

已配置两个 MCP（见全局 `~/.config/opencode/opencode.jsonc` 的 `mcp` 段，改动后**需重启 opencode**）：

| 名称 | 端点 | 用途 |
| --- | --- | --- |
| `stc-manual` | `https://help.stcaimcu.com/mcp`（远程） | STC 知识库：查数据手册、论坛 |
| `stc-gui` | `http://localhost:8051/mcp`（本机） | 驱动 **AiCube-ISP V6.97+** 的 GUI：自动下载/烧录、判断成功、改硬件选项、开串口助手 |

`stc-gui` 的 9 个工具（GUI 自动化，逐步操作）：
`list_windows → list_controls → tab_list/tab_select → combo_list/combo_select → click → get_text → get_info`。

注意事项：

- 前提：`AiCube-ISP-v6.97A.exe` 正在运行（端口 8051 由它监听，服务是内嵌的）。
  `http://localhost:8051/` 只是**帮助页**，真正的端点是 `/mcp`。
- `hwnd` **每次程序重启都会变**，必须先 `list_windows` 重新发现。
- 只能操作该程序**自己的窗口**，其它程序被过滤。
- **尚未接入开发板**：现在无法真正下载/验证；等接了板子再走“编译 → 打开 AiCube → 选芯片/HEX → 下载 → get_text 核对”。
- 实测（2026-09-14）：对 `/mcp` 发标准 JSON-RPC（`initialize` / `tools/list`）一律回
  `{"error":{"code":-32601,"message":"Unknown method"}}`，连非法 JSON 也一样 →
  工具分发层暂未响应。若重启 opencode 后 `stc-gui` 工具不可用，先确认 AiCube 版本/状态。


# 下方为用户填写
关于自举需经我确认
工具：
C:\Program Files\CMake
C:\Program Files\dotnet
C:\Program Files\Git
C:\Program Files\LLVM
C:\Program Files\PuTTY
C:\Program Files\STMicroelectronics
C:\Program Files\xmake
C:\Program Files (x86)\7-Zip
C:\Program Files (x86)\Arm GNU Toolchain arm-none-eabi
C:\Program Files (x86)\dotnet
C:\Program Files (x86)\SDCC
C:\Program Files (x86)\STMicroelectronics
C:\ST\STM32CubeCLT_1.22.0
C:\Users\<user>\.vcpkg
C:\Users\<user>\vcpkg
C:\Users\<user>\zls
