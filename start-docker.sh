#!/bin/bash
# V853 AI Glasses 开发环境启动脚本
# 基于 docker-compose 管理开发容器

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置
IMAGE_NAME="aiglasses/v853-dev:v1.0.0"
CONTAINER_NAME="v853_ai_glasses_dev"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"

# SDK目录路径
SDK_DIR="${PROJECT_DIR}/SDK/tina-v853-open"

# 帮助信息
show_help() {
    cat << EOF
${GREEN}╔══════════════════════════════════════════════════════════╗
║     V853 AI Glasses 开发环境管理脚本 v1.0.0              ║
╚══════════════════════════════════════════════════════════╝${NC}

${CYAN}📁 目录挂载:${NC}
  • 项目源码: ${PROJECT_DIR} → /workspace
  • V853 SDK:  ${SDK_DIR} → /opt/v853_sdk
  • 编译缓存:  Docker volume → /workspace/.build-cache
  • 编译输出:  Docker volume → /workspace/output

${CYAN}🎯 用法:${NC}
  $0 [命令]

${CYAN}📋 容器管理命令:${NC}
  ${GREEN}start${NC}           启动开发容器
  ${GREEN}stop${NC}            停止容器
  ${GREEN}restart${NC}         重启容器
  ${GREEN}shell${NC}           进入容器Shell
  ${GREEN}logs${NC}            查看容器日志
  ${GREEN}clean${NC}           删除容器（保留镜像）
  ${GREEN}clean-all${NC}       删除容器和镜像
  ${GREEN}status${NC}          查看容器状态

${CYAN}🔨 编译命令:${NC}
  ${GREEN}build-sdk${NC}       编译SDK适配层
  ${GREEN}build-app${NC}       编译应用层 (Qt+FFmpeg+GPIO)
  ${GREEN}build-all${NC}       编译所有组件 (SDK+应用)
  ${GREEN}build-firmware${NC}  编译完整固件镜像 (.img)

${CYAN}🧪 测试命令:${NC}
  ${GREEN}test-camera${NC}     测试摄像头功能
  ${GREEN}test-audio${NC}      测试音频功能
  ${GREEN}test-gpio${NC}       测试GPIO功能

${CYAN}🧹 清理命令:${NC}
  ${GREEN}clean-build${NC}     清理编译产物
  ${GREEN}clean-cache${NC}     清理Docker缓存

${CYAN}📦 部署命令:${NC}
  ${GREEN}deploy-ssh${NC}      通过SSH部署到设备
  ${GREEN}deploy-adb${NC}      通过ADB部署到设备
  ${GREEN}copy-image${NC}      复制固件镜像到主机

${CYAN}🛠️  开发辅助:${NC}
  ${GREEN}info${NC}            显示环境信息
  ${GREEN}toolchain${NC}       显示工具链信息
  ${GREEN}help${NC}            显示此帮助信息

${CYAN}💡 示例:${NC}
  ${BLUE}# 启动开发环境${NC}
  $0 start

  ${BLUE}# 进入容器${NC}
  $0 shell

  ${BLUE}# 编译所有组件${NC}
  $0 build-all

  ${BLUE}# 编译固件镜像${NC}
  $0 build-firmware

  ${BLUE}# 部署到设备${NC}
  $0 deploy-ssh 192.168.1.100

${YELLOW}⚠️  注意事项:${NC}
  1. 首次启动会自动构建Docker镜像（需要几分钟）
  2. 确保 SDK/tina-v853-open 目录存在且完整
  3. 固件编译需要20-40分钟，请耐心等待
  4. 编译产物会保存在Docker volume中，不会占用主机空间

${CYAN}📚 更多信息:${NC}
  README.md          - 项目概述
  QUICK_START.md     - 快速入门指南
  PROJECT_STATUS.md  - 开发进度

EOF
}

