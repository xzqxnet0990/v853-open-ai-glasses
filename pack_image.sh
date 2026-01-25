#!/bin/bash
#
# V853 打包镜像脚本
# 内核已编译，打包成可烧录的镜像
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}  V853 镜像打包工具${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# 检查是否在容器内
if [ ! -d "/opt/v853_sdk" ]; then
    echo -e "${RED}错误: 请在 Docker 容器内运行${NC}"
    exit 1
fi

SDK_PATH="/opt/v853_sdk"

cd "$SDK_PATH"

# ============ 步骤 1: 检查编译状态 ============
echo -e "${CYAN}[1/4] 检查编译状态${NC}"
echo ""

KERNEL_IMAGE="$SDK_PATH/kernel/linux-4.9/arch/arm/boot/zImage"
if [ -f "$KERNEL_IMAGE" ]; then
    SIZE=$(ls -lh "$KERNEL_IMAGE" | awk '{print $5}')
    echo -e "${GREEN}✓ 内核镜像存在: $SIZE${NC}"
else
    echo -e "${YELLOW}⚠️  内核镜像不存在，可能需要先编译内核${NC}"
fi

# 检查 DTB
DTB_FILES=$(find "$SDK_PATH/kernel/linux-4.9/arch/arm/boot/dts" -name "*.dtb" 2>/dev/null || true)
if [ -n "$DTB_FILES" ]; then
    echo -e "${GREEN}✓ 设备树文件存在${NC}"
else
    echo -e "${YELLOW}⚠️  设备树文件不存在${NC}"
fi

echo ""

# ============ 步骤 2: 查找现有镜像 ============
echo -e "${CYAN}[2/4] 查找已有镜像${NC}"
echo ""

EXISTING_IMAGES=$(find "$SDK_PATH/out" \( -name "*.img" -o -name "*.fex" \) -type f 2>/dev/null || true)

if [ -n "$EXISTING_IMAGES" ]; then
    echo -e "${GREEN}找到以下镜像文件:${NC}"
    echo "$EXISTING_IMAGES" | while read img; do
        SIZE=$(ls -lh "$img" | awk '{print $5}')
        echo "  $img ($SIZE)"
    done
    echo ""
    echo -e "${CYAN}这些镜像可能已经可用！${NC}"
    read -p "是否重新打包? (y/N): " repack
    if [ "$repack" != "y" ] && [ "$repack" != "Y" ]; then
        echo ""
        echo -e "${GREEN}使用现有镜像${NC}"
        exit 0
    fi
else
    echo "未找到已有镜像，需要打包"
fi

echo ""

# ============ 步骤 3: 尝试打包镜像 ============
echo -e "${CYAN}[3/4] 打包镜像${NC}"
echo ""

# 配置环境
if [ -f "build/envsetup.sh" ]; then
    source build/envsetup.sh
    export TARGET_PRODUCT=${TARGET_PRODUCT:-v853-100ask}
    echo "TARGET_PRODUCT: $TARGET_PRODUCT"
fi

echo ""
echo "尝试以下打包命令..."
echo ""

# 尝试不同的打包命令
PACK_SUCCESS=false

# 方法 1: make pack
echo -e "${YELLOW}尝试: make pack${NC}"
if make pack 2>&1 | tee pack.log; then
    PACK_SUCCESS=true
    echo -e "${GREEN}✓ make pack 成功${NC}"
fi

# 方法 2: make image
if [ "$PACK_SUCCESS" = false ]; then
    echo ""
    echo -e "${YELLOW}尝试: make image${NC}"
    if make image 2>&1 | tee pack.log; then
        PACK_SUCCESS=true
        echo -e "${GREEN}✓ make image 成功${NC}"
    fi
fi

# 方法 3: pack 脚本
if [ "$PACK_SUCCESS" = false ]; then
    PACK_SCRIPT=$(find . -name "pack" -o -name "pack.sh" | head -1)
    if [ -n "$PACK_SCRIPT" ] && [ -x "$PACK_SCRIPT" ]; then
        echo ""
        echo -e "${YELLOW}尝试: $PACK_SCRIPT${NC}"
        if $PACK_SCRIPT 2>&1 | tee pack.log; then
            PACK_SUCCESS=true
            echo -e "${GREEN}✓ pack 脚本成功${NC}"
        fi
    fi
fi

# 方法 4: 使用 tools/pack
if [ "$PACK_SUCCESS" = false ]; then
    if [ -d "tools/pack" ]; then
        echo ""
        echo -e "${YELLOW}尝试: tools/pack${NC}"
        cd tools/pack
        if ./pack -c v853 -p linux 2>&1 | tee "$SDK_PATH/pack.log"; then
            PACK_SUCCESS=true
            echo -e "${GREEN}✓ tools/pack 成功${NC}"
        fi
        cd "$SDK_PATH"
    fi
fi

echo ""

# ============ 步骤 4: 查找打包结果 ============
echo -e "${CYAN}[4/4] 查找打包结果${NC}"
echo ""

NEW_IMAGES=$(find "$SDK_PATH/out" \( -name "*.img" -o -name "*.fex" \) -type f -mmin -10 2>/dev/null || true)

if [ -n "$NEW_IMAGES" ]; then
    echo -e "${GREEN}✅ 找到新生成的镜像:${NC}"
    echo "$NEW_IMAGES" | while read img; do
        SIZE=$(ls -lh "$img" | awk '{print $5}')
        MTIME=$(stat -c '%y' "$img" 2>/dev/null || stat -f '%Sm' "$img")
        echo "  $img"
        echo "    大小: $SIZE"
        echo "    时间: $MTIME"
        echo ""
    done

    echo -e "${CYAN}📋 下一步:${NC}"
    echo "  1. 退出容器: exit"
    echo "  2. 复制镜像: ./start-docker.sh copy-image"
    echo "  3. 烧录到设备"
else
    echo -e "${YELLOW}⚠️  未找到新镜像${NC}"
    echo ""
    echo "可能的原因:"
    echo "  1. 打包失败，查看日志: cat $SDK_PATH/pack.log"
    echo "  2. 镜像位置不在 out/ 目录"
    echo ""
    echo "手动查找:"
    echo "  find /opt/v853_sdk -name '*.img' -mmin -10"
fi

echo ""
echo -e "${BLUE}════════════════════════════════════════${NC}"
