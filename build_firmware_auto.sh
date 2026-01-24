#!/bin/bash
#
# V853 固件自动编译脚本
# 自动查找配置文件并编译
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}  V853 固件自动编译脚本${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# 检查是否在容器内
if [ ! -d "/opt/v853_sdk" ]; then
    echo -e "${RED}错误: 请在 Docker 容器内运行${NC}"
    exit 1
fi

SDK_PATH="/opt/v853_sdk"
KERNEL_PATH="$SDK_PATH/kernel/linux-4.9"

# ============ 步骤 1: 查找内核配置 ============
echo -e "${CYAN}[1/5] 查找内核配置文件${NC}"
echo ""

cd "$KERNEL_PATH"

# 列出所有可能的配置文件
echo "搜索配置文件..."
DEFCONFIGS=$(find arch/arm/configs -name "*defconfig" 2>/dev/null | sort)

if [ -z "$DEFCONFIGS" ]; then
    echo -e "${RED}错误: 找不到任何内核配置文件${NC}"
    exit 1
fi

echo -e "${GREEN}找到以下配置文件:${NC}"
echo "$DEFCONFIGS" | nl

# 自动选择最匹配的配置
SELECTED_CONFIG=""
for pattern in "v853" "sun8iw21" "sunxi" "100ask"; do
    MATCH=$(echo "$DEFCONFIGS" | grep -i "$pattern" | head -1 || true)
    if [ -n "$MATCH" ]; then
        SELECTED_CONFIG="$MATCH"
        echo ""
        echo -e "${GREEN}自动选择: $(basename $SELECTED_CONFIG)${NC}"
        break
    fi
done

# 如果没找到匹配，使用第一个
if [ -z "$SELECTED_CONFIG" ]; then
    SELECTED_CONFIG=$(echo "$DEFCONFIGS" | head -1)
    echo ""
    echo -e "${YELLOW}使用第一个配置: $(basename $SELECTED_CONFIG)${NC}"
fi

DEFCONFIG_NAME=$(basename "$SELECTED_CONFIG")

echo ""

# ============ 步骤 2: 修复内核配置 ============
echo -e "${CYAN}[2/5] 修复内核配置${NC}"
echo ""

# 备份旧配置
if [ -f ".config" ]; then
    cp .config .config.backup.$(date +%Y%m%d_%H%M%S) 2>/dev/null || true
    echo "备份旧配置"
fi

# 清理配置缓存
echo "清理配置缓存..."
rm -f .config
rm -f include/config/auto.conf 2>/dev/null || true
rm -f include/config/auto.conf.cmd 2>/dev/null || true
rm -f include/generated/autoconf.h 2>/dev/null || true
rm -rf include/config/* 2>/dev/null || true

# 应用配置
echo "应用配置: $DEFCONFIG_NAME"
make ARCH=arm CROSS_COMPILE=arm-openwrt-linux- $DEFCONFIG_NAME

if [ ! -f ".config" ]; then
    echo -e "${RED}错误: 配置生成失败${NC}"
    exit 1
fi

# 验证架构
if grep -q "CONFIG_ARM=y" .config; then
    echo -e "${GREEN}✓ 架构验证: ARM${NC}"
else
    echo -e "${RED}✗ 配置错误: 不是 ARM 架构${NC}"
    exit 1
fi

# 禁用有问题的模块
echo "禁用问题模块..."
sed -i 's/^CONFIG_NETFILTER_XT_TARGET_TCPMSS=.*/# CONFIG_NETFILTER_XT_TARGET_TCPMSS is not set/' .config 2>/dev/null || true
sed -i 's/^CONFIG_IP_NF_TARGET_MASQUERADE=.*/# CONFIG_IP_NF_TARGET_MASQUERADE is not set/' .config 2>/dev/null || true
sed -i 's/^CONFIG_NETFILTER_XT_MATCH_TCPMSS=.*/# CONFIG_NETFILTER_XT_MATCH_TCPMSS is not set/' .config 2>/dev/null || true

echo -e "${GREEN}✓ 内核配置完成${NC}"
echo ""

# ============ 步骤 3: 检查资源 ============
echo -e "${CYAN}[3/5] 检查系统资源${NC}"
echo ""

TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
DISK_AVAIL=$(df -BG /opt/v853_sdk | tail -1 | awk '{print $4}' | sed 's/G//')

echo "内存: ${TOTAL_MEM}MB"
echo "磁盘可用: ${DISK_AVAIL}GB"

if [ $TOTAL_MEM -lt 4096 ]; then
    JOBS=2
elif [ $TOTAL_MEM -lt 8192 ]; then
    JOBS=4
else
    JOBS=8
fi

echo "编译线程: $JOBS"
echo ""

# ============ 步骤 4: 清理（可选）============
echo -e "${CYAN}[4/5] 清理选项${NC}"
echo ""

read -p "清理旧的编译产物? (推荐首次编译: y, 增量编译: N): " do_clean
if [ "$do_clean" = "y" ] || [ "$do_clean" = "Y" ]; then
    cd "$SDK_PATH"
    echo "清理中，请稍候..."
    make clean 2>/dev/null || true
    echo -e "${GREEN}✓ 清理完成${NC}"
else
    echo "跳过清理（增量编译）"
fi

echo ""

# ============ 步骤 5: 开始编译 ============
echo -e "${CYAN}[5/5] 开始编译固件${NC}"
echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${YELLOW}⏱  预计时间: 30-60 分钟${NC}"
echo -e "${YELLOW}📝 日志文件: $SDK_PATH/build_auto.log${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

cd "$SDK_PATH"

# 尝试使用 build.sh
if [ -f "./build.sh" ]; then
    echo "使用 build.sh 编译..."
    echo ""
    ./build.sh 2>&1 | tee build_auto.log
    BUILD_STATUS=${PIPESTATUS[0]}
else
    echo "使用 make 直接编译..."
    echo ""
    make -j$JOBS 2>&1 | tee build_auto.log
    BUILD_STATUS=${PIPESTATUS[0]}
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"

if [ $BUILD_STATUS -eq 0 ]; then
    echo -e "${GREEN}✅ 编译成功！${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo ""

    # 查找镜像
    echo -e "${CYAN}📦 镜像文件:${NC}"
    echo ""

    find "$SDK_PATH/out" \( -name "*.img" -o -name "*.fex" \) -type f 2>/dev/null | while read img; do
        SIZE=$(ls -lh "$img" | awk '{print $5}')
        echo "  $img ($SIZE)"
    done

    echo ""
    echo -e "${CYAN}📋 下一步:${NC}"
    echo "  1. 退出容器: exit"
    echo "  2. 复制镜像: ./start-docker.sh copy-image"
    echo "  3. 烧录到设备"
    echo ""
else
    echo -e "${RED}❌ 编译失败 (退出码: $BUILD_STATUS)${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}📝 查看日志:${NC}"
    echo "  tail -100 $SDK_PATH/build_auto.log"
    echo ""
    echo -e "${CYAN}📝 查看错误:${NC}"
    tail -50 "$SDK_PATH/build_auto.log" | grep -E "(error|Error|ERROR|failed|Failed)" || tail -30 "$SDK_PATH/build_auto.log"
    echo ""
    exit 1
fi