# 显示Banner
show_banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║     🤓  V853 AI Glasses Development Environment  👓        ║
║                                                          ║
║          基于 Allwinner V853 SoC 的智能眼镜              ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# 检查Docker和docker-compose
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}❌ 错误: 未检测到Docker${NC}"
        echo -e "${YELLOW}请先安装Docker: https://docs.docker.com/get-docker/${NC}"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        echo -e "${RED}❌ 错误: 未检测到docker-compose${NC}"
        echo -e "${YELLOW}请先安装docker-compose: https://docs.docker.com/compose/install/${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ Docker 检查通过${NC}"
}

# 检查SDK目录
check_sdk() {
    if [ ! -d "$SDK_DIR" ]; then
        echo -e "${RED}❌ 错误: V853 SDK目录不存在: $SDK_DIR${NC}"
        echo -e "${YELLOW}解决方案:${NC}"
        echo "  1. 确保已解压 tina-v853-open SDK"
        echo "  2. SDK应位于: SDK/tina-v853-open/"
        echo "  3. 或修改脚本中的 SDK_DIR 变量"
        exit 1
    fi

    # 检查SDK关键文件
    local key_files=(
        "$SDK_DIR/build.sh"
    )

    for file in "${key_files[@]}"; do
        if [ ! -e "$file" ]; then
            echo -e "${RED}❌ 错误: SDK不完整，缺少: $(basename $file)${NC}"
            exit 1
        fi
    done

    # 检查工具链 (支持多种可能的路径)
    local toolchain_found=false
    local toolchain_paths=(
        "$SDK_DIR/prebuilt/gcc/linux-x86/arm/toolchain-sunxi-musl"
        "$SDK_DIR/prebuilt/rootfsbuilt/arm/toolchain-sunxi-musl-gcc-830"
        "$SDK_DIR/prebuilt/rootfsbuilt/arm/toolchain-sunxi-glibc-gcc-830"
    )

    for toolchain_path in "${toolchain_paths[@]}"; do
        if [ -d "$toolchain_path" ]; then
            toolchain_found=true
            echo -e "${GREEN}✓ 找到工具链: $(basename $toolchain_path)${NC}"
            break
        fi
    done

    if [ "$toolchain_found" = false ]; then
        echo -e "${RED}❌ 错误: 找不到V853工具链${NC}"
        echo -e "${YELLOW}提示: 请检查SDK是否完整解压${NC}"
        exit 1
    fi

    echo -e "${GREEN}✓ SDK目录检查通过${NC}"
}

# 使用docker-compose命令
compose_cmd() {
    if command -v docker-compose &> /dev/null; then
        docker-compose "$@"
    else
        docker compose "$@"
    fi
}

# 启动容器
start_container() {
    show_banner
    echo -e "${GREEN}🚀 启动V853开发容器...${NC}"
    echo ""

    check_sdk

    # 检查镜像是否存在
    if docker images | grep -q "aiglasses/v853-dev"; then
        echo -e "${GREEN}✓ 发现已有镜像，直接启动容器...${NC}"
        compose_cmd up -d
    else
        echo -e "${BLUE}首次启动，构建Docker镜像（需要几分钟）...${NC}"
        compose_cmd up -d --build
    fi

    echo ""
    echo -e "${GREEN}✅ 容器启动成功！${NC}"
    echo ""
    echo -e "${CYAN}下一步:${NC}"
    echo -e "  ${GREEN}$0 shell${NC}       - 进入容器Shell"
    echo -e "  ${GREEN}$0 build-all${NC}   - 编译所有组件"
    echo -e "  ${GREEN}$0 info${NC}        - 查看环境信息"
}

# 停止容器
stop_container() {
    echo -e "${YELLOW}⏹️  停止容器...${NC}"
    compose_cmd stop
    echo -e "${GREEN}✅ 容器已停止${NC}"
}

