cmake_minimum_required(VERSION 3.20)
project(vscode_c_cmake C)

# 生成 compile_commands.json（在 build/ 下；供其它工具）。clangd 用根目录的 compile_flags.txt。
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

add_executable(blink src/main.c)
