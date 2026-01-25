#!/bin/bash
#
# V853 详细模式重新编译
# 使用单线程和详细输出来定位错误
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}  V853 详细模式重新编译${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# 检查是否在容器内
if [ ! -d "/opt/v853_sdk" ]; then
    echo -e "${RED}错误: 请在 Docker 容器内运行${NC}"
    exit 1
fi

SDK_PATH="/opt/v853_sdk"
KERNEL_PATH="$SDK_PATH/kernel/linux-4.9"

cd "$SDK_PATH"

echo -e "${YELLOW}此脚本将使用单线程和详细输出编译${NC}"
echo -e "${YELLOW}这会很慢，但能看到具体的错误信息${NC}"
echo ""

read -p "继续? (y/N): " confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    exit 0
fi

echo ""
echo -e "${CYAN}选择编译目标:${NC}"
echo "1. 只编译内核 (make -j1 V=s kernel)"
echo "2. 编译整个系统 (make -j1 V=s world)"
echo ""

read -p "选择 (1-2, 默认1): " choice
choice=${choice:-1}

echo ""
echo -e "${GREEN}开始编译（详细输出）...${NC}"
echo ""

case $choice in
    1)
        make -j1 V=s kernel 2>&1 | tee kernel_verbose.log
        ;;
    2)
        make -j1 V=s world 2>&1 | tee world_verbose.log
        ;;
    *)
        echo -e "${RED}无效选择${NC}"
        exit 1
        ;;
esac

BUILD_STATUS=${PIPESTATUS[0]}

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"

if [ $BUILD_STATUS -eq 0 ]; then
    echo -e "${GREEN}✅ 编译成功！${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
else
    echo -e "${RED}❌ 编译失败${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}查看完整日志:${NC}"
    if [ $choice -eq 1 ]; then
        echo "  cat $SDK_PATH/kernel_verbose.log | less"
    else
        echo "  cat $SDK_PATH/world_verbose.log | less"
    fi
    echo ""
    exit 1
fi
