# V853 Toolchain for FFmpeg Launcher
# 继承自主工具链配置

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

# V853 SDK路径 (优先使用环境变量)
if(DEFINED ENV{V853_SDK_PATH})
    set(V853_SDK_PATH "$ENV{V853_SDK_PATH}" CACHE PATH "V853 SDK Path" FORCE)
    message(STATUS "使用环境变量 V853_SDK_PATH: ${V853_SDK_PATH}")
elseif(EXISTS "/opt/v853_sdk")
    set(V853_SDK_PATH "/opt/v853_sdk" CACHE PATH "V853 SDK Path")
    message(STATUS "使用Docker路径: ${V853_SDK_PATH}")
else()
    set(V853_SDK_PATH "${CMAKE_SOURCE_DIR}/../../SDK/tina-v853-open" CACHE PATH "V853 SDK Path")
    message(STATUS "使用相对路径: ${V853_SDK_PATH}")
endif()

set(TOOLCHAIN_PATH "${V853_SDK_PATH}/prebuilt/rootfsbuilt/arm/toolchain-sunxi-musl-gcc-830/toolchain")

# 编译器
set(CMAKE_C_COMPILER   "${TOOLCHAIN_PATH}/bin/arm-openwrt-linux-gcc")
set(CMAKE_CXX_COMPILER "${TOOLCHAIN_PATH}/bin/arm-openwrt-linux-g++")

# Sysroot - 使用工具链自带的sysroot（Buildroot输出目录不存在）
set(CMAKE_SYSROOT "${TOOLCHAIN_PATH}")

# 查找路径
set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# 编译选项
set(CMAKE_C_FLAGS   "-march=armv7-a -mfpu=neon -mfloat-abi=hard")
set(CMAKE_CXX_FLAGS "-march=armv7-a -mfpu=neon -mfloat-abi=hard")
