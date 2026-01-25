#!/bin/bash
#
# V853 SDK 验证脚本
#
# 验证 Tina SDK 是否正确安装和配置

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
SDK_PATH="$PROJECT_ROOT/SDK/tina-v853-open"

echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${CYAN}     V853 SDK 验证工具${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo ""

PASS_COUNT=0
FAIL_COUNT=0

# 检查函数
check_item() {
    local item="$1"
    local command="$2"

    echo -n "  检查 $item... "

    if eval "$command" > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        ((PASS_COUNT++))
        return 0
    else
        echo -e "${RED}✗${NC}"
        ((FAIL_COUNT++))
        return 1
    fi
}

# 1. 检查 SDK 目录
echo -e "${CYAN}[1/6] SDK 目录检查${NC}"
check_item "SDK 根目录存在" "[ -d '$SDK_PATH' ]"
check_item "build/ 目录" "[ -d '$SDK_PATH/build' ]"
check_item "kernel/ 目录" "[ -d '$SDK_PATH/kernel' ]"
check_item "openwrt/ 目录" "[ -d '$SDK_PATH/openwrt' ]"
check_item "prebuilt/ 目录" "[ -d '$SDK_PATH/prebuilt' ]"
echo ""

# 2. 检查工具链
echo -e "${CYAN}[2/6] 工具链检查${NC}"
TOOLCHAIN_BASE="$SDK_PATH/prebuilt/rootfsbuilt/arm"
check_item "ARM 工具链目录" "[ -d '$TOOLCHAIN_BASE' ]"
check_item "toolchain-sunxi-musl-gcc-830" "[ -d '$TOOLCHAIN_BASE/toolchain-sunxi-musl-gcc-830' ]"
check_item "toolchain-sunxi-glibc-gcc-830" "[ -d '$TOOLCHAIN_BASE/toolchain-sunxi-glibc-gcc-830' ]"

# 检查 GCC 编译器
GCC_PATH=$(find "$TOOLCHAIN_BASE" -name "arm-openwrt-linux-gcc" -type f 2>/dev/null | head -1)
if [ -n "$GCC_PATH" ]; then
    echo -e "  ${GREEN}✓${NC} GCC 编译器: $GCC_PATH"
    ((PASS_COUNT++))
else
    echo -e "  ${RED}✗${NC} GCC 编译器未找到"
    ((FAIL_COUNT++))
fi
echo ""

# 3. 检查关键文件
echo -e "${CYAN}[3/6] 关键文件检查${NC}"
check_item "build.sh 脚本" "[ -f '$SDK_PATH/build.sh' ]"
check_item "envsetup.sh 脚本" "[ -f '$SDK_PATH/build/envsetup.sh' ]"
check_item ".buildconfig 文件" "[ -f '$SDK_PATH/.buildconfig' ]"
echo ""

# 4. 检查 Docker 配置
echo -e "${CYAN}[4/6] Docker 配置检查${NC}"
check_item "docker-compose.yml 存在" "[ -f '$PROJECT_ROOT/docker-compose.yml' ]"
check_item "Dockerfile 存在" "[ -f '$PROJECT_ROOT/Dockerfile' ]"

# 检查 docker-compose.yml 中的 SDK 挂载
if grep -q "tina-v853-open:/opt/v853_sdk" "$PROJECT_ROOT/docker-compose.yml" 2>/dev/null; then
    echo -e "  ${GREEN}✓${NC} docker-compose.yml SDK 挂载配置正确"
    ((PASS_COUNT++))
else
    echo -e "  ${RED}✗${NC} docker-compose.yml SDK 挂载配置错误"
    ((FAIL_COUNT++))
fi
echo ""

# 5. 检查 SDK 大小
echo -e "${CYAN}[5/6] SDK 完整性检查${NC}"
SDK_SIZE=$(du -sh "$SDK_PATH" 2>/dev/null | awk '{print $1}')
echo "  SDK 大小: $SDK_SIZE"

# 检查是否大于 10GB（正常的 SDK 应该在 10-20GB）
SIZE_NUM=$(echo "$SDK_SIZE" | sed 's/[^0-9.]//g')
SIZE_UNIT=$(echo "$SDK_SIZE" | sed 's/[0-9.]//g')

if [[ "$SIZE_UNIT" == "G" ]] && (( $(echo "$SIZE_NUM > 10" | bc -l) )); then
    echo -e "  ${GREEN}✓${NC} SDK 大小正常（预期 10-20GB）"
    ((PASS_COUNT++))
else
    echo -e "  ${YELLOW}⚠${NC}  SDK 大小可能不完整（当前 $SDK_SIZE，预期 10-20GB）"
    ((FAIL_COUNT++))
fi
echo ""

# 6. 检查设备配置
echo -e "${CYAN}[6/6] 设备配置检查${NC}"
DEVICE_PATH="$SDK_PATH/device/config/chips/v853"
if [ -d "$DEVICE_PATH" ]; then
    echo -e "  ${GREEN}✓${NC} V853 设备配置存在"
    ((PASS_COUNT++))

    # 列出 V853 配置
    echo "  V853 配置目录:"
    ls -1 "$DEVICE_PATH" 2>/dev/null | head -5 | sed 's/^/    - /'
else
    echo -e "  ${YELLOW}⚠${NC}  V853 设备配置目录不存在（可能使用其他路径）"
fi
echo ""

# 生成报告
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo -e "${CYAN}     验证结果${NC}"
echo -e "${CYAN}═══════════════════════════════════════════${NC}"
echo ""

TOTAL=$((PASS_COUNT + FAIL_COUNT))
echo -e "  总计: $TOTAL 项检查"
echo -e "  ${GREEN}通过: $PASS_COUNT${NC}"
echo -e "  ${RED}失败: $FAIL_COUNT${NC}"
echo ""

if [ $FAIL_COUNT -eq 0 ]; then
    echo -e "${GREEN}✅ SDK 验证通过！可以开始开发${NC}"
    echo ""
    echo -e "${CYAN}下一步:${NC}"
    echo "  1. 启动容器: ./start-docker.sh start"
    echo "  2. 编译项目: ./start-docker.sh build-all"
    echo ""
    exit 0
elif [ $FAIL_COUNT -le 2 ]; then
    echo -e "${YELLOW}⚠️  SDK 验证部分通过，可能可以使用但建议检查失败项${NC}"
    exit 1
else
    echo -e "${RED}❌ SDK 验证失败，请检查 SDK 安装${NC}"
    exit 1
fi