# 重启容器
restart_container() {
    echo -e "${YELLOW}🔄 重启容器...${NC}"
    compose_cmd restart
    echo -e "${GREEN}✅ 容器已重启${NC}"
}

# 进入容器Shell
enter_shell() {
    echo -e "${GREEN}🐚 进入容器Shell...${NC}"
    echo -e "${CYAN}工作目录: /workspace${NC}"
    echo -e "${CYAN}SDK目录:  /opt/v853_sdk${NC}"
    echo ""
    compose_cmd exec v853-dev bash -l
}

# 查看日志
show_logs() {
    compose_cmd logs -f v853-dev
}

# 删除容器
clean_container() {
    echo -e "${YELLOW}🧹 删除容器...${NC}"
    compose_cmd down
    echo -e "${GREEN}✅ 容器已删除${NC}"
}

# 删除容器和镜像
clean_all() {
    echo -e "${YELLOW}🧹 删除容器、镜像和卷...${NC}"
    read -p "确认删除所有内容? (y/N): " confirm
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        compose_cmd down --rmi all --volumes
        echo -e "${GREEN}✅ 已删除所有内容${NC}"
    else
        echo "已取消"
    fi
}

# 查看状态
show_status() {
    echo -e "${CYAN}📊 容器状态:${NC}"
    compose_cmd ps
}

# 确保容器运行
ensure_running() {
    if ! compose_cmd ps | grep -q "Up"; then
        echo -e "${YELLOW}容器未运行，正在启动...${NC}"
        start_container
        sleep 2
    fi
}

# 编译SDK适配层
build_sdk() {
    echo -e "${GREEN}🔨 编译SDK适配层...${NC}"
    ensure_running
    compose_cmd exec v853-dev bash -l -c "
        cd /workspace
        make sdk
    "
}

# 编译应用层
build_app() {
    echo -e "${GREEN}🔨 编译应用层...${NC}"
    ensure_running
    compose_cmd exec v853-dev bash -l -c "
        cd /workspace
        make app
    "
}

# 编译所有组件
build_all() {
    echo -e "${GREEN}🔨 编译所有组件...${NC}"
    ensure_running
    compose_cmd exec v853-dev bash -l -c "
        cd /workspace
        make all
    "
}

