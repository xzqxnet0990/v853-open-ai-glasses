#!/bin/bash
#
# V853 一键修复并编译固件
# 整合所有修复步骤 + 安全编译
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  V853 AI Glasses 固件一键修复+编译    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# 检查是否在容器内
if [ ! -d "/opt/v853_sdk" ]; then
    echo -e "${RED}错误: 请在 Docker 容器内运行${NC}"
    echo ""
    echo "使用方法:"
    echo "  ./start-docker.sh shell"
    echo "  cd /workspace"
    echo "  ./fix_and_build_firmware.sh"
    exit 1
fi

SDK_PATH="/opt/v853_sdk"
KERNEL_PATH="$SDK_PATH/kernel/linux-4.9"

# ==================== 阶段 1: 环境检查 ====================
echo -e "${CYAN}▶ 阶段 1/6: 环境检查${NC}"
echo ""

# 检查磁盘空间
DISK_AVAIL=$(df -BG /opt/v853_sdk | tail -1 | awk '{print $4}' | sed 's/G//')
echo "磁盘可用空间: ${DISK_AVAIL}GB"
if [ "$DISK_AVAIL" -lt 10 ]; then
    echo -e "${RED}⚠️  警告: 磁盘空间不足 10GB，可能导致编译失败${NC}"
    read -p "是否继续? (y/N): " continue_build
    if [ "$continue_build" != "y" ]; then
        exit 1
    fi
fi

# 检查内存
TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
echo "可用内存: ${TOTAL_MEM}MB"

# 根据内存调整并发数
if [ $TOTAL_MEM -lt 4096 ]; then
    JOBS=2
    echo -e "${YELLOW}内存较低，使用 2 线程编译${NC}"
elif [ $TOTAL_MEM -lt 8192 ]; then
    JOBS=4
    echo "使用 4 线程编译"
else
    JOBS=8
    echo "使用 8 线程编译"
fi

echo ""

# ==================== 阶段 2: 配置环境 ====================
echo -e "${CYAN}▶ 阶段 2/6: 配置编译环境${NC}"
echo ""

cd "$SDK_PATH"
source build/envsetup.sh

# lunch 可能需要交互式选择，使用 expect 或直接设置环境变量
# 方案1: 直接通过 echo 提供输入
echo "1" | lunch v853-100ask-tina 2>/dev/null || lunch v853-100ask-tina

# 验证是否成功
if [ -z "$TARGET_PRODUCT" ]; then
    echo -e "${YELLOW}⚠️  lunch 未完全配置，手动设置环境变量${NC}"
    export TARGET_PRODUCT=v853-100ask
    export TARGET_BOARD_PLATFORM=v853
fi

echo -e "${GREEN}✓ 编译环境已配置${NC}"
echo "   TARGET_PRODUCT: $TARGET_PRODUCT"
echo ""

# ==================== 阶段 3: 修复内核配置 ====================
echo -e "${CYAN}▶ 阶段 3/6: 修复内核配置${NC}"
echo ""

cd "$KERNEL_PATH"

# 备份并清理错误的配置
if [ -f ".config" ]; then
    echo "备份旧配置..."
    cp .config .config.backup.$(date +%Y%m%d_%H%M%S)
    rm -f .config
    echo "✓ 已删除错误的 x86_64 配置"
fi

