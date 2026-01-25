# V853 Toolchain for System Services

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

# V853 SDK路径 (优先使用环境变量)
if(DEFINED ENV{V853_SDK_PATH})
    set(V853_SDK_PATH "$ENV{V853_SDK_PATH}" CACHE PATH "V853 SDK Path" FORCE)
elseif(EXISTS "/opt/v853_sdk")
    set(V853_SDK_PATH "/opt/v853_sdk" CACHE PATH "V853 SDK Path")
else()
    set(V853_SDK_PATH "${CMAKE_SOURCE_DIR}/../../SDK/tina-v853-open" CACHE PATH "V853 SDK Path")
endif()

set(TOOLCHAIN_PATH "${V853_SDK_PATH}/prebuilt/rootfsbuilt/arm/toolchain-sunxi-musl-gcc-830/toolchain")

# 编译器
set(CMAKE_C_COMPILER   "${TOOLCHAIN_PATH}/bin/arm-openwrt-linux-gcc")
set(CMAKE_CXX_COMPILER "${TOOLCHAIN_PATH}/bin/arm-openwrt-linux-g++")

# Sysroot
set(CMAKE_SYSROOT "${V853_SDK_PATH}/buildroot/buildroot-201902/output/target")

# 查找路径
set(CMAKE_FIND_ROOT_PATH ${CMAKE_SYSROOT})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

# 编译选项
set(CMAKE_C_FLAGS   "-march=armv7-a -mfpu=neon -mfloat-abi=hard")
set(CMAKE_CXX_FLAGS "-march=armv7-a -mfpu=neon -mfloat-abi=hard")
