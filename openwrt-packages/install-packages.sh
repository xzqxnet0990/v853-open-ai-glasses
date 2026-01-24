#!/bin/bash
# 安装 OpenWrt 包定义到 Tina SDK
# V853 AI Glasses - Package Installation Script
#
# 用法:
#   ./install-packages.sh [Tina_SDK_路径]
#
# 如果不提供路径，将使用默认路径: ../SDK/tina-v853-open

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 打印函数
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}=================================${NC}"
}

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Tina SDK 路径
if [ -n "$1" ]; then
    TINA_SDK_PATH="$1"
else
    TINA_SDK_PATH="$PROJECT_ROOT/SDK/tina-v853-open"
fi

# 目标包目录
TARGET_PKG_DIR="$TINA_SDK_PATH/openwrt/package/allwinner/ai-glasses"

print_header "AI Glasses OpenWrt 包安装脚本"

echo ""
print_info "项目根目录: $PROJECT_ROOT"
print_info "Tina SDK 路径: $TINA_SDK_PATH"
print_info "目标包目录: $TARGET_PKG_DIR"
echo ""

# 1. 检查 Tina SDK 路径
if [ ! -d "$TINA_SDK_PATH" ]; then
    print_error "Tina SDK 路径不存在: $TINA_SDK_PATH"
    echo ""
    echo "请指定正确的 Tina SDK 路径:"
    echo "  $0 /path/to/tina-v853-open"
    echo ""
    echo "或者将 Tina SDK 放置在默认位置:"
    echo "  $PROJECT_ROOT/SDK/tina-v853-open"
    exit 1
fi

if [ ! -d "$TINA_SDK_PATH/openwrt" ]; then
    print_error "无效的 Tina SDK 目录 (缺少 openwrt/ 子目录)"
    exit 1
fi

print_info "✓ Tina SDK 路径验证通过"

# 2. 检查源代码目录
print_info "检查源代码目录..."

if [ ! -d "$PROJECT_ROOT/src/sdk_adapter" ]; then
    print_error "找不到 SDK 适配层源代码: $PROJECT_ROOT/src/sdk_adapter"
    exit 1
fi

if [ ! -d "$PROJECT_ROOT/src/system_services" ]; then
    print_warn "找不到系统服务源代码: $PROJECT_ROOT/src/system_services"
    print_warn "system-services 包可能无法编译"
fi

if [ ! -d "$PROJECT_ROOT/src/display_qt" ]; then
    print_warn "找不到显示应用源代码: $PROJECT_ROOT/src/display_qt"
    print_warn "display-qt 包可能无法编译"
fi

print_info "✓ 源代码目录检查完成"

# 3. 创建目标目录
print_info "创建目标包目录..."

mkdir -p "$TARGET_PKG_DIR"

if [ ! -d "$TARGET_PKG_DIR" ]; then
    print_error "无法创建目标目录: $TARGET_PKG_DIR"
    exit 1
fi

print_info "✓ 目标目录创建成功"

# 4. 复制包定义
print_info "复制包定义到 Tina SDK..."

# 复制 ai-glass-sdk 包
if [ -d "$SCRIPT_DIR/ai-glass-sdk" ]; then
    print_info "  - 复制 ai-glass-sdk..."
    cp -r "$SCRIPT_DIR/ai-glass-sdk" "$TARGET_PKG_DIR/"
    print_info "    ✓ ai-glass-sdk 复制完成"
else
    print_error "找不到 ai-glass-sdk 包定义"
    exit 1
fi

# 复制 system-services 包
if [ -d "$SCRIPT_DIR/system-services" ]; then
    print_info "  - 复制 system-services..."
    cp -r "$SCRIPT_DIR/system-services" "$TARGET_PKG_DIR/"
    print_info "    ✓ system-services 复制完成"
else
    print_warn "跳过 system-services (包定义不存在)"
fi

# 复制 display-qt 包
if [ -d "$SCRIPT_DIR/display-qt" ]; then
    print_info "  - 复制 display-qt..."
    cp -r "$SCRIPT_DIR/display-qt" "$TARGET_PKG_DIR/"
    print_info "    ✓ display-qt 复制完成"
else
    print_warn "跳过 display-qt (包定义不存在)"
fi

print_info "✓ 所有包定义复制完成"

# 5. 检查相对路径
print_info "检查 Makefile 中的相对路径..."

# 计算从 Tina SDK 到项目根目录的相对路径
TINA_SDK_ABS=$(cd "$TINA_SDK_PATH" && pwd)
PROJECT_ROOT_ABS=$(cd "$PROJECT_ROOT" && pwd)

# 检查是否需要修改路径
if [[ "$PROJECT_ROOT_ABS" != "$TINA_SDK_ABS/../v853-ai-glasses" ]]; then
    print_warn "检测到非标准目录结构"
    print_warn "项目路径: $PROJECT_ROOT_ABS"
    print_warn "Tina SDK: $TINA_SDK_ABS"
    print_warn ""
    print_warn "您可能需要手动修改 Makefile 中的 SRC_CODE_DIR 路径:"
    print_warn "  $TARGET_PKG_DIR/ai-glass-sdk/Makefile"
    print_warn "  $TARGET_PKG_DIR/system-services/Makefile"
    print_warn "  $TARGET_PKG_DIR/display-qt/Makefile"
    print_warn ""
    print_warn "将以下行修改为绝对路径:"
    print_warn "  SRC_CODE_DIR := $PROJECT_ROOT_ABS/src/xxx"
else
    print_info "✓ 目录结构符合预期，相对路径应该可用"
fi

# 6. 打印后续操作指南
echo ""
print_header "安装完成！"
echo ""
print_info "包已安装到: $TARGET_PKG_DIR"
echo ""
print_info "后续操作:"
echo ""
echo "1. 进入 Tina SDK 目录:"
echo "   ${BLUE}cd $TINA_SDK_PATH${NC}"
echo ""
echo "2. 加载构建环境:"
echo "   ${BLUE}source build/envsetup.sh${NC}"
echo "   ${BLUE}lunch v853-100ask-tina${NC}"
echo ""
echo "3. 配置包 (可选):"
echo "   ${BLUE}make menuconfig${NC}"
echo "   导航到: ${YELLOW}Allwinner > AI Glasses${NC}"
echo ""
echo "4. 编译单个包 (测试):"
echo "   ${BLUE}make package/allwinner/ai-glasses/ai-glass-sdk/compile V=s${NC}"
echo ""
echo "5. 编译所有 AI Glasses 包:"
echo "   ${BLUE}make package/allwinner/ai-glasses/compile V=s${NC}"
echo ""
echo "6. 构建完整固件:"
echo "   ${BLUE}./build.sh${NC}"
echo ""
echo "固件输出位置:"
echo "   ${GREEN}$TINA_SDK_PATH/out/v853/image/tina_v853-100ask_uart0.img${NC}"
echo ""

print_header "安装脚本执行完毕"
exit 0
