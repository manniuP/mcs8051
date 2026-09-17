# CMake toolchain：SDCC (MCS-251 / AI8051U)。
#
# 用法：
#   cmake -S . -B build -G Ninja -DCMAKE_TOOLCHAIN_FILE=cmake/sdcc-mcs251.cmake
#   cmake --build build
#
# 说明：CMake 官方不认识 SDCC，这里用「FORCED 编译器」跳过探测，直接当普通 C 编译器用：
#   - 编译：sdcc <flags> -o xxx.rel -c xxx.c
#   - 链接：sdcc <flags> xxx.rel -o app.ihx
# compile_commands.json 供 clangd 用；SDCC 专属 flag 由 .clangd 里的 CompileFlags.Remove 去掉。

set(CMAKE_SYSTEM_NAME Generic)
set(CMAKE_SYSTEM_PROCESSOR mcs251)

get_filename_component(REPO_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../.." ABSOLUTE)

set(MCS_SDCC "${REPO_ROOT}/tools/sdcc-mcs251-windows-x64/sdcc-mcs251/bin/sdcc.exe"
    CACHE FILEPATH "SDCC (mcs251) 可执行文件路径")
set(MCS_INCLUDE "${REPO_ROOT}/lib/include" CACHE PATH "SDCC 头文件目录（c51.h / ai8051u_sfr.h）")

set(CMAKE_C_COMPILER "${MCS_SDCC}")
set(CMAKE_C_COMPILER_FORCED TRUE)
set(CMAKE_C_OUTPUT_EXTENSION ".rel")
set(CMAKE_EXECUTABLE_SUFFIX ".ihx")

# AI8051U：程序存储器在 FF:0000，代码链在 0xff0000；data/idata 基址按 crt0 约定。
set(MCS_CPU_FLAGS "-mmcs251 --model-large --code-loc 0xff0000 --data-loc 0x30 --idata-loc 0x80")
set(CMAKE_C_FLAGS_INIT "${MCS_CPU_FLAGS} -I${MCS_INCLUDE}")