# 清理配置缓存
rm -f include/config/auto.conf
rm -f include/config/auto.conf.cmd
rm -f include/generated/autoconf.h
rm -rf include/config/* 2>/dev/null || true

echo "✓ 已清理配置缓存"

# 重新生成 ARM 配置
echo ""
echo "重新生成 ARM 架构配置..."

DEFCONFIG_PATHS=(
    "arch/arm/configs/sun8iw21p1smp_v853_defconfig"
    "arch/arm/configs/sun8iw21p1_defconfig"
    "arch/arm/configs/sunxi_defconfig"
)

DEFCONFIG_FOUND=""
for defconfig in "${DEFCONFIG_PATHS[@]}"; do
    if [ -f "$defconfig" ]; then
        DEFCONFIG_FOUND="$defconfig"
        DEFCONFIG_NAME=$(basename "$defconfig")
        echo "找到默认配置: $DEFCONFIG_NAME"
        make ARCH=arm CROSS_COMPILE=arm-openwrt-linux- "$DEFCONFIG_NAME" > /dev/null 2>&1
        echo "✓ 已应用 $DEFCONFIG_NAME"
        break
    fi
done

if [ -z "$DEFCONFIG_FOUND" ]; then
    echo -e "${YELLOW}使用内核默认配置${NC}"
    make ARCH=arm CROSS_COMPILE=arm-openwrt-linux- defconfig > /dev/null 2>&1
fi

# 验证配置
if grep -q "^CONFIG_ARM=y" .config; then
    echo -e "${GREEN}✓ 架构验证: ARM${NC}"
else
    echo -e "${RED}✗ 配置错误: 未检测到 ARM 架构${NC}"
    exit 1
fi

echo ""

# ==================== 阶段 4: 修复 netfilter 模块 ====================
echo -e "${CYAN}▶ 阶段 4/6: 修复 netfilter 模块${NC}"
echo ""

# 禁用可能导致问题的模块
sed -i 's/^CONFIG_NETFILTER_XT_TARGET_TCPMSS=.*/# CONFIG_NETFILTER_XT_TARGET_TCPMSS is not set/' .config 2>/dev/null || true
sed -i 's/^CONFIG_IP_NF_TARGET_MASQUERADE=.*/# CONFIG_IP_NF_TARGET_MASQUERADE is not set/' .config 2>/dev/null || true
sed -i 's/^CONFIG_NETFILTER_XT_MATCH_TCPMSS=.*/# CONFIG_NETFILTER_XT_MATCH_TCPMSS is not set/' .config 2>/dev/null || true

echo "✓ 已禁用有问题的 netfilter 模块"
echo ""

# ==================== 阶段 5: 清理并准备编译 ====================
echo -e "${CYAN}▶ 阶段 5/6: 清理旧的编译产物${NC}"
echo ""

cd "$SDK_PATH"

read -p "是否清理所有旧的编译产物? (推荐: y, 跳过: N): " do_clean
if [ "$do_clean" = "y" ] || [ "$do_clean" = "Y" ]; then
    echo "清理中，请稍候..."
    make clean > /dev/null 2>&1 || true
    echo -e "${GREEN}✓ 清理完成${NC}"
else
    echo "跳过清理（增量编译）"
fi

echo ""

# ==================== 阶段 6: 开始编译 ====================
echo -e "${CYAN}▶ 阶段 6/6: 编译固件${NC}"
echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${YELLOW}⏱  预计时间: 30-60 分钟${NC}"
echo -e "${YELLOW}📝 日志保存: $SDK_PATH/build_complete.log${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

sleep 2

# 使用低并发编译，并保存日志
make -j$JOBS 2>&1 | tee "$SDK_PATH/build_complete.log"

BUILD_STATUS=${PIPESTATUS[0]}

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"

if [ $BUILD_STATUS -eq 0 ]; then
    echo -e "${GREEN}✅ 编译成功！${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo ""

    # 查找镜像文件
    echo -e "${CYAN}📦 固件镜像位置:${NC}"
    echo ""

    IMAGE_DIRS=(
        "$SDK_PATH/out/v853/100ask/image"
        "$SDK_PATH/out/v853/vision/image"
        "$SDK_PATH/out/v853/image"
    )

    FOUND_IMAGES=false
    for img_dir in "${IMAGE_DIRS[@]}"; do
        if [ -d "$img_dir" ]; then
            echo -e "${GREEN}找到镜像目录: $img_dir${NC}"
            if ls "$img_dir"/*.img "$img_dir"/*.fex 2>/dev/null; then
                FOUND_IMAGES=true
                echo ""
            fi
        fi
    done

    if [ "$FOUND_IMAGES" = false ]; then
        echo -e "${YELLOW}⚠️  未找到镜像文件，可能编译不完整${NC}"
    fi

    echo ""
    echo -e "${CYAN}📋 下一步操作:${NC}"
    echo "  1. 退出容器: exit"
    echo "  2. 复制镜像: ./start-docker.sh copy-image"
    echo "  3. 烧录固件: 使用 PhoenixSuit 或 LiveSuit"
    echo ""
else
    echo -e "${RED}❌ 编译失败 (错误码: $BUILD_STATUS)${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}📝 调试信息:${NC}"
    echo "  完整日志: $SDK_PATH/build_complete.log"
    echo "  最后 50 行错误:"
    echo ""
    tail -n 50 "$SDK_PATH/build_complete.log" | grep -E "(error|Error|ERROR|failed|Failed)" || tail -n 50 "$SDK_PATH/build_complete.log"
    echo ""
    exit 1
fi