# 编译固件
build_firmware() {
    echo -e "${GREEN}🔨 编译完整固件镜像...${NC}"
    echo -e "${YELLOW}⚠️  警告: 固件编译需要20-40分钟${NC}"
    read -p "确认继续? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "已取消"
        return
    fi

    ensure_running

    echo -e "${BLUE}开始编译固件...${NC}"
    compose_cmd exec v853-dev bash -l -c "
        cd /opt/v853_sdk

        # 配置环境
        source build/envsetup.sh

        # 选择配置（根据实际板型调整）
        lunch v853-100ask-tina

        # 编译
        ./build.sh

        echo ''
        echo '${GREEN}✅ 固件编译完成！${NC}'
        echo '${CYAN}输出目录: /opt/v853_sdk/out/v853/100ask/image/${NC}'
        ls -lh /opt/v853_sdk/out/v853/100ask/image/*.img /opt/v853_sdk/out/v853/100ask/image/*.fex 2>/dev/null || true
    "

    echo ""
    echo -e "${CYAN}提示: 使用 '$0 copy-image' 复制固件到主机${NC}"
}

# 测试摄像头
test_camera() {
    echo -e "${GREEN}🧪 测试摄像头功能...${NC}"
    ensure_running
    compose_cmd exec v853-dev bash -l -c "
        cd /workspace/src/sdk_adapter/build/examples
        ./camera_test
    "
}

# 测试音频
test_audio() {
    echo -e "${GREEN}🧪 测试音频功能...${NC}"
    ensure_running
    compose_cmd exec v853-dev bash -l -c "
        cd /workspace/src/sdk_adapter/build/examples
        ./audio_test /tmp/test.pcm
    "
}

# 测试GPIO
test_gpio() {
    echo -e "${GREEN}🧪 测试GPIO功能...${NC}"
    ensure_running
    compose_cmd exec v853-dev bash -l -c "
        cd /workspace/src/sdk_adapter/build/examples
        ./gpio_test
    "
}

# 清理编译产物
clean_build() {
    echo -e "${YELLOW}🧹 清理编译产物...${NC}"
    ensure_running
    compose_cmd exec v853-dev bash -l -c "
        cd /workspace
        make clean
    "
    echo -e "${GREEN}✅ 清理完成${NC}"
}

# 清理Docker缓存
clean_cache() {
    echo -e "${YELLOW}🧹 清理Docker缓存...${NC}"
    docker system prune -f
    echo -e "${GREEN}✅ 缓存清理完成${NC}"
}

# 通过SSH部署
deploy_ssh() {
    local device_ip=$1
    if [ -z "$device_ip" ]; then
        echo -e "${RED}❌ 错误: 请指定设备IP地址${NC}"
        echo -e "${YELLOW}用法: $0 deploy-ssh <IP地址>${NC}"
        echo -e "${YELLOW}示例: $0 deploy-ssh 192.168.1.100${NC}"
        exit 1
    fi

    echo -e "${GREEN}📦 通过SSH部署到 $device_ip...${NC}"
    ensure_running
    compose_cmd exec v853-dev bash -l -c "
        cd /workspace
        ./deploy.sh $device_ip
    "
}

# 通过ADB部署
deploy_adb() {
    echo -e "${GREEN}📦 通过ADB部署...${NC}"
    ensure_running
    compose_cmd exec v853-dev bash -l -c "
        cd /workspace
        ./deploy.sh adb
    "
}

# 复制固件镜像
copy_image() {
    echo -e "${GREEN}📤 复制固件镜像到主机...${NC}"

    local output_dir="$PROJECT_DIR/output"
    mkdir -p "$output_dir"

    # 可能的镜像路径列表
    local image_paths=(
        "/opt/v853_sdk/out/v853/100ask/image"
        "/opt/v853_sdk/out/v853/vision/image"
        "/opt/v853_sdk/out/v853/image"
    )

    local found=false

    # 遍历所有可能的路径
    for base_path in "${image_paths[@]}"; do
        echo -e "${CYAN}检查路径: $base_path${NC}"

        # 查找该路径下的所有 .img 和 .fex 文件
        compose_cmd exec v853-dev bash -c "
            if [ -d '$base_path' ]; then
                find '$base_path' -maxdepth 1 \( -name '*.img' -o -name '*.fex' \) -type f
            fi
        " 2>/dev/null | while read -r remote_file; do
            if [ -n "$remote_file" ]; then
                local filename=$(basename "$remote_file")
                echo -e "${BLUE}正在复制: $filename${NC}"
                docker cp "$CONTAINER_NAME:$remote_file" "$output_dir/" 2>/dev/null && \
                    echo -e "${GREEN}  ✓ $filename${NC}" && \
                    found=true
            fi
        done
    done

    # 显示复制结果
    if [ -d "$output_dir" ] && [ "$(ls -A $output_dir 2>/dev/null)" ]; then
        echo ""
        echo -e "${GREEN}✅ 固件文件已复制到: $output_dir/${NC}"
        ls -lh "$output_dir"/*.img "$output_dir"/*.fex 2>/dev/null || true
    else
        echo ""
        echo -e "${YELLOW}⚠️  未找到固件镜像文件${NC}"
        echo -e "${CYAN}提示: 检查以下位置:${NC}"
        compose_cmd exec v853-dev bash -c "
            find /opt/v853_sdk/out -name '*.img' -o -name '*.fex' 2>/dev/null | head -10
        " || true
    fi
}

# 显示环境信息
show_info() {
    echo -e "${CYAN}📋 V853开发环境信息${NC}"
    echo ""
    ensure_running
    compose_cmd exec v853-dev bash -l -c "
        echo '${CYAN}=== 系统信息 ===${NC}'
        uname -a
        echo ''

        echo '${CYAN}=== 工具链信息 ===${NC}'
        if [ -f /opt/v853_sdk/prebuilt/gcc/linux-x86/arm/toolchain-sunxi-musl/toolchain/bin/arm-openwrt-linux-gcc ]; then
            /opt/v853_sdk/prebuilt/gcc/linux-x86/arm/toolchain-sunxi-musl/toolchain/bin/arm-openwrt-linux-gcc --version | head -1
        else
            echo '⚠️  工具链未找到'
        fi
        echo ''

        echo '${CYAN}=== 目录信息 ===${NC}'
        echo 'SDK目录: /opt/v853_sdk'
        ls -d /opt/v853_sdk 2>/dev/null && echo '  ✓ 已挂载' || echo '  ✗ 未挂载'
        echo '项目目录: /workspace'
        ls -d /workspace 2>/dev/null && echo '  ✓ 已挂载' || echo '  ✗ 未挂载'
        echo ''

        echo '${CYAN}=== 编译状态 ===${NC}'
        [ -f /workspace/src/sdk_adapter/build/libai_glass_sdk_v853.so ] && \
            echo '  ✓ SDK适配层已编译' || echo '  ✗ SDK适配层未编译'
        [ -f /workspace/src/display_lvgl/build-v853/AIGlassesDisplayLVGL ] && \
            echo '  ✓ LVGL应用已编译' || echo '  ✗ LVGL应用未编译'
    "
}

# 显示工具链信息
show_toolchain() {
    echo -e "${CYAN}🔧 工具链信息${NC}"
    ensure_running
    compose_cmd exec v853-dev bash -l -c "
        echo '${CYAN}=== 编译器 ===${NC}'
        arm-openwrt-linux-gcc --version 2>/dev/null || echo '未找到'
        echo ''

        echo '${CYAN}=== CMake ===${NC}'
        cmake --version | head -1
        echo ''

        echo '${CYAN}=== Python ===${NC}'
        python3 --version
    "
}

# 主函数
main() {
    # 必须在项目根目录运行
    if [ ! -f "$PROJECT_DIR/docker-compose.yml" ]; then
        echo -e "${RED}❌ 错误: 请在项目根目录运行此脚本${NC}"
        exit 1
    fi

    check_docker

    case "${1:-help}" in
        # 容器管理
        start)
            start_container
            ;;
        stop)
            stop_container
            ;;
        restart)
            restart_container
            ;;
        shell)
            enter_shell
            ;;
        logs)
            show_logs
            ;;
        clean)
            clean_container
            ;;
        clean-all)
            clean_all
            ;;
        status)
            show_status
            ;;

        # 编译命令
        build-sdk|make-sdk)
            build_sdk
            ;;
        build-app|make-app)
            build_app
            ;;
        build-all|make-all)
            build_all
            ;;
        build-firmware|make-firmware)
            build_firmware
            ;;

        # 测试命令
        test-camera)
            test_camera
            ;;
        test-audio)
            test_audio
            ;;
        test-gpio)
            test_gpio
            ;;

        # 清理命令
        clean-build)
            clean_build
            ;;
        clean-cache)
            clean_cache
            ;;

        # 部署命令
        deploy-ssh)
            deploy_ssh "$2"
            ;;
        deploy-adb)
            deploy_adb
            ;;
        copy-image)
            copy_image
            ;;

        # 辅助命令
        info)
            show_info
            ;;
        toolchain)
            show_toolchain
            ;;
        help|--help|-h)
            show_help
            ;;

        *)
            echo -e "${RED}❌ 错误: 未知命令 '$1'${NC}"
            echo ""
            show_help
            exit 1
            ;;
    esac
}

main "$@"
