#!/bin/bash
#
# V853 内核配置修复脚本
# 修复错误的 x86_64 架构配置，重新生成 ARM 配置
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== V853 内核配置修复脚本 ===${NC}"
echo ""

# 检查是否在容器内
if [ ! -d "/opt/v853_sdk" ]; then
    echo -e "${RED}错误: 请在 Docker 容器内运行${NC}"
    exit 1
fi

SDK_PATH="/opt/v853_sdk"
KERNEL_PATH="$SDK_PATH/kernel/linux-4.9"

echo -e "${YELLOW}问题: 内核配置使用了错误的架构 (x86_64 而不是 ARM)${NC}"
echo -e "${CYAN}解决: 删除错误配置，重新生成正确的 ARM 配置${NC}"
echo ""

cd "$SDK_PATH"

# 1. 配置环境
echo -e "${GREEN}[1/5] 加载编译环境${NC}"
source build/envsetup.sh
echo ""

# 2. 选择方案
echo -e "${GREEN}[2/5] 选择编译方案${NC}"
lunch v853-100ask-tina
echo ""

# 3. 清理内核配置
echo -e "${GREEN}[3/5] 清理错误的内核配置${NC}"
cd "$KERNEL_PATH"

if [ -f ".config" ]; then
    echo "   备份旧配置: .config.backup.$(date +%Y%m%d_%H%M%S)"
    cp .config .config.backup.$(date +%Y%m%d_%H%M%S)
    rm -f .config
    echo "   ✓ 已删除错误的 .config"
fi

# 清理自动生成的文件
rm -f include/config/auto.conf
rm -f include/config/auto.conf.cmd
rm -f include/generated/autoconf.h
rm -rf include/config/*
echo "   ✓ 已清理配置缓存"
echo ""

# 4. 重新生成正确的配置
echo -e "${GREEN}[4/5] 重新生成 ARM 架构配置${NC}"

# 查找默认配置文件
DEFCONFIG_PATHS=(
    "$KERNEL_PATH/arch/arm/configs/sun8iw21p1smp_v853_defconfig"
    "$KERNEL_PATH/arch/arm/configs/sun8iw21p1_defconfig"
    "$KERNEL_PATH/arch/arm/configs/sunxi_defconfig"
)

DEFCONFIG_FOUND=""
for defconfig in "${DEFCONFIG_PATHS[@]}"; do
    if [ -f "$defconfig" ]; then
        DEFCONFIG_FOUND="$defconfig"
        echo "   找到默认配置: $(basename $defconfig)"
        break
    fi
done

if [ -z "$DEFCONFIG_FOUND" ]; then
    echo -e "${YELLOW}   警告: 找不到默认配置文件${NC}"
    echo "   将使用 SDK 自动配置"
else
    # 使用找到的默认配置
    DEFCONFIG_NAME=$(basename "$DEFCONFIG_FOUND")
    cd "$KERNEL_PATH"
    make ARCH=arm CROSS_COMPILE=arm-openwrt-linux- "$DEFCONFIG_NAME"
    echo "   ✓ 已应用 $DEFCONFIG_NAME"
fi

echo ""

# 5. 验证配置
echo -e "${GREEN}[5/5] 验证内核配置${NC}"

if [ -f "$KERNEL_PATH/.config" ]; then
    # 检查架构
    ARCH_CHECK=$(grep "^CONFIG_ARM=y" "$KERNEL_PATH/.config" || echo "")
    if [ -n "$ARCH_CHECK" ]; then
        echo -e "${GREEN}   ✓ 架构正确: ARM${NC}"
    else
        echo -e "${RED}   ✗ 架构错误: 未检测到 ARM 配置${NC}"
    fi

    # 检查交叉编译器
    CROSS_CHECK=$(grep "^CONFIG_CROSS_COMPILE=" "$KERNEL_PATH/.config" || echo "")
    echo "   编译器配置: $CROSS_CHECK"
else
    echo -e "${RED}   ✗ 配置文件不存在${NC}"
fi

echo ""
echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}✅ 配置修复完成！${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""
echo -e "${CYAN}下一步:${NC}"
echo "  1. 返回 SDK 根目录: cd /opt/v853_sdk"
echo "  2. 重新编译: ./build.sh"
echo ""
echo -e "${YELLOW}或者使用安全编译脚本:${NC}"
echo "  cd /workspace"
echo "  ./build_firmware_safe.sh"
echo ""
