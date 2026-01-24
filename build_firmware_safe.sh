#!/bin/bash
#
# V853 安全编译脚本 - 降低并发，避免内存/资源问题
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== V853 安全编译模式 ===${NC}"
echo ""

# 检查是否在容器内
if [ ! -d "/opt/v853_sdk" ]; then
    echo -e "${RED}错误: 请在 Docker 容器内运行${NC}"
    echo "使用: ./start-docker.sh shell"
    exit 1
fi

SDK_PATH="/opt/v853_sdk"

echo -e "${YELLOW}此脚本将使用低并发编译，避免内存不足${NC}"
echo ""

# 检查可用内存
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
echo -e "${GREEN}编译步骤:${NC}"
echo ""

cd "$SDK_PATH"

# 1. 配置环境
echo -e "${CYAN}[1/5] 配置编译环境${NC}"
source build/envsetup.sh

# 2. 选择方案
echo -e "${CYAN}[2/5] 选择编译方案${NC}"
lunch v853-100ask-tina

# 3. 清理旧的编译产物（可选）
read -p "是否清理旧的编译产物? (y/N): " clean_old
if [ "$clean_old" = "y" ] || [ "$clean_old" = "Y" ]; then
    echo -e "${CYAN}[3/5] 清理旧产物${NC}"
    make clean
else
    echo -e "${CYAN}[3/5] 跳过清理${NC}"
fi

# 4. 编译（低并发）
echo ""
echo -e "${CYAN}[4/5] 开始编译固件（使用 -j$JOBS）${NC}"
echo -e "${YELLOW}预计时间: 30-60 分钟，请耐心等待...${NC}"
echo ""

# 使用 V=1 显示详细输出，方便调试
make -j$JOBS V=1 2>&1 | tee "$SDK_PATH/build_safe.log"

BUILD_STATUS=${PIPESTATUS[0]}

# 5. 检查编译结果
echo ""
echo -e "${CYAN}[5/5] 检查编译结果${NC}"

if [ $BUILD_STATUS -eq 0 ]; then
    echo -e "${GREEN}==================================${NC}"
    echo -e "${GREEN}✅ 编译成功！${NC}"
    echo -e "${GREEN}==================================${NC}"
    echo ""

    # 查找生成的镜像
    IMAGE_DIRS=(
        "$SDK_PATH/out/v853/100ask/image"
        "$SDK_PATH/out/v853/vision/image"
        "$SDK_PATH/out/v853/image"
    )

    for img_dir in "${IMAGE_DIRS[@]}"; do
        if [ -d "$img_dir" ]; then
            echo -e "${CYAN}镜像文件位置: $img_dir${NC}"
            ls -lh "$img_dir"/*.img "$img_dir"/*.fex 2>/dev/null || true
            echo ""
        fi
    done

    echo -e "${YELLOW}下一步:${NC}"
    echo "  1. 复制镜像到主机: exit 容器后运行 ./start-docker.sh copy-image"
    echo "  2. 烧录到设备: 使用 PhoenixSuit 或 LiveSuit 工具"
    echo ""
else
    echo -e "${RED}==================================${NC}"
    echo -e "${RED}❌ 编译失败${NC}"
    echo -e "${RED}==================================${NC}"
    echo ""
    echo -e "${CYAN}调试信息:${NC}"
    echo "  完整日志: $SDK_PATH/build_safe.log"
    echo ""
    echo "  查看错误: tail -n 100 $SDK_PATH/build_safe.log"
    echo "  查看内核日志: tail -n 100 $SDK_PATH/out/v853/100ask/longan_buildlog.log"
    echo ""
    exit 1
fi
