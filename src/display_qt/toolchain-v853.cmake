# V853 Cross-Compilation Toolchain File
#
# 使用方法:
#   cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

# V853 SDK路径 (优先使用环境变量)
if(DEFINED ENV{V853_SDK_PATH})
    set(V853_SDK_PATH "$ENV{V853_SDK_PATH}" CACHE PATH "V853 SDK Root Path" FORCE)
    message(STATUS "使用环境变量 V853_SDK_PATH: ${V853_SDK_PATH}")
elseif(EXISTS "/opt/v853_sdk")
    set(V853_SDK_PATH "/opt/v853_sdk" CACHE PATH "V853 SDK Root Path")
    message(STATUS "使用Docker路径: ${V853_SDK_PATH}")
else()
    set(V853_SDK_PATH "${CMAKE_SOURCE_DIR}/../../SDK/tina-v853-open" CACHE PATH "V853 SDK Root Path")
    message(STATUS "使用相对路径: ${V853_SDK_PATH}")
endif()

# 工具链路径
set(TOOLCHAIN_PATH "${V853_SDK_PATH}/prebuilt/rootfsbuilt/arm/toolchain-sunxi-musl-gcc-830/toolchain"
    CACHE PATH "Toolchain Path")

# 编译器
set(CMAKE_C_COMPILER   "${TOOLCHAIN_PATH}/bin/arm-openwrt-linux-gcc")
set(CMAKE_CXX_COMPILER "${TOOLCHAIN_PATH}/bin/arm-openwrt-linux-g++")

# Sysroot (V853的根文件系统)
set(CMAKE_SYSROOT "${V853_SDK_PATH}/buildroot/buildroot-201902/output/target")

# 查找路径设置
set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# 编译选项
set(CMAKE_C_FLAGS   "-march=armv7-a -mfpu=neon -mfloat-abi=hard" CACHE STRING "C flags")
set(CMAKE_CXX_FLAGS "-march=armv7-a -mfpu=neon -mfloat-abi=hard" CACHE STRING "CXX flags")

message(STATUS "V853 Toolchain Configuration:")
message(STATUS "  SDK Path: ${V853_SDK_PATH}")
message(STATUS "  Toolchain: ${TOOLCHAIN_PATH}")
message(STATUS "  C Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "  CXX Compiler: ${CMAKE_CXX_COMPILER}")
message(STATUS "  Sysroot: ${CMAKE_SYSROOT}")
