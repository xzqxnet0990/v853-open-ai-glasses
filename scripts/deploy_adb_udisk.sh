#!/bin/bash
#
# V853 AI Glasses - ADB 部署脚本（UDISK 分区）
#
# 将编译产物通过 ADB 部署到 V853 设备的 UDISK 分区
# 解决 overlayfs 文件系统不一致问题
#
# 用法:
#   ./deploy_adb_udisk.sh              # 部署所有文件
#   ./deploy_adb_udisk.sh --app-only   # 只部署应用程序

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_DIR="$PROJECT_ROOT/output"

# UDISK 目标路径
UDISK_BASE="/mnt/UDISK/aiglasses"
UDISK_BIN="$UDISK_BASE/bin"
UDISK_LIB="$UDISK_BASE/lib"

echo -e "${CYAN}=== V853 AI Glasses ADB Deployment (UDISK) ===${NC}"
echo ""

# 检查 ADB 设备
echo -e "${GREEN}[1/5] 检查 ADB 连接...${NC}"
if ! adb devices | grep -q "device$"; then
    echo -e "${RED}错误: 未找到 ADB 设备${NC}"
    echo "请确保:"
    echo "  1. USB 已连接"
    echo "  2. ADB 已安装 (brew install android-platform-tools)"
    echo "  3. 设备已授权"
    exit 1
fi

adb devices
echo -e "${GREEN}✓ ADB 设备已连接${NC}"
echo ""

# 获取 root 权限并重新挂载
echo -e "${GREEN}[2/5] 获取 root 权限...${NC}"
adb root 2>/dev/null || true
sleep 1
adb remount 2>/dev/null || true
echo -e "${GREEN}✓ Root 权限已获取${NC}"
echo ""

# 创建目标目录
echo -e "${GREEN}[3/5] 创建 UDISK 目录...${NC}"
adb shell "mkdir -p $UDISK_BIN $UDISK_LIB"
echo -e "${GREEN}✓ 目录已创建: $UDISK_BASE${NC}"
echo ""

# 检查编译产物
echo -e "${GREEN}[4/5] 检查编译产物...${NC}"
if [ ! -d "$OUTPUT_DIR" ]; then
    echo -e "${RED}错误: output/ 目录不存在${NC}"
    echo "请先从 Docker 容器复制文件:"
    echo "  docker cp v853_ai_glasses_dev:/workspace/src/sdk_adapter/build/libai_glass_sdk_v853.so ./output/"
    echo "  docker cp v853_ai_glasses_dev:/workspace/src/display_lvgl/build-v853/AIGlassesDisplayLVGL ./output/"
    exit 1
fi

# 部署文件
echo -e "${GREEN}[5/5] 部署文件到设备...${NC}"

APP_ONLY=false
if [ "$1" = "--app-only" ]; then
    APP_ONLY=true
    echo -e "${YELLOW}只部署应用程序（跳过库文件）${NC}"
fi

# 部署库文件
if [ "$APP_ONLY" = false ]; then
    if [ -f "$OUTPUT_DIR/libai_glass_sdk_v853.so" ]; then
        echo -e "${CYAN}→ 部署 SDK 库...${NC}"
        adb push "$OUTPUT_DIR/libai_glass_sdk_v853.so" "$UDISK_LIB/"
        adb shell chmod 644 "$UDISK_LIB/libai_glass_sdk_v853.so"
        echo -e "${GREEN}  ✓ libai_glass_sdk_v853.so${NC}"
    else
        echo -e "${YELLOW}  ⊘ libai_glass_sdk_v853.so 不存在，跳过${NC}"
    fi
fi

# 部署应用程序
DEPLOYED_COUNT=0

if [ -f "$OUTPUT_DIR/AIGlassesDisplayLVGL" ]; then
    echo -e "${CYAN}→ 部署 LVGL 应用...${NC}"
    adb push "$OUTPUT_DIR/AIGlassesDisplayLVGL" "$UDISK_BIN/"
    adb shell chmod 755 "$UDISK_BIN/AIGlassesDisplayLVGL"
    echo -e "${GREEN}  ✓ AIGlassesDisplayLVGL${NC}"
    ((DEPLOYED_COUNT++))
fi

if [ -f "$OUTPUT_DIR/FFlaunch" ]; then
    echo -e "${CYAN}→ 部署 FFmpeg 启动器...${NC}"
    adb push "$OUTPUT_DIR/FFlaunch" "$UDISK_BIN/"
    adb shell chmod 755 "$UDISK_BIN/FFlaunch"
    echo -e "${GREEN}  ✓ FFlaunch${NC}"
    ((DEPLOYED_COUNT++))
fi

if [ -f "$OUTPUT_DIR/touchpad_manager" ]; then
    echo -e "${CYAN}→ 部署 GPIO 管理器...${NC}"
    adb push "$OUTPUT_DIR/touchpad_manager" "$UDISK_BIN/"
    adb shell chmod 755 "$UDISK_BIN/touchpad_manager"
    echo -e "${GREEN}  ✓ touchpad_manager${NC}"
    ((DEPLOYED_COUNT++))
fi

# 同步文件系统
echo -e "${CYAN}→ 同步文件系统...${NC}"
adb shell sync
echo -e "${GREEN}  ✓ 已同步${NC}"
echo ""

# 验证部署
echo -e "${GREEN}=== 部署验证 ===${NC}"
adb shell "ls -lh $UDISK_BIN/ 2>/dev/null || echo '目录为空'"
echo ""

if [ $DEPLOYED_COUNT -eq 0 ]; then
    echo -e "${YELLOW}警告: 没有部署任何文件${NC}"
    echo "请确保编译产物存在于 output/ 目录"
    exit 1
fi

# 部署成功
echo -e "${GREEN}✅ 部署成功！已部署 $DEPLOYED_COUNT 个文件${NC}"
echo ""
echo -e "${CYAN}=== 如何运行 ===${NC}"
echo ""
echo "方法 1: 通过 ADB shell"
echo "  adb shell"
echo "  export LD_LIBRARY_PATH=/mnt/UDISK/aiglasses/lib:\$LD_LIBRARY_PATH"
echo "  /mnt/UDISK/aiglasses/bin/AIGlassesDisplayLVGL"
echo ""
echo "方法 2: 通过串口终端"
echo "  export LD_LIBRARY_PATH=/mnt/UDISK/aiglasses/lib:\$LD_LIBRARY_PATH"
echo "  /mnt/UDISK/aiglasses/bin/AIGlassesDisplayLVGL"
echo ""
echo "方法 3: 使用启动脚本（如果已创建）"
echo "  /mnt/UDISK/aiglasses/start.sh"
echo ""
