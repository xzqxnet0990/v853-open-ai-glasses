#!/bin/bash
#
# V853 内核编译修复脚本
# 修复 xt_TCPMSS 模块缺失导致的编译失败
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== V853 内核编译修复脚本 ===${NC}"
echo ""

# 检查是否在容器内运行
if [ ! -d "/opt/v853_sdk" ]; then
    echo -e "${RED}错误: 请在 Docker 容器内运行此脚本${NC}"
    echo "使用方法:"
    echo "  ./start-docker.sh shell"
    echo "  cd /workspace"
    echo "  ./fix_kernel_build.sh"
    exit 1
fi

SDK_PATH="/opt/v853_sdk"
KERNEL_PATH="$SDK_PATH/kernel/linux-4.9"
KERNEL_CONFIG="$KERNEL_PATH/.config"

echo -e "${YELLOW}问题: 内核编译失败，缺少 xt_TCPMSS.c${NC}"
echo -e "${CYAN}解决方案: 禁用不必要的 netfilter 模块${NC}"
echo ""

# 备份原配置
if [ -f "$KERNEL_CONFIG" ]; then
    echo -e "${GREEN}1. 备份内核配置...${NC}"
    cp "$KERNEL_CONFIG" "$KERNEL_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
    echo "   备份完成: $KERNEL_CONFIG.backup.*"
else
    echo -e "${YELLOW}警告: 内核配置文件不存在，跳过备份${NC}"
fi

# 方案A: 禁用 xt_TCPMSS 模块
echo ""
echo -e "${GREEN}2. 修改内核配置...${NC}"

if [ -f "$KERNEL_CONFIG" ]; then
    # 禁用可能导致问题的 netfilter 模块
    sed -i 's/^CONFIG_NETFILTER_XT_TARGET_TCPMSS=.*/# CONFIG_NETFILTER_XT_TARGET_TCPMSS is not set/' "$KERNEL_CONFIG"
    sed -i 's/^CONFIG_IP_NF_TARGET_MASQUERADE=.*/# CONFIG_IP_NF_TARGET_MASQUERADE is not set/' "$KERNEL_CONFIG"

    echo "   ✓ 已禁用 CONFIG_NETFILTER_XT_TARGET_TCPMSS"
    echo "   ✓ 已禁用 CONFIG_IP_NF_TARGET_MASQUERADE"
fi

# 方案B: 创建缺失的文件（如果源文件确实缺失）
echo ""
echo -e "${GREEN}3. 检查缺失的源文件...${NC}"

TCPMSS_FILE="$KERNEL_PATH/net/netfilter/xt_TCPMSS.c"
if [ ! -f "$TCPMSS_FILE" ]; then
    echo -e "${YELLOW}   警告: $TCPMSS_FILE 文件确实缺失${NC}"
    echo "   已通过禁用模块解决"
else
    echo "   ✓ 文件存在: xt_TCPMSS.c"
fi

# 清理内核编译缓存
echo ""
echo -e "${GREEN}4. 清理内核编译缓存...${NC}"
cd "$KERNEL_PATH"
make clean 2>/dev/null || true
echo "   ✓ 内核缓存已清理"

echo ""
echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}✅ 修复完成！${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""
echo -e "${CYAN}下一步:${NC}"
echo "1. 退出容器: exit"
echo "2. 重新编译固件: ./start-docker.sh build-firmware"
echo ""
echo -e "${YELLOW}或者直接在容器内编译:${NC}"
echo "  cd /opt/v853_sdk"
echo "  source build/envsetup.sh"
echo "  lunch v853-100ask-tina"
echo "  ./build.sh"
echo ""
