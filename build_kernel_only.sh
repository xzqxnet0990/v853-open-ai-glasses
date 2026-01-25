#!/bin/bash
#
# V853 只编译内核（快速方案）
# 跳过完整固件编译，只生成内核镜像
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}  V853 内核快速编译${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# 检查是否在容器内
if [ ! -d "/opt/v853_sdk" ]; then
    echo -e "${RED}错误: 请在 Docker 容器内运行${NC}"
    exit 1
fi

SDK_PATH="/opt/v853_sdk"
KERNEL_PATH="$SDK_PATH/kernel/linux-4.9"

# ============ 步骤 1: 查找并应用内核配置 ============
echo -e "${CYAN}[1/3] 配置内核${NC}"
echo ""

cd "$KERNEL_PATH"

# 查找配置文件
DEFCONFIG=""
for pattern in "v853" "sun8iw21" "100ask" "sunxi"; do
    FOUND=$(find arch/arm/configs -name "*${pattern}*defconfig" 2>/dev/null | head -1)
    if [ -n "$FOUND" ]; then
        DEFCONFIG=$(basename "$FOUND")
        echo "找到配置: $DEFCONFIG"
        break
    fi
done

if [ -z "$DEFCONFIG" ]; then
    # 使用现有配置或默认配置
    if [ -f ".config" ]; then
        echo -e "${YELLOW}使用现有 .config${NC}"
    else
        DEFCONFIG=$(ls arch/arm/configs/*defconfig 2>/dev/null | head -1 | xargs basename)
        echo "使用默认配置: $DEFCONFIG"
    fi
fi

# 清理并重新配置
if [ -n "$DEFCONFIG" ]; then
    rm -f .config 2>/dev/null || true
    rm -rf include/config/* 2>/dev/null || true

    make ARCH=arm CROSS_COMPILE=arm-openwrt-linux- $DEFCONFIG
    echo -e "${GREEN}✓ 配置已应用${NC}"
fi

# 禁用问题模块
if [ -f ".config" ]; then
    sed -i 's/^CONFIG_NETFILTER_XT_TARGET_TCPMSS=.*/# CONFIG_NETFILTER_XT_TARGET_TCPMSS is not set/' .config 2>/dev/null || true
    sed -i 's/^CONFIG_IP_NF_TARGET_MASQUERADE=.*/# CONFIG_IP_NF_TARGET_MASQUERADE is not set/' .config 2>/dev/null || true
    echo -e "${GREEN}✓ 已禁用问题模块${NC}"
fi

echo ""

# ============ 步骤 2: 检查资源 ============
echo -e "${CYAN}[2/3] 检查资源${NC}"
echo ""

TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
echo "内存: ${TOTAL_MEM}MB"

if [ $TOTAL_MEM -lt 4096 ]; then
    JOBS=2
elif [ $TOTAL_MEM -lt 8192 ]; then
    JOBS=4
else
    JOBS=8
fi

echo "编译线程: $JOBS"
echo ""

# ============ 步骤 3: 编译内核 ============
echo -e "${CYAN}[3/3] 编译内核${NC}"
echo ""
echo -e "${YELLOW}预计时间: 10-20 分钟${NC}"
echo ""

cd "$KERNEL_PATH"

# 清理旧的编译产物
read -p "清理旧的内核编译产物? (y/N): " do_clean
if [ "$do_clean" = "y" ] || [ "$do_clean" = "Y" ]; then
    make clean
    echo -e "${GREEN}✓ 清理完成${NC}"
fi

echo ""
echo "开始编译内核..."
echo ""

# 编译内核
make ARCH=arm CROSS_COMPILE=arm-openwrt-linux- -j$JOBS zImage modules dtbs 2>&1 | tee kernel_build.log

BUILD_STATUS=${PIPESTATUS[0]}

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"

if [ $BUILD_STATUS -eq 0 ]; then
    echo -e "${GREEN}✅ 内核编译成功！${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo ""

    echo -e "${CYAN}📦 编译产物:${NC}"
    if [ -f "arch/arm/boot/zImage" ]; then
        ls -lh arch/arm/boot/zImage
        echo -e "${GREEN}✓ zImage 已生成${NC}"
    fi

    if [ -f "arch/arm/boot/dts/board.dtb" ]; then
        ls -lh arch/arm/boot/dts/board.dtb
        echo -e "${GREEN}✓ DTB 已生成${NC}"
    fi

    if [ -d "output/lib/modules" ]; then
        echo -e "${GREEN}✓ 内核模块已生成${NC}"
    fi

    echo ""
    echo -e "${CYAN}📋 内核镜像位置:${NC}"
    echo "  $KERNEL_PATH/arch/arm/boot/zImage"
    echo "  $KERNEL_PATH/arch/arm/boot/dts/board.dtb"
    echo ""
else
    echo -e "${RED}❌ 内核编译失败${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo ""
    echo "查看日志: tail -100 $KERNEL_PATH/kernel_build.log"
    echo ""
    exit 1
fi
