# CMake toolchain file for ARM cross-compilation
# Target: RV1109 (ARM Cortex-A7)

set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

# Cross-compiler paths
# Update these paths based on your Docker environment
set(TOOLCHAIN_PREFIX arm-rockchip831-linux-uclibcgnueabihf)
set(TOOLCHAIN_PATH /opt/new/rv1106b_rv1103b_linux_ipc_v1.0.0_20241016/tools/linux/toolchain/arm-rockchip831-linux-uclibcgnueabihf/bin)

# Set compilers
set(CMAKE_C_COMPILER ${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}-gcc)
set(CMAKE_CXX_COMPILER ${TOOLCHAIN_PATH}/${TOOLCHAIN_PREFIX}-g++)

# Set sysroot (optional, if needed)
# set(CMAKE_SYSROOT /path/to/sysroot)

# Search for programs only in host directories
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)

# Search for libraries and headers only in target directories
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

# Qt5 specific settings for cross-compilation
set(QT_QMAKE_EXECUTABLE /path/to/qt5/qmake)  # Update this path

# Compiler flags
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -march=armv7-a -mfpu=neon -mfloat-abi=hard")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=armv7-a -mfpu=neon -mfloat-abi=hard")
