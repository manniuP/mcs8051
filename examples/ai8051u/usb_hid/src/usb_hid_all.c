/* usb_hid_all.c —— 单一编译单元：main + 全部 ISR 放同一模块（SDCC 才会生成完整 IVT）。
 * 只编译本文件 + 链接；不要再单独编译下面的 .c（符号会重复）。详见 docs/14。
 */
#include "main.c"
#include "usb.c"
#include "usb_desc.c"
#include "usb_req_std.c"
#include "usb_req_class.c"
#include "usb_req_vendor.c"
#include "util.c"
