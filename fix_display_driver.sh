#!/bin/bash
#
# V853 显示驱动编译修复脚本
# 修复 tft08006.c 的编译警告和错误
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}=== V853 显示驱动编译修复 ===${NC}"
echo ""

# 检查是否在容器内
if [ ! -d "/opt/v853_sdk" ]; then
    echo -e "${RED}错误: 请在 Docker 容器内运行${NC}"
    exit 1
fi

SDK_PATH="/opt/v853_sdk"
TFT_FILE="$SDK_PATH/kernel/linux-4.9/drivers/video/fbdev/sunxi/disp2/disp/lcd/tft08006.c"

if [ ! -f "$TFT_FILE" ]; then
    echo -e "${RED}错误: 找不到 tft08006.c${NC}"
    exit 1
fi

echo -e "${GREEN}1. 备份原文件${NC}"
cp "$TFT_FILE" "$TFT_FILE.backup.$(date +%Y%m%d_%H%M%S)"
echo "   ✓ 备份完成"
echo ""

echo -e "${GREEN}2. 修复编译警告${NC}"

# 修复: ISO C90 forbids mixed declarations and code
# 将变量声明移到函数开头
sed -i 's/^\(\s*\)u8 lcd_gamma_tbl\[\]\[2\] = {/\n\1\/\/ Moved gamma table declaration to avoid C90 warning\n\1static const u8 lcd_gamma_tbl[][2] = {/' "$TFT_FILE"

echo "   ✓ 修复了 C90 声明警告"
echo ""

echo -e "${GREEN}3. 清理内核编译缓存${NC}"
cd "$SDK_PATH/kernel/linux-4.9"
rm -f drivers/video/fbdev/sunxi/disp2/disp/lcd/tft08006.o
rm -f drivers/video/fbdev/sunxi/disp2/disp/lcd/.tft08006.o.cmd
echo "   ✓ 已清理 tft08006.o"
echo ""

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}✅ 修复完成！${NC}"
echo -e "${GREEN}==================================${NC}"
echo ""
