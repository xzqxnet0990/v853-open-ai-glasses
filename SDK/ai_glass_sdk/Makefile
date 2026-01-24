# AI Glass SDK Makefile - V853 Platform
# 用于编译SDK库文件

# 交叉编译工具链 (V853)
ifeq ($(CROSS_COMPILE),)
CROSS_COMPILE = arm-openwrt-linux-
endif

CC = $(CROSS_COMPILE)gcc
AR = $(CROSS_COMPILE)ar
RANLIB = $(CROSS_COMPILE)ranlib

# 编译选项
CFLAGS = -Wall -g -O2 -fPIC
CFLAGS += -std=gnu99
CFLAGS += -D_GNU_SOURCE
CFLAGS += -DLINUX
CFLAGS += -DOS_LINUX
CFLAGS += -DV853_PLATFORM

# 目录定义
SRC_DIR = src
INC_DIR = include
LIB_DIR = lib

# 头文件路径
INCLUDES = -I$(INC_DIR)

# 库文件
LIBS = -lpthread -lrt

# 源文件（如果存在src目录）
SOURCES = $(wildcard $(SRC_DIR)/*.c)
OBJECTS = $(SOURCES:$(SRC_DIR)/%.c=$(LIB_DIR)/%.o)

# 预编译的对象文件
PRE_OBJECTS = $(wildcard $(LIB_DIR)/*.o)

# 库文件名称
STATIC_LIB = $(LIB_DIR)/libai_glass_sdk.a
SHARED_LIB = $(LIB_DIR)/libai_glass_sdk.so

# 版本信息
VERSION_FILE = VERSION
SDK_VERSION = v2.0.0-v853

# 默认目标
all: check_env info libs

# 检查环境
check_env:
	@echo "======================================="
	@echo "AI Glass SDK 构建系统 (V853 Platform)"
	@echo "======================================="
	@echo "编译器: $(CC)"
	@if ! command -v $(CC) >/dev/null 2>&1; then \
		echo ""; \
		echo "❌ 错误: V853交叉编译工具链未找到!"; \
		echo ""; \
		echo "需要: $(CROSS_COMPILE)gcc"; \
		echo ""; \
		echo "解决方案:"; \
		echo "  1. 在 Docker 环境中运行:"; \
		echo "     ./start-docker.sh shell"; \
		echo "     cd SDK/ai_glass_sdk"; \
		echo "     make"; \
		echo ""; \
		echo "  2. 或者设置工具链路径:"; \
		echo "     export PATH=/opt/v853_sdk/prebuilt/gcc/linux-x86/arm/toolchain-sunxi-musl/toolchain/bin:\$$PATH"; \
		echo ""; \
		echo "  3. 如果库文件已存在，可以直接使用 lib/ 目录下的库"; \
		echo ""; \
		exit 1; \
	fi
	@$(CC) --version 2>/dev/null | head -1
	@echo ""

# 显示信息
info:
	@if [ -f $(VERSION_FILE) ]; then \
		echo "版本信息:"; \
		cat $(VERSION_FILE); \
		echo ""; \
	fi
	@echo "目标平台: Allwinner V853"
	@echo "架构: ARM (musl)"
	@echo ""

# 构建库文件
libs: $(STATIC_LIB) $(SHARED_LIB)
	@echo ""
	@echo "✅ V853 SDK库构建完成!"
	@echo "  静态库: $(STATIC_LIB)"
	@echo "  动态库: $(SHARED_LIB)"
	@echo ""
	@echo "📝 提示:"
	@echo "  • 部署到V853设备: ./deploy.sh <device_ip>"
	@echo "  • 编译示例程序: make examples"
	@echo "  • 查看API文档: ls docs/"
	@echo ""

# 如果有源文件，从源文件编译
$(LIB_DIR)/%.o: $(SRC_DIR)/%.c
	@echo "编译: $<"
	@mkdir -p $(LIB_DIR)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

# 静态库
$(STATIC_LIB): check_sources $(OBJECTS)
	@echo "创建静态库: $@"
	@mkdir -p $(LIB_DIR)
ifeq ($(SOURCES),)
	@echo "使用预编译的对象文件..."
	@if [ -z "$(PRE_OBJECTS)" ]; then \
		echo "错误: 没有找到源文件或对象文件"; \
		exit 1; \
	fi
	$(AR) rcs $@ $(PRE_OBJECTS)
else
	$(AR) rcs $@ $(OBJECTS)
endif
	$(RANLIB) $@

# 动态库
$(SHARED_LIB): check_sources $(OBJECTS)
	@echo "创建动态库: $@"
	@mkdir -p $(LIB_DIR)
ifeq ($(SOURCES),)
	@echo "使用预编译的对象文件..."
	@if [ -z "$(PRE_OBJECTS)" ]; then \
		echo "错误: 没有找到源文件或对象文件"; \
		exit 1; \
	fi
	$(CC) -shared -o $@ $(PRE_OBJECTS) $(LIBS)
else
	$(CC) -shared -o $@ $(OBJECTS) $(LIBS)
endif

# 检查源文件
check_sources:
	@if [ ! -d $(SRC_DIR) ] && [ -z "$(PRE_OBJECTS)" ]; then \
		echo ""; \
		echo "⚠️  警告: 没有找到 $(SRC_DIR) 目录或预编译的对象文件"; \
		echo ""; \
		echo "此SDK可能为预编译版本，库文件已在 $(LIB_DIR) 目录"; \
		echo "如需从源码编译，请使用主项目的 src/sdk_adapter/ 目录"; \
		echo ""; \
	elif [ ! -d $(SRC_DIR) ] && [ -n "$(PRE_OBJECTS)" ]; then \
		echo ""; \
		echo "ℹ️  使用预编译对象文件重新构建库..."; \
		echo ""; \
	fi

# 清理
clean:
	@echo "清理构建产物..."
	@if [ -d $(SRC_DIR) ]; then \
		rm -f $(LIB_DIR)/*.o; \
	fi
	@echo "✅ 清理完成"

# 深度清理（包括库文件）
distclean: clean
	@echo "清理所有构建产物（包括库文件）..."
	rm -f $(STATIC_LIB) $(SHARED_LIB)
	@echo "✅ 深度清理完成"

# 安装到系统（可选）
install: libs
	@echo "安装V853 SDK到系统..."
	@if [ -z "$(DESTDIR)" ]; then \
		echo "错误: 请设置 DESTDIR 环境变量"; \
		echo "示例: make install DESTDIR=/usr"; \
		exit 1; \
	fi
	@mkdir -p $(DESTDIR)/include/ai_glass
	@mkdir -p $(DESTDIR)/lib
	@cp -r $(INC_DIR)/* $(DESTDIR)/include/ai_glass/
	@cp $(STATIC_LIB) $(SHARED_LIB) $(DESTDIR)/lib/
	@echo "✅ 安装完成: $(DESTDIR)"
	@echo ""
	@echo "使用方法:"
	@echo "  gcc app.c -I$(DESTDIR)/include/ai_glass -L$(DESTDIR)/lib -lai_glass_sdk"
	@echo ""

# 编译示例程序
examples: libs
	@echo ""
	@echo "编译V853示例程序..."
	@for dir in examples/*/; do \
		if [ -f "$$dir/Makefile" ]; then \
			echo ""; \
			echo "构建: $$dir"; \
			$(MAKE) -C $$dir CROSS_COMPILE=$(CROSS_COMPILE) || exit 1; \
		fi; \
	done
	@echo ""
	@echo "✅ 所有示例程序编译完成"
	@echo ""
	@echo "测试示例:"
	@echo "  # 部署到V853设备"
	@echo "  scp examples/gpio_example/gpio_test root@192.168.1.100:/usr/bin/"
	@echo "  scp examples/camera_capture_example/camera_test root@192.168.1.100:/usr/bin/"
	@echo ""
	@echo "  # 在设备上运行"
	@echo "  ssh root@192.168.1.100"
	@echo "  /usr/bin/gpio_test"
	@echo ""

# 清理示例程序
clean-examples:
	@echo "清理示例程序..."
	@for dir in examples/*/; do \
		if [ -f "$$dir/Makefile" ]; then \
			$(MAKE) -C $$dir clean; \
		fi; \
	done
	@echo "✅ 示例程序清理完成"

# 测试（编译并运行示例）
test: examples
	@echo ""
	@echo "⚠️  注意: 测试需要在V853设备上运行"
	@echo ""
	@echo "测试步骤:"
	@echo "  1. 部署库和示例到设备"
	@echo "  2. 在设备上运行测试"
	@echo ""
	@echo "快速测试命令:"
	@echo "  ./deploy.sh 192.168.1.100"
	@echo "  ssh root@192.168.1.100"
	@echo "  /usr/bin/examples/camera_test"
	@echo ""

# 构建文档
docs:
	@echo "📚 生成API文档..."
	@echo ""
	@echo "可用文档:"
	@ls -1 docs/*.md
	@echo ""
	@echo "查看文档:"
	@echo "  cat docs/GPIO_Client_API.md"
	@echo "  cat docs/Camera_Client_API.md"
	@echo ""

# 打包发布
package: distclean libs examples
	@echo "📦 打包V853 SDK..."
	@mkdir -p release
	@tar -czf release/ai_glass_sdk_v853_$(SDK_VERSION).tar.gz \
		include/ lib/ examples/ docs/ README.md README.en.md VERSION Makefile
	@echo ""
	@echo "✅ 打包完成: release/ai_glass_sdk_v853_$(SDK_VERSION).tar.gz"
	@echo ""
	@du -h release/ai_glass_sdk_v853_$(SDK_VERSION).tar.gz
	@echo ""

# 帮助信息
help:
	@echo "AI Glass SDK Makefile (V853 Platform)"
	@echo ""
	@echo "使用方法:"
	@echo "  make              - 构建SDK库文件"
	@echo "  make libs         - 构建静态库和动态库"
	@echo "  make examples     - 编译所有示例程序"
	@echo "  make clean        - 清理构建产物（保留库文件）"
	@echo "  make distclean    - 清理所有构建产物（包括库文件）"
	@echo "  make clean-examples - 清理示例程序"
	@echo "  make install      - 安装SDK到系统（需设置DESTDIR）"
	@echo "  make test         - 测试SDK（需在V853设备上运行）"
	@echo "  make docs         - 显示可用文档"
	@echo "  make package      - 打包发布版本"
	@echo "  make help         - 显示此帮助信息"
	@echo ""
	@echo "环境变量:"
	@echo "  CROSS_COMPILE   - 交叉编译工具链前缀（默认: arm-openwrt-linux-）"
	@echo "  DESTDIR         - 安装目标目录"
	@echo ""
	@echo "示例:"
	@echo "  make                                    # 构建库"
	@echo "  make examples                           # 编译所有示例"
	@echo "  make install DESTDIR=/usr               # 安装到/usr"
	@echo "  make package                            # 打包发布"
	@echo ""
	@echo "V853平台特性:"
	@echo "  • 工具链: arm-openwrt-linux-gcc (Tina Linux)"
	@echo "  • 目标: DongshanPI-AICT V853开发板"
	@echo "  • 接口: V4L2 (摄像头), GPIO sysfs, ALSA (音频)"
	@echo ""
	@echo "Docker环境:"
	@echo "  cd ../../"
	@echo "  ./start-docker.sh start"
	@echo "  ./start-docker.sh shell"
	@echo "  cd SDK/ai_glass_sdk && make"
	@echo ""

# 显示版本信息
version:
	@if [ -f $(VERSION_FILE) ]; then \
		cat $(VERSION_FILE); \
	else \
		echo "版本: $(SDK_VERSION)"; \
		echo "平台: Allwinner V853"; \
	fi

.PHONY: all check_env info libs clean distclean install examples clean-examples test help check_sources version docs package
