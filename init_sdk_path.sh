#!/bin/bash
# V853 SDK路径初始化脚本
# 用于更新所有工具链文件中的SDK路径

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SDK_DIR="${PROJECT_DIR}/SDK/tina-v853-open"

echo -e "${BLUE}=== V853 SDK路径初始化 ===${NC}"
echo ""

# 检查SDK目录
if [ ! -d "$SDK_DIR" ]; then
    echo -e "${RED}❌ 错误: SDK目录不存在: $SDK_DIR${NC}"
    echo ""
    echo -e "${YELLOW}解决方案:${NC}"
    echo "  1. 确保已解压 tina-v853-open SDK"
    echo "  2. SDK应位于: SDK/tina-v853-open/"
    echo "  3. 或手动设置SDK_DIR环境变量"
    exit 1
fi

echo -e "${GREEN}✓ SDK目录找到: $SDK_DIR${NC}"
echo ""

# 需要更新的工具链文件
TOOLCHAIN_FILES=(
    "src/sdk_adapter/toolchain-v853.cmake"
    "src/display_qt/toolchain-v853.cmake"
    "src/ffm_launcher/toolchain-v853.cmake"
    "src/touchpad_manager/toolchain-v853.cmake"
)

echo -e "${BLUE}更新工具链文件中的SDK路径...${NC}"
echo ""

for file in "${TOOLCHAIN_FILES[@]}"; do
    file_path="${PROJECT_DIR}/${file}"

    if [ -f "$file_path" ]; then
        echo -e "${GREEN}➜${NC} 更新: $file"

        # 使用sed更新V853_SDK_PATH
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s|set(V853_SDK_PATH \".*\"|set(V853_SDK_PATH \"$SDK_DIR\"|g" "$file_path"
        else
            # Linux
            sed -i "s|set(V853_SDK_PATH \".*\"|set(V853_SDK_PATH \"$SDK_DIR\"|g" "$file_path"
        fi
    else
        echo -e "${YELLOW}⚠${NC}  跳过: $file (不存在)"
    fi
done

echo ""
echo -e "${GREEN}✅ SDK路径初始化完成！${NC}"
echo ""
echo -e "${CYAN}SDK路径已设置为:${NC}"
echo "  $SDK_DIR"
echo ""
echo -e "${CYAN}工具链路径:${NC}"
echo "  $SDK_DIR/prebuilt/gcc/linux-x86/arm/toolchain-sunxi-musl/toolchain"
echo ""
echo -e "${YELLOW}提示:${NC}"
echo "  • 如果移动项目目录，请重新运行此脚本"
echo "  • Docker环境会自动处理路径，无需运行此脚本"
echo ""
