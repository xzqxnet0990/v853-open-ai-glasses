#!/bin/bash
#
# V853 固件编译工具 - 合并版本
# 包含：内核编译、固件打包、状态检查
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查是否在容器内
check_container() {
    if [ ! -d "/opt/v853_sdk" ]; then
        echo -e "${RED}错误: 请在 Docker 容器内运行${NC}"
        echo "使用: ./start-docker.sh shell"
        exit 1
    fi
}

SDK_PATH="/opt/v853_sdk"
KERNEL_PATH="$SDK_PATH/kernel/linux-4.9"

# ============ 功能：检查编译状态 ============
check_status() {
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}  编译状态检查${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo ""

    # 内核
    KERNEL_IMAGE="$KERNEL_PATH/arch/arm/boot/zImage"
    if [ -f "$KERNEL_IMAGE" ]; then
        SIZE=$(ls -lh "$KERNEL_IMAGE" | awk '{print $5}')
        echo -e "${GREEN}✓ 内核: $SIZE${NC}"
    else
        echo -e "${YELLOW}✗ 内核未编译${NC}"
    fi

    # 镜像
    IMG_COUNT=$(find "$SDK_PATH/out" \( -name "*.img" -o -name "*.fex" \) 2>/dev/null | wc -l)
    if [ $IMG_COUNT -gt 0 ]; then
        echo -e "${GREEN}✓ 镜像: $IMG_COUNT 个文件${NC}"
        find "$SDK_PATH/out" \( -name "*.img" -o -name "*.fex" \) 2>/dev/null | head -5 | while read f; do
            echo "  - $(basename $f) ($(ls -lh "$f" | awk '{print $5}'))"
        done
    else
        echo -e "${YELLOW}✗ 镜像未生成${NC}"
    fi

    echo ""
}

# ============ 功能：编译内核 ============
build_kernel() {
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}  编译内核${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo ""

    cd "$KERNEL_PATH"

    # 查找配置
    echo "查找内核配置..."
    DEFCONFIG=""
    for pattern in "v853" "sun8iw21" "100ask" "sunxi"; do
        FOUND=$(find arch/arm/configs -name "*${pattern}*defconfig" 2>/dev/null | head -1)
        if [ -n "$FOUND" ]; then
            DEFCONFIG=$(basename "$FOUND")
            echo -e "${GREEN}找到: $DEFCONFIG${NC}"
            break
        fi
    done

    if [ -z "$DEFCONFIG" ]; then
        DEFCONFIG=$(ls arch/arm/configs/*defconfig 2>/dev/null | head -1 | xargs basename)
        echo -e "${YELLOW}使用默认: $DEFCONFIG${NC}"
    fi

    # 清理并配置
    rm -f .config 2>/dev/null || true
    rm -rf include/config/* 2>/dev/null || true

    make ARCH=arm CROSS_COMPILE=arm-openwrt-linux- $DEFCONFIG

    # 禁用问题模块
    sed -i 's/^CONFIG_NETFILTER_XT_TARGET_TCPMSS=.*/# CONFIG_NETFILTER_XT_TARGET_TCPMSS is not set/' .config 2>/dev/null || true
    sed -i 's/^CONFIG_IP_NF_TARGET_MASQUERADE=.*/# CONFIG_IP_NF_TARGET_MASQUERADE is not set/' .config 2>/dev/null || true

    # 验证
    if ! grep -q "CONFIG_ARM=y" .config; then
        echo -e "${RED}错误: 配置不是 ARM 架构${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ 配置完成${NC}"
    echo ""

    # 编译
    JOBS=$(free -m | awk '/^Mem:/{if($2<4096) print 2; else if($2<8192) print 4; else print 8}')
    echo "使用 $JOBS 线程编译..."
    echo ""

    make ARCH=arm CROSS_COMPILE=arm-openwrt-linux- -j$JOBS zImage modules dtbs

    if [ -f "arch/arm/boot/zImage" ]; then
        echo ""
        echo -e "${GREEN}✅ 内核编译成功${NC}"
        ls -lh arch/arm/boot/zImage
    else
        echo -e "${RED}❌ 内核编译失败${NC}"
        exit 1
    fi
}

# ============ 功能：打包镜像 ============
pack_image() {
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo -e "${CYAN}  打包镜像${NC}"
    echo -e "${CYAN}════════════════════════════════════════${NC}"
    echo ""

    cd "$SDK_PATH"

    # 尝试不同的打包方法
    PACK_SUCCESS=false

    echo "尝试 make pack..."
    if make pack 2>&1 | tee pack.log; then
        PACK_SUCCESS=true
    fi

    if [ "$PACK_SUCCESS" = false ]; then
        echo "尝试 make image..."
        if make image 2>&1 | tee pack.log; then
            PACK_SUCCESS=true
        fi
    fi

    # 查找结果
    NEW_IMAGES=$(find "$SDK_PATH/out" \( -name "*.img" -o -name "*.fex" \) -type f -mmin -10 2>/dev/null)

    if [ -n "$NEW_IMAGES" ]; then
        echo ""
        echo -e "${GREEN}✅ 镜像打包成功${NC}"
        echo "$NEW_IMAGES" | while read img; do
            echo "  - $(basename $img) ($(ls -lh "$img" | awk '{print $5}'))"
        done
    else
        echo -e "${YELLOW}⚠️  未找到新镜像${NC}"
    fi
}

# ============ 主菜单 ============
show_menu() {
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}  V853 固件编译工具${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo ""
    echo "1. 检查编译状态"
    echo "2. 编译内核"
    echo "3. 打包镜像"
    echo "4. 完整流程（内核 + 打包）"
    echo "0. 退出"
    echo ""
}

# ============ 主程序 ============
main() {
    check_container

    if [ $# -eq 0 ]; then
        # 交互模式
        while true; do
            show_menu
            read -p "请选择 (0-4): " choice

            case $choice in
                1) check_status ;;
                2) build_kernel ;;
                3) pack_image ;;
                4) build_kernel && pack_image ;;
                0) echo "退出"; exit 0 ;;
                *) echo -e "${RED}无效选择${NC}" ;;
            esac

            echo ""
            read -p "按回车继续..."
            clear
        done
    else
        # 命令行模式
        case "$1" in
            status|check) check_status ;;
            kernel) build_kernel ;;
            pack) pack_image ;;
            all|full) build_kernel && pack_image ;;
            *)
                echo "用法: $0 [status|kernel|pack|all]"
                echo ""
                echo "  status  - 检查编译状态"
                echo "  kernel  - 编译内核"
                echo "  pack    - 打包镜像"
                echo "  all     - 完整流程"
                exit 1
                ;;
        esac
    fi
}

main "$@"
