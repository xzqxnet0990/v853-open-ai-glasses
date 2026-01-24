#!/bin/bash
#
# V853 内核编译修复 + 重新编译脚本（macOS版本）
# 在 macOS 主机上运行，自动修复并重新编译
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
KERNEL_CONFIG="$PROJECT_DIR/SDK/tina-v853-open/kernel/linux-4.9/.config"

echo -e "${CYAN}=== V853 内核编译修复脚本 (macOS) ===${NC}"
echo ""

# 检查内核配置文件
if [ ! -f "$KERNEL_CONFIG" ]; then
    echo -e "${RED}错误: 内核配置文件不存在${NC}"
    echo "路径: $KERNEL_CONFIG"
    echo ""
    echo "请先运行一次编译以生成配置文件:"
    echo "  ./start-docker.sh build-firmware"
    exit 1
fi

echo -e "${GREEN}1. 备份内核配置...${NC}"
cp "$KERNEL_CONFIG" "$KERNEL_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
echo "   ✓ 备份完成"

echo ""
echo -e "${GREEN}2. 修复内核配置...${NC}"

# 禁用导致编译失败的模块
if grep -q "CONFIG_NETFILTER_XT_TARGET_TCPMSS" "$KERNEL_CONFIG"; then
    sed -i '' 's/^CONFIG_NETFILTER_XT_TARGET_TCPMSS=.*/# CONFIG_NETFILTER_XT_TARGET_TCPMSS is not set/' "$KERNEL_CONFIG"
    echo "   ✓ 已禁用 CONFIG_NETFILTER_XT_TARGET_TCPMSS"
fi

if grep -q "CONFIG_IP_NF_TARGET_MASQUERADE" "$KERNEL_CONFIG"; then
    sed -i '' 's/^CONFIG_IP_NF_TARGET_MASQUERADE=.*/# CONFIG_IP_NF_TARGET_MASQUERADE is not set/' "$KERNEL_CONFIG"
    echo "   ✓ 已禁用 CONFIG_IP_NF_TARGET_MASQUERADE"
fi

# 添加更多可能有问题的模块
if grep -q "CONFIG_NETFILTER_XT_MATCH_TCPMSS" "$KERNEL_CONFIG"; then
    sed -i '' 's/^CONFIG_NETFILTER_XT_MATCH_TCPMSS=.*/# CONFIG_NETFILTER_XT_MATCH_TCPMSS is not set/' "$KERNEL_CONFIG"
    echo "   ✓ 已禁用 CONFIG_NETFILTER_XT_MATCH_TCPMSS"
fi

echo ""
echo -e "${GREEN}3. 清理内核编译缓存...${NC}"

# 使用 docker-compose 在容器内清理
if command -v docker-compose &> /dev/null; then
    docker-compose exec v853-dev bash -c "cd /opt/v853_sdk/kernel/linux-4.9 && make clean" 2>/dev/null || \
        docker compose exec v853-dev bash -c "cd /opt/v853_sdk/kernel/linux-4.9 && make clean" 2>/dev/null || \
        echo "   ⚠️  无法清理（容器未运行）"
else
    docker compose exec v853-dev bash -c "cd /opt/v853_sdk/kernel/linux-4.9 && make clean" 2>/dev/null || \
        echo "   ⚠️  无法清理（容器未运行）"
fi

echo ""
echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}✅ 修复完成！${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""
echo -e "${CYAN}现在重新编译固件:${NC}"
echo "  ./start-docker.sh build-firmware"
echo ""

# 询问是否立即重新编译
read -p "是否立即重新编译固件? (y/N): " rebuild
if [ "$rebuild" = "y" ] || [ "$rebuild" = "Y" ]; then
    echo ""
    echo -e "${GREEN}开始重新编译...${NC}"
    ./start-docker.sh build-firmware
fi
