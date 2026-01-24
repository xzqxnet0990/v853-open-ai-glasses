cmake_minimum_required(VERSION 3.10)
project(TouchpadManager)

# 编译器由toolchain文件配置，不要在这里硬编码
# 使用 -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake 指定工具链

add_executable(touchpad_manager launch.cpp)

