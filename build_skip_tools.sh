#!/bin/bash
#
# V853 跳过工具链编译
# 直接编译固件，跳过工具准备阶段
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}  V853 固件编译（跳过工具链）${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# 检查是否在容器内
if [ ! -d "/opt/v853_sdk" ]; then
    echo -e "${RED}错误: 请在 Docker 容器内运行${NC}"
    exit 1
fi

SDK_PATH="/opt/v853_sdk"

cd "$SDK_PATH"

echo -e "${CYAN}提示:${NC}"
echo "此脚本跳过 OpenWrt 工具链编译，直接编译系统"
echo ""

# 检查是否已经配置过环境
if [ -z "$TARGET_PRODUCT" ]; then
    echo -e "${YELLOW}环境未配置，正在配置...${NC}"
    source build/envsetup.sh

    # 直接设置环境变量，跳过 lunch 交互
    export TARGET_PRODUCT=v853-100ask
    export TARGET_BOARD_PLATFORM=v853
    echo "TARGET_PRODUCT: $TARGET_PRODUCT"
fi

echo ""
echo -e "${CYAN}编译选项:${NC}"
echo "1. make kernel    - 只编译内核"
echo "2. make buildroot - 只编译 buildroot"
echo "3. make image     - 只打包镜像"
echo "4. ./build.sh     - 完整编译"
echo ""

read -p "选择编译目标 (1-4, 默认4): " choice
choice=${choice:-4}

echo ""

case $choice in
    1)
        echo -e "${CYAN}编译内核...${NC}"
        make kernel -j4
        ;;
    2)
        echo -e "${CYAN}编译 buildroot...${NC}"
        make buildroot -j4
        ;;
    3)
        echo -e "${CYAN}打包镜像...${NC}"
        make image
        ;;
    4)
        echo -e "${CYAN}完整编译（可能会卡在工具编译）...${NC}"
        echo -e "${YELLOW}如果卡住，按 Ctrl+C 然后选择选项 1 或 3${NC}"
        sleep 3
        ./build.sh
        ;;
    *)
        echo -e "${RED}无效选择${NC}"
        exit 1
        ;;
esac

BUILD_STATUS=$?

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"

if [ $BUILD_STATUS -eq 0 ]; then
    echo -e "${GREEN}✅ 编译完成！${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo ""

    echo -e "${CYAN}查找镜像文件:${NC}"
    find "$SDK_PATH/out" \( -name "*.img" -o -name "*.fex" \) 2>/dev/null | head -10

    echo ""
else
    echo -e "${RED}❌ 编译失败${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    exit 1
fi
