# projects

可上机的完整工程集合。每个工程都是「C（SDCC）+ Zig（自举后端）」混编，并有
自己的 `build.ps1` 与 `README.md`。

| 工程 | 说明 |
| --- | --- |
| [`ai8051u_blink/`](ai8051u_blink/) | AI8051U 流水灯：STC HAL 驱动 P1，Zig 计算图案（8051 兼容模式） |

创建新工程的步骤与约定见 [`../docs/`](../docs/README.md)。最小起手方式：
复制 `ai8051u_blink/`，改 `main.c` / `led.zig` / `build.ps1` 中的文件与目标即可。
