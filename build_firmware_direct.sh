#!/bin/bash
#
# V853 固件直接编译脚本（跳过交互）
# 适用于已经配置好环境的情况
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}  V853 固件直接编译（无交互模式）${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# 检查是否在容器内
if [ ! -d "/opt/v853_sdk" ]; then
    echo -e "${RED}错误: 请在 Docker 容器内运行${NC}"
    exit 1
fi

SDK_PATH="/opt/v853_sdk"
KERNEL_PATH="$SDK_PATH/kernel/linux-4.9"

# ============ 步骤 1: 修复内核配置 ============
echo -e "${CYAN}[1/4] 修复内核配置${NC}"
echo ""

cd "$KERNEL_PATH"

# 备份旧配置
if [ -f ".config" ]; then
    cp .config .config.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    rm -f .config
fi

# 清理配置缓存
rm -f include/config/auto.conf 2>/dev/null || true
rm -f include/config/auto.conf.cmd 2>/dev/null || true
rm -f include/generated/autoconf.h 2>/dev/null || true

echo "清理配置缓存..."

# 查找并应用默认配置
DEFCONFIG="sun8iw21p1smp_v853_defconfig"
if [ -f "arch/arm/configs/$DEFCONFIG" ]; then
    echo "应用默认配置: $DEFCONFIG"
    make ARCH=arm CROSS_COMPILE=arm-openwrt-linux- $DEFCONFIG
    echo -e "${GREEN}✓ 内核配置已重新生成${NC}"
else
    echo -e "${RED}错误: 找不到默认配置 $DEFCONFIG${NC}"
    exit 1
fi

# 禁用有问题的模块
if [ -f ".config" ]; then
    sed -i 's/^CONFIG_NETFILTER_XT_TARGET_TCPMSS=.*/# CONFIG_NETFILTER_XT_TARGET_TCPMSS is not set/' .config
    sed -i 's/^CONFIG_IP_NF_TARGET_MASQUERADE=.*/# CONFIG_IP_NF_TARGET_MASQUERADE is not set/' .config
    echo -e "${GREEN}✓ 已禁用问题模块${NC}"
fi

echo ""

# ============ 步骤 2: 检查资源 ============
echo -e "${CYAN}[2/4] 检查系统资源${NC}"
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

# ============ 步骤 3: 清理（可选）============
echo -e "${CYAN}[3/4] 清理选项${NC}"
echo ""

read -p "清理旧的编译产物? (y/N): " do_clean
if [ "$do_clean" = "y" ] || [ "$do_clean" = "Y" ]; then
    cd "$SDK_PATH"
    echo "清理中..."
    make clean 2>/dev/null || true
    echo -e "${GREEN}✓ 清理完成${NC}"
else
    echo "跳过清理（增量编译）"
fi

echo ""

# ============ 步骤 4: 开始编译 ============
echo -e "${CYAN}[4/4] 开始编译固件${NC}"
echo ""
echo -e "${YELLOW}预计时间: 30-60 分钟${NC}"
echo -e "${YELLOW}日志文件: $SDK_PATH/build.log${NC}"
echo ""

cd "$SDK_PATH"

# 直接调用 build.sh
if [ -f "./build.sh" ]; then
    echo "使用 build.sh 编译..."
    ./build.sh 2>&1 | tee build.log
    BUILD_STATUS=${PIPESTATUS[0]}
else
    echo "使用 make 编译..."
    make -j$JOBS 2>&1 | tee build.log
    BUILD_STATUS=${PIPESTATUS[0]}
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"

if [ $BUILD_STATUS -eq 0 ]; then
    echo -e "${GREEN}✅ 编译成功！${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo ""

    # 查找镜像
    echo -e "${CYAN}镜像位置:${NC}"
    find "$SDK_PATH/out" -name "*.img" -o -name "*.fex" 2>/dev/null | head -10

    echo ""
    echo -e "${CYAN}下一步:${NC}"
    echo "  exit"
    echo "  ./start-docker.sh copy-image"
else
    echo -e "${RED}❌ 编译失败${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo ""
    echo "查看日志: tail -100 $SDK_PATH/build.log"
    exit 1
fi
