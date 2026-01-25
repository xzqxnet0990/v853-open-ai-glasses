#!/bin/bash
#
# V853 AI Glasses - 一键编译脚本
#
# 用法:
#   ./build_all.sh              # 编译所有组件
#   ./build_all.sh sdk          # 只编译SDK适配层
#   ./build_all.sh app          # 只编译应用层
#   ./build_all.sh clean        # 清理所有编译输出

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 项目根目录（脚本在 scripts/ 子目录中，需要返回上一级）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
echo -e "${GREEN}=== V853 AI Glasses Build Script ===${NC}"
echo "Project root: $PROJECT_ROOT"
echo ""

# 检查V853 SDK是否存在
# 支持两种路径: SDK/tina-v853-open 或 tina-v853-open (向后兼容)
V853_SDK_PATH=""
if [ -d "$PROJECT_ROOT/SDK/tina-v853-open" ]; then
    V853_SDK_PATH="$PROJECT_ROOT/SDK/tina-v853-open"
    echo "Found V853 SDK: SDK/tina-v853-open"
elif [ -d "$PROJECT_ROOT/tina-v853-open" ]; then
    V853_SDK_PATH="$PROJECT_ROOT/tina-v853-open"
    echo "Found V853 SDK: tina-v853-open"
else
    echo -e "${RED}错误: 未找到V853 SDK${NC}"
    echo "请确保SDK位于以下位置之一:"
    echo "  - SDK/tina-v853-open/"
    echo "  - tina-v853-open/"
    exit 1
fi

# 清理函数
clean_all() {
    echo -e "${YELLOW}清理所有编译输出...${NC}"

    rm -rf src/sdk_adapter/build
    rm -rf src/display_lvgl/build-v853
    rm -rf src/ffm_launcher/build-v853
    rm -rf src/touchpad_manager/build-v853

    echo -e "${GREEN}清理完成${NC}"
}

# 编译SDK适配层
build_sdk() {
    echo -e "${GREEN}[1/4] 编译 SDK 适配层...${NC}"

    # 设置 OpenWrt 工具链必需的环境变量
    if [ -z "$STAGING_DIR" ]; then
        if [ -n "$TOOLCHAIN_PATH" ]; then
            export STAGING_DIR="$TOOLCHAIN_PATH"
            echo "设置 STAGING_DIR=$STAGING_DIR"
        elif [ -n "$V853_SDK_PATH" ]; then
            export STAGING_DIR="$V853_SDK_PATH/prebuilt/rootfsbuilt/arm/toolchain-sunxi-musl-gcc-830/toolchain"
            echo "设置 STAGING_DIR=$STAGING_DIR"
        fi
    fi

    cd "$PROJECT_ROOT/src/sdk_adapter"
    rm -rf build  # 清理旧的 CMake 缓存
    mkdir -p build && cd build

    cmake .. \
        -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake \
        -DCMAKE_BUILD_TYPE=Release

    make -j$(nproc)

    echo -e "${GREEN}SDK适配层编译完成${NC}"
    echo "  输出:"
    ls -lh libai_glass_sdk_v853.* 2>/dev/null || echo "  (库文件生成中...)"
    echo ""
}

# 编译LVGL显示应用
build_display_lvgl() {
    echo -e "${GREEN}[2/4] 编译 LVGL 显示应用...${NC}"

    cd "$PROJECT_ROOT/src/display_lvgl"
    rm -rf build-v853  # 清理旧的 CMake 缓存
    mkdir -p build-v853 && cd build-v853

    cmake .. \
        -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake \
        -DCMAKE_BUILD_TYPE=Release

    make -j$(nproc)

    echo -e "${GREEN}LVGL显示应用编译完成${NC}"
    echo "  输出: AIGlassesDisplayLVGL"
    ls -lh AIGlassesDisplayLVGL 2>/dev/null || echo "  (编译失败或未生成)"
    echo ""
}

# Qt显示应用已移除，使用LVGL代替
# 保留此注释以记录历史

# 编译FFmpeg启动器
build_ffm_launcher() {
    echo -e "${GREEN}[3/4] 编译 FFmpeg 启动器...${NC}"

    cd "$PROJECT_ROOT/src/ffm_launcher"
    rm -rf build-v853  # 清理旧的CMake缓存
    mkdir -p build-v853 && cd build-v853

    cmake .. \
        -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake \
        -DCMAKE_BUILD_TYPE=Release

    make -j$(nproc)

    echo -e "${GREEN}FFmpeg启动器编译完成${NC}"
    echo "  输出: FFlaunch"
    ls -lh FFlaunch 2>/dev/null || echo "  (编译失败或未生成)"
    echo ""
}

# 编译GPIO管理器
build_touchpad() {
    echo -e "${GREEN}[4/4] 编译 GPIO 管理器...${NC}"

    cd "$PROJECT_ROOT/src/touchpad_manager"
    rm -rf build-v853  # 清理旧的CMake缓存
    mkdir -p build-v853 && cd build-v853

    cmake .. \
        -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake \
        -DCMAKE_BUILD_TYPE=Release

    make -j$(nproc)

    echo -e "${GREEN}GPIO管理器编译完成${NC}"
    echo "  输出: touchpad_manager"
    ls -lh touchpad_manager 2>/dev/null || echo "  (编译失败或未生成)"
    echo ""
}

# 显示编译结果
show_results() {
    echo ""
    echo -e "${GREEN}==================================${NC}"
    echo -e "${GREEN}编译完成！编译产物位置:${NC}"
    echo -e "${GREEN}==================================${NC}"
    echo ""
    echo "SDK适配层:"
    echo "  src/sdk_adapter/build/libai_glass_sdk_v853.a"
    echo "  src/sdk_adapter/build/libai_glass_sdk_v853.so"
    echo ""
    echo "应用程序:"
    echo "  src/display_lvgl/build-v853/AIGlassesDisplayLVGL"
    echo "  src/ffm_launcher/build-v853/FFlaunch"
    echo "  src/touchpad_manager/build-v853/touchpad_manager"
    echo ""
    echo "测试程序:"
    echo "  src/sdk_adapter/build/examples/camera_test"
    echo "  src/sdk_adapter/build/examples/audio_test"
    echo ""
    echo -e "${YELLOW}注意: 需要将这些文件部署到V853设备上运行${NC}"
    echo ""
}

# 主逻辑
case "$1" in
    clean)
        clean_all
        ;;
    sdk)
        build_sdk
        ;;
    app)
        build_display_lvgl
        build_ffm_launcher
        build_touchpad
        ;;
    *)
        echo "编译所有组件..."
        echo ""
        build_sdk
        build_display_lvgl
        build_ffm_launcher
        build_touchpad
        show_results
        ;;
esac

echo -e "${GREEN}Done!${NC}"
