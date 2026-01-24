#!/bin/bash
# 从SDK适配层复制库文件到应用层SDK
# 用法: ./link_from_adapter.sh

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 路径定义
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_LIB_DIR="$SCRIPT_DIR"
ADAPTER_BUILD_DIR="$SCRIPT_DIR/../../../src/sdk_adapter/build"

echo -e "${BLUE}=== SDK库文件链接脚本 ===${NC}"
echo ""

# 检查适配层构建目录
if [ ! -d "$ADAPTER_BUILD_DIR" ]; then
    echo -e "${RED}❌ 错误: SDK适配层构建目录不存在${NC}"
    echo "路径: $ADAPTER_BUILD_DIR"
    echo ""
    echo -e "${YELLOW}请先编译SDK适配层:${NC}"
    echo "  cd src/sdk_adapter"
    echo "  mkdir build && cd build"
    echo "  cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake"
    echo "  make"
    exit 1
fi

echo -e "${GREEN}✓ 找到SDK适配层构建目录${NC}"
echo "  $ADAPTER_BUILD_DIR"
echo ""

# 检查库文件
STATIC_LIB="$ADAPTER_BUILD_DIR/libai_glass_sdk_v853.a"
SHARED_LIB="$ADAPTER_BUILD_DIR/libai_glass_sdk_v853.so"

if [ ! -f "$STATIC_LIB" ] || [ ! -f "$SHARED_LIB" ]; then
    echo -e "${RED}❌ 错误: 未找到编译好的库文件${NC}"
    echo ""
    echo "预期文件:"
    echo "  $STATIC_LIB"
    echo "  $SHARED_LIB"
    echo ""
    echo -e "${YELLOW}请先编译SDK适配层:${NC}"
    echo "  cd src/sdk_adapter/build"
    echo "  make"
    exit 1
fi

echo -e "${GREEN}✓ 找到库文件${NC}"
ls -lh "$STATIC_LIB"
ls -lh "$SHARED_LIB"
echo ""

# 复制静态库
echo -e "${BLUE}复制静态库...${NC}"
cp -v "$STATIC_LIB" "$SDK_LIB_DIR/libai_glass_sdk.a"

# 复制动态库
echo -e "${BLUE}复制动态库...${NC}"
cp -v "$SHARED_LIB" "$SDK_LIB_DIR/libai_glass_sdk.so"

echo ""
echo -e "${GREEN}✅ 库文件复制完成！${NC}"
echo ""
echo -e "${CYAN}SDK库目录内容:${NC}"
ls -lh "$SDK_LIB_DIR"
echo ""

# 验证库文件
echo -e "${CYAN}验证库文件:${NC}"
file "$SDK_LIB_DIR/libai_glass_sdk.a"
file "$SDK_LIB_DIR/libai_glass_sdk.so"
echo ""

echo -e "${GREEN}✓ SDK库文件已准备就绪${NC}"
echo ""
echo -e "${YELLOW}下一步:${NC}"
echo "  • 编译示例程序: make examples"
echo "  • 编译应用程序: 在应用的CMakeLists.txt中链接SDK库"
echo "  • 部署到设备: ./deploy.sh <device_ip>"
echo ""
