#!/bin/bash
#
# 从 Docker 容器复制编译产物到 output/ 目录
#
# 用法:
#   ./copy_from_docker.sh           # 复制所有文件
#   ./copy_from_docker.sh --app     # 只复制应用程序
#   ./copy_from_docker.sh --sdk     # 只复制 SDK 库

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/output"

# Docker 容器名称
CONTAINER_NAME="v853_ai_glasses_dev"

echo -e "${CYAN}=== 从 Docker 容器复制编译产物 ===${NC}"
echo ""

# 检查容器是否运行
echo -e "${GREEN}[1/3] 检查 Docker 容器...${NC}"
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${RED}错误: 容器未运行${NC}"
    echo "请先启动容器: ./start-docker.sh start"
    exit 1
fi
echo -e "${GREEN}✓ 容器正在运行${NC}"
echo ""

# 创建 output 目录
echo -e "${GREEN}[2/3] 准备输出目录...${NC}"
mkdir -p "$OUTPUT_DIR"
echo -e "${GREEN}✓ 目录已创建: $OUTPUT_DIR${NC}"
echo ""

# 复制文件
echo -e "${GREEN}[3/3] 复制编译产物...${NC}"

COPY_SDK=true
COPY_APP=true

# 解析参数
if [ "$1" = "--app" ]; then
    COPY_SDK=false
    echo -e "${YELLOW}只复制应用程序${NC}"
elif [ "$1" = "--sdk" ]; then
    COPY_APP=false
    echo -e "${YELLOW}只复制 SDK 库${NC}"
fi

COPIED_COUNT=0

# 复制 SDK 库
if [ "$COPY_SDK" = true ]; then
    echo -e "${CYAN}→ 复制 SDK 适配层...${NC}"
    if docker cp "$CONTAINER_NAME:/workspace/src/sdk_adapter/build/libai_glass_sdk_v853.so" "$OUTPUT_DIR/" 2>/dev/null; then
        echo -e "${GREEN}  ✓ libai_glass_sdk_v853.so${NC}"
        ((COPIED_COUNT++))
    else
        echo -e "${YELLOW}  ⊘ libai_glass_sdk_v853.so 不存在，可能未编译${NC}"
    fi

    if docker cp "$CONTAINER_NAME:/workspace/src/sdk_adapter/build/libai_glass_sdk_v853.a" "$OUTPUT_DIR/" 2>/dev/null; then
        echo -e "${GREEN}  ✓ libai_glass_sdk_v853.a${NC}"
        ((COPIED_COUNT++))
    fi
fi

# 复制应用程序
if [ "$COPY_APP" = true ]; then
    echo -e "${CYAN}→ 复制 LVGL 显示应用...${NC}"
    if docker cp "$CONTAINER_NAME:/workspace/src/display_lvgl/build-v853/AIGlassesDisplayLVGL" "$OUTPUT_DIR/" 2>/dev/null; then
        echo -e "${GREEN}  ✓ AIGlassesDisplayLVGL${NC}"
        ((COPIED_COUNT++))
    else
        echo -e "${YELLOW}  ⊘ AIGlassesDisplayLVGL 不存在，可能未编译${NC}"
    fi

    echo -e "${CYAN}→ 复制 FFmpeg 启动器...${NC}"
    if docker cp "$CONTAINER_NAME:/workspace/src/ffm_launcher/build-v853/FFlaunch" "$OUTPUT_DIR/" 2>/dev/null; then
        echo -e "${GREEN}  ✓ FFlaunch${NC}"
        ((COPIED_COUNT++))
    else
        echo -e "${YELLOW}  ⊘ FFlaunch 不存在，可能未编译${NC}"
    fi

    echo -e "${CYAN}→ 复制 GPIO 管理器...${NC}"
    if docker cp "$CONTAINER_NAME:/workspace/src/touchpad_manager/build-v853/touchpad_manager" "$OUTPUT_DIR/" 2>/dev/null; then
        echo -e "${GREEN}  ✓ touchpad_manager${NC}"
        ((COPIED_COUNT++))
    else
        echo -e "${YELLOW}  ⊘ touchpad_manager 不存在，可能未编译${NC}"
    fi

    # 复制示例程序（可选）
    echo -e "${CYAN}→ 复制测试程序...${NC}"
    if docker cp "$CONTAINER_NAME:/workspace/src/sdk_adapter/build/examples/camera_test" "$OUTPUT_DIR/" 2>/dev/null; then
        echo -e "${GREEN}  ✓ camera_test${NC}"
        ((COPIED_COUNT++))
    fi

    if docker cp "$CONTAINER_NAME:/workspace/src/sdk_adapter/build/examples/audio_test" "$OUTPUT_DIR/" 2>/dev/null; then
        echo -e "${GREEN}  ✓ audio_test${NC}"
        ((COPIED_COUNT++))
    fi
fi

echo ""

# 显示结果
if [ $COPIED_COUNT -eq 0 ]; then
    echo -e "${YELLOW}警告: 没有复制任何文件${NC}"
    echo "请先编译项目: ./start-docker.sh build-all"
    exit 1
fi

echo -e "${GREEN}✅ 成功复制 $COPIED_COUNT 个文件到 output/${NC}"
echo ""
echo -e "${CYAN}=== 文件列表 ===${NC}"
ls -lh "$OUTPUT_DIR"
echo ""
echo -e "${CYAN}=== 下一步 ===${NC}"
echo "使用以下命令部署到设备:"
echo "  ./scripts/deploy_adb_udisk.sh      # ADB 部署到 UDISK"
echo "  ./scripts/deploy.sh 192.168.x.x    # SSH 部署（如果 SSH 可用）"
echo ""
