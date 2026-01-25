#!/bin/bash
#
# V853 编译状态检查
# 查看当前编译进度和产物
#

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}  V853 编译状态检查${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# 检查是否在容器内
if [ ! -d "/opt/v853_sdk" ]; then
    echo -e "${RED}错误: 请在 Docker 容器内运行${NC}"
    exit 1
fi

SDK_PATH="/opt/v853_sdk"

# ============ 1. 内核编译状态 ============
echo -e "${CYAN}[1/5] 内核编译状态${NC}"
echo ""

KERNEL_IMAGE="$SDK_PATH/kernel/linux-4.9/arch/arm/boot/zImage"
if [ -f "$KERNEL_IMAGE" ]; then
    SIZE=$(ls -lh "$KERNEL_IMAGE" | awk '{print $5}')
    MTIME=$(stat -c '%y' "$KERNEL_IMAGE" 2>/dev/null || stat -f '%Sm' "$KERNEL_IMAGE")
    echo -e "${GREEN}✓ 内核镜像已编译${NC}"
    echo "  文件: $KERNEL_IMAGE"
    echo "  大小: $SIZE"
    echo "  时间: $MTIME"
else
    echo -e "${YELLOW}✗ 内核镜像未编译${NC}"
fi

echo ""

# ============ 2. 设备树状态 ============
echo -e "${CYAN}[2/5] 设备树编译状态${NC}"
echo ""

DTB_COUNT=$(find "$SDK_PATH/kernel/linux-4.9/arch/arm/boot/dts" -name "*.dtb" 2>/dev/null | wc -l)
if [ $DTB_COUNT -gt 0 ]; then
    echo -e "${GREEN}✓ 找到 $DTB_COUNT 个 DTB 文件${NC}"
    find "$SDK_PATH/kernel/linux-4.9/arch/arm/boot/dts" -name "*.dtb" 2>/dev/null | head -3 | while read dtb; do
        SIZE=$(ls -lh "$dtb" | awk '{print $5}')
        echo "  $(basename $dtb) ($SIZE)"
    done
else
    echo -e "${YELLOW}✗ 未找到 DTB 文件${NC}"
fi

echo ""

# ============ 3. Buildroot/OpenWrt 状态 ============
echo -e "${CYAN}[3/5] Buildroot/OpenWrt 状态${NC}"
echo ""

ROOTFS_DIRS=(
    "$SDK_PATH/out/v853/100ask/openwrt"
    "$SDK_PATH/out/v853/vision/openwrt"
    "$SDK_PATH/out/v853/openwrt"
)

ROOTFS_FOUND=false
for dir in "${ROOTFS_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓ 找到 OpenWrt 编译输出: $dir${NC}"
        ROOTFS_FOUND=true
        break
    fi
done

if [ "$ROOTFS_FOUND" = false ]; then
    echo -e "${YELLOW}✗ OpenWrt/Buildroot 未编译${NC}"
fi

echo ""

# ============ 4. 镜像文件状态 ============
echo -e "${CYAN}[4/5] 镜像文件${NC}"
echo ""

IMG_FOUND=false
find "$SDK_PATH/out" \( -name "*.img" -o -name "*.fex" \) -type f 2>/dev/null | while read img; do
    IMG_FOUND=true
    SIZE=$(ls -lh "$img" | awk '{print $5}')
    MTIME=$(stat -c '%y' "$img" 2>/dev/null || stat -f '%Sm' "$img" 2>/dev/null || echo "Unknown")
    echo -e "${GREEN}✓ $img${NC}"
    echo "  大小: $SIZE"
    echo "  时间: $MTIME"
    echo ""
done

if [ "$IMG_FOUND" = false ]; then
    echo -e "${YELLOW}✗ 未找到镜像文件${NC}"
    echo ""
    echo "  镜像可能还未打包，运行: ./pack_image.sh"
fi

echo ""

# ============ 5. 应用层编译状态 ============
echo -e "${CYAN}[5/5] 应用层编译状态${NC}"
echo ""

APP_FILES=(
    "/workspace/src/sdk_adapter/build/libai_glass_sdk_v853.so"
    "/workspace/src/display_lvgl/build-v853/AIGlassesDisplayLVGL"
    "/workspace/src/ffm_launcher/build-v853/FFlaunch"
    "/workspace/src/touchpad_manager/build-v853/touchpad_manager"
)

for app in "${APP_FILES[@]}"; do
    if [ -f "$app" ]; then
        SIZE=$(ls -lh "$app" | awk '{print $5}')
        echo -e "${GREEN}✓ $(basename $app) ($SIZE)${NC}"
    else
        echo -e "${YELLOW}✗ $(basename $app)${NC}"
    fi
done

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${CYAN}📋 建议的下一步操作:${NC}"
echo ""

# 根据状态给出建议
if [ -f "$KERNEL_IMAGE" ]; then
    if find "$SDK_PATH/out" -name "*.img" 2>/dev/null | grep -q .; then
        echo "  ✅ 固件已编译完成"
        echo "     运行: exit && ./start-docker.sh copy-image"
    else
        echo "  ⚠️  内核已编译，但镜像未打包"
        echo "     运行: ./pack_image.sh"
    fi
else
    echo "  ⚠️  内核未编译"
    echo "     运行: ./build_kernel_only.sh"
fi

echo ""

# 检查应用层
APP_COUNT=0
for app in "${APP_FILES[@]}"; do
    if [ -f "$app" ]; then
        ((APP_COUNT++)) || true
    fi
done

if [ $APP_COUNT -lt ${#APP_FILES[@]} ]; then
    echo "  ⚠️  应用层未完全编译"
    echo "     运行: ./build_all.sh"
fi

echo ""
