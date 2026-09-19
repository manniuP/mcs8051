/* usb_cdc_all.c —— 单一编译单元，把 main + 全部中断服务函数放进同一模块。
 *
 * 原因：SDCC（mcs251）只在**定义了 main 的那个模块**里生成中断向量表
 * （见 SDCCglue.c 的 createInterruptVect），而本工程的 usb_isr/uart2_isr
 * 原本在 usb.c/uart.c。分开编译时 IVT 里不会有这两个向量，中断不会触发。
 * 把它们合到一个编译单元后，SDCC 会生成完整的 IVT（`ejmp _usb_isr` 等）。
 *
 * 用法：只编译本文件 + 链接（不要再单独编译下面这些 .c，否则符号重复）。
 */
#include "main.c"
#include "uart.c"
#include "usb.c"
#include "usb_desc.c"
#include "usb_req_std.c"
#include "usb_req_class.c"
#include "usb_req_vendor.c"
#include "util.c"
