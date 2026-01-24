#!/bin/bash
#
# V853 编译调试脚本 - 查看详细的编译错误
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== V853 编译调试脚本 ===${NC}"
echo ""

# 检查是否在容器内
if [ ! -d "/opt/v853_sdk" ]; then
    echo -e "${RED}错误: 请在 Docker 容器内运行${NC}"
    echo "使用: ./start-docker.sh shell"
    exit 1
fi

SDK_PATH="/opt/v853_sdk"

echo -e "${GREEN}1. 检查磁盘空间${NC}"
df -h /opt/v853_sdk
echo ""

echo -e "${GREEN}2. 检查内存使用${NC}"
free -h
echo ""

echo -e "${GREEN}3. 查看最近的编译日志${NC}"
echo ""

# 查找编译日志
LOG_PATHS=(
    "$SDK_PATH/out/v853/100ask/longan_buildlog.log"
    "$SDK_PATH/out/v853/100ask/kernel_build.log"
    "$SDK_PATH/out/v853/buildroot.log"
    "$SDK_PATH/kernel/linux-4.9/.build.log"
)

for log in "${LOG_PATHS[@]}"; do
    if [ -f "$log" ]; then
        echo -e "${CYAN}找到日志: $log${NC}"
        echo -e "${YELLOW}最后 50 行错误信息:${NC}"
        tail -n 50 "$log" | grep -E "(error|Error|ERROR|failed|Failed|FAILED)" || echo "  (无明显错误)"
        echo ""
    fi
done

echo -e "${GREEN}4. 查看内核编译输出目录${NC}"
if [ -d "$SDK_PATH/kernel/linux-4.9" ]; then
    cd "$SDK_PATH/kernel/linux-4.9"
    echo "当前目录: $(pwd)"
    echo ""

    # 检查是否有未完成的编译
    if [ -f ".config" ]; then
        echo -e "${CYAN}内核配置存在${NC}"
    else
        echo -e "${RED}内核配置缺失！${NC}"
    fi

    # 检查编译状态
    if [ -f "vmlinux" ]; then
        echo -e "${GREEN}✓ vmlinux 已生成${NC}"
        ls -lh vmlinux
    else
        echo -e "${YELLOW}⚠️  vmlinux 未生成${NC}"
    fi

    echo ""
fi

echo -e "${GREEN}5. 检查问题模块${NC}"
echo ""

# 检查 tft08006.c 文件
TFT_FILE="$SDK_PATH/kernel/linux-4.9/drivers/video/fbdev/sunxi/disp2/disp/lcd/tft08006.c"
if [ -f "$TFT_FILE" ]; then
    echo -e "${CYAN}检查 tft08006.c 编译状态:${NC}"

    # 尝试单独编译这个文件
    cd "$SDK_PATH/kernel/linux-4.9"
    make drivers/video/fbdev/sunxi/disp2/disp/lcd/tft08006.o 2>&1 | tail -20 || echo "  编译失败"
fi

echo ""
echo -e "${GREEN}6. 推荐的修复步骤${NC}"
echo ""
echo "如果问题依然存在，尝试以下步骤："
echo ""
echo "方案 A: 完全清理重新编译"
echo "  cd /opt/v853_sdk"
echo "  make clean"
echo "  source build/envsetup.sh"
echo "  lunch v853-100ask-tina"
echo "  make kernel_menuconfig  # 可选：检查内核配置"
echo "  ./build.sh"
echo ""
echo "方案 B: 只重新编译内核"
echo "  cd /opt/v853_sdk"
echo "  source build/envsetup.sh"
echo "  lunch v853-100ask-tina"
echo "  make kernel -j4  # 使用4线程编译，降低内存压力"
echo ""
echo "方案 C: 禁用问题驱动"
echo "  cd /opt/v853_sdk"
echo "  make kernel_menuconfig"
echo "  # 在菜单中禁用: Device Drivers -> Graphics support -> Frame buffer Devices -> Video support for sunxi -> tft08006"
echo "  ./build.sh"
echo ""
