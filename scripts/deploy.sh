#!/bin/bash
#
# V853 AI Glasses - 部署脚本
#
# 将编译好的文件部署到V853设备
#
# 用法:
#   ./deploy.sh <device_ip>     # 通过SSH部署
#   ./deploy.sh adb             # 通过ADB部署

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 项目根目录（脚本在 scripts/ 子目录中，需要返回上一级）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo -e "${GREEN}=== V853 AI Glasses Deploy Script ===${NC}"
echo ""

# 检查参数
if [ $# -eq 0 ]; then
    echo -e "${RED}错误: 请指定设备IP或使用'adb'${NC}"
    echo "用法:"
    echo "  $0 192.168.1.100    # SSH部署"
    echo "  $0 adb              # ADB部署"
    exit 1
fi

DEPLOY_METHOD=$1

# 定义文件列表
FILES=(
    "src/sdk_adapter/build/libai_glass_sdk_v853.so:/usr/lib/"
    "src/display_qt/build-v853/AIGlassesDisplay_V853:/usr/bin/"
    "src/ffm_launcher/build-v853/FFlaunch:/usr/bin/"
    "src/touchpad_manager/build-v853/touchpad_manager:/usr/bin/"
)

# ADB部署
deploy_adb() {
    echo -e "${GREEN}使用ADB部署...${NC}"

    # 检查ADB
    if ! command -v adb &> /dev/null; then
        echo -e "${RED}错误: 未找到adb命令${NC}"
        exit 1
    fi

    # 检查设备连接
    if ! adb devices | grep -q "device$"; then
        echo -e "${RED}错误: 未检测到ADB设备${NC}"
        echo "请确保设备已连接并开启ADB"
        exit 1
    fi

    echo "开始部署..."
    for item in "${FILES[@]}"; do
        local_file=$(echo $item | cut -d: -f1)
        remote_path=$(echo $item | cut -d: -f2)

        if [ -f "$PROJECT_ROOT/$local_file" ]; then
            echo -e "${GREEN}➜${NC} $local_file -> $remote_path"
            adb push "$PROJECT_ROOT/$local_file" "$remote_path"
        else
            echo -e "${YELLOW}⚠${NC} 跳过: $local_file (不存在)"
        fi
    done

    echo ""
    echo -e "${GREEN}ADB部署完成！${NC}"
}

# SSH部署
deploy_ssh() {
    local device_ip=$1
    echo -e "${GREEN}使用SSH部署到 $device_ip...${NC}"

    # 检查SSH连接
    if ! ping -c 1 -W 1 $device_ip &> /dev/null; then
        echo -e "${RED}错误: 无法连接到 $device_ip${NC}"
        exit 1
    fi

    echo "开始部署..."
    for item in "${FILES[@]}"; do
        local_file=$(echo $item | cut -d: -f1)
        remote_path=$(echo $item | cut -d: -f2)

        if [ -f "$PROJECT_ROOT/$local_file" ]; then
            echo -e "${GREEN}➜${NC} $local_file -> root@$device_ip:$remote_path"
            scp "$PROJECT_ROOT/$local_file" "root@$device_ip:$remote_path"
        else
            echo -e "${YELLOW}⚠${NC} 跳过: $local_file (不存在)"
        fi
    done

    # 设置可执行权限
    echo ""
    echo "设置可执行权限..."
    ssh root@$device_ip "chmod +x /usr/bin/AIGlassesDisplay_V853"
    ssh root@$device_ip "chmod +x /usr/bin/FFlaunch"
    ssh root@$device_ip "chmod +x /usr/bin/touchpad_manager"

    echo ""
    echo -e "${GREEN}SSH部署完成！${NC}"
}

# 主逻辑
case "$DEPLOY_METHOD" in
    adb)
        deploy_adb
        ;;
    *)
        deploy_ssh "$DEPLOY_METHOD"
        ;;
esac

echo ""
echo -e "${YELLOW}部署后操作:${NC}"
echo "1. SSH登录到设备:"
if [ "$DEPLOY_METHOD" != "adb" ]; then
    echo "   ssh root@$DEPLOY_METHOD"
else
    echo "   adb shell"
fi
echo ""
echo "2. 启动应用:"
echo "   /usr/bin/AIGlassesDisplay_V853"
echo ""
echo "3. 查看日志:"
echo "   logcat | grep V853"
echo ""

echo -e "${GREEN}Done!${NC}"
