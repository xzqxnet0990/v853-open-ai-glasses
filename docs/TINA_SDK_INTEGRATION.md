# Tina SDK Integration Guide - V853 AI Glasses

**目标**: 将 `src/` 和 `SDK/ai_glass_sdk/` 目录集成到 Tina SDK 构建系统

**日期**: 2026-01-23

---

## 📋 概述

### 问题

用户询问: `tina-v853-open/build.sh` 是否需要修改以包含以下目录:
- `/path/to/v853-ai-glasses/src`
- `/path/to/v853-ai-glasses/SDK/ai_glass_sdk`

### 答案

**不需要直接修改 build.sh**。正确的做法是:

1. **在 OpenWrt 包系统中创建自定义包** (推荐)
2. **或者**使用 overlay 机制部署预编译二进制文件 (快速)

---

## 🎯 推荐方案: OpenWrt 包系统集成

### Tina SDK 构建系统架构

```
tina-v853-open/
├── build.sh                    # 构建入口 (不需要修改)
│   └─> build/mkcommon.sh       # 实际构建脚本
│       └─> make                # OpenWrt Makefile 系统
│
├── openwrt/
│   ├── package/
│   │   ├── allwinner/          # Allwinner 自定义包
│   │   │   ├── audio/
│   │   │   ├── display/
│   │   │   ├── power/
│   │   │   └── **ai-glasses/** ← 我们在这里创建包
│   │   ├── feeds/              # 第三方包
│   │   └── thirdparty/
│   │
│   └── target/v853/
│       └── v853-100ask/        # 我们的目标设备配置
│           └── defconfig       # 包选择配置
│
└── buildroot/
    └── (rootfs 构建系统)
```

### 工作原理

1. **build.sh** 调用 OpenWrt 构建系统
2. **OpenWrt** 读取 `openwrt/package/` 下的所有包定义
3. **target defconfig** 决定哪些包被包含到固件中
4. **每个包的 Makefile** 定义如何编译和安装该包

---

## 🚀 实施步骤

### 步骤 1: 创建 AI Glasses 包结构

```bash
cd SDK/tina-v853-open/openwrt/package/allwinner
mkdir -p ai-glasses/ai-glass-sdk
mkdir -p ai-glasses/system-services
```

目录结构:
```
openwrt/package/allwinner/ai-glasses/
├── ai-glass-sdk/           # SDK 适配层包
│   ├── Makefile            # OpenWrt 包定义
│   ├── Config.in           # 配置选项
│   └── files/              # 附加文件(启动脚本等)
│
└── system-services/        # 系统服务包
    ├── Makefile
    ├── Config.in
    └── files/
        └── S99aiglasses    # Init 脚本
```

### 步骤 2: 创建 SDK 包 Makefile

**文件**: `openwrt/package/allwinner/ai-glasses/ai-glass-sdk/Makefile`

```makefile
include $(TOPDIR)/rules.mk

PKG_NAME:=ai-glass-sdk
PKG_VERSION:=2.0.0
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

# 指向我们的源代码目录 (外部)
SRC_CODE_DIR := $(TOPDIR)/../../src/sdk_adapter
SDK_INCLUDE_DIR := $(TOPDIR)/../../SDK/ai_glass_sdk/include

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/ai-glass-sdk
  SUBMENU:=AI Glasses
  SECTION:=allwinner
  CATEGORY:=Allwinner
  TITLE:=AI Glass SDK for V853
  DEPENDS:=+libpthread +librt
  DEFAULT:=y
endef

define Package/ai-glass-sdk/description
	AI Glass SDK adapter layer for V853 platform
	Provides GPIO, Camera (V4L2), and Audio (ALSA) interfaces
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) $(SRC_CODE_DIR)/* $(PKG_BUILD_DIR)/
endef

define Build/Configure
	cd $(PKG_BUILD_DIR) && \
	$(CMAKE) \
		-DCMAKE_TOOLCHAIN_FILE=$(PKG_BUILD_DIR)/toolchain-v853.cmake \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_BUILD_TYPE=Release \
		.
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CROSS_COMPILE=$(TARGET_CROSS) \
		CFLAGS="$(TARGET_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)"
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_DIR) $(1)/usr/include
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/build/*.so $(1)/usr/lib/
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/build/*.a $(1)/usr/lib/
	$(CP) $(SDK_INCLUDE_DIR)/* $(1)/usr/include/
endef

define Package/ai-glass-sdk/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/build/*.so $(1)/usr/lib/
	# 安装测试程序
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/examples/build/* $(1)/usr/bin/
endef

$(eval $(call BuildPackage,ai-glass-sdk))
```

### 步骤 3: 创建系统服务包 Makefile

**文件**: `openwrt/package/allwinner/ai-glasses/system-services/Makefile`

```makefile
include $(TOPDIR)/rules.mk

PKG_NAME:=ai-glass-services
PKG_VERSION:=2.0.0
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

SRC_CODE_DIR := $(TOPDIR)/../../src/system_services
SDK_LIB_DIR := $(TOPDIR)/../../SDK/ai_glass_sdk/lib

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/ai-glass-services
  SUBMENU:=AI Glasses
  SECTION:=allwinner
  CATEGORY:=Allwinner
  TITLE:=AI Glasses System Services
  DEPENDS:=+ai-glass-sdk +libpthread +librt
  DEFAULT:=y
endef

define Package/ai-glass-services/description
	System services for AI Glasses:
	- ai-core: GPIO/Camera/Audio service
	- power_manager: Power monitoring
	- log_daemon: Log collection
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) $(SRC_CODE_DIR)/* $(PKG_BUILD_DIR)/
endef

define Build/Configure
	cd $(PKG_BUILD_DIR) && \
	$(CMAKE) \
		-DCMAKE_TOOLCHAIN_FILE=$(PKG_BUILD_DIR)/toolchain-v853.cmake \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_BUILD_TYPE=Release \
		.
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
		CROSS_COMPILE=$(TARGET_CROSS) \
		CFLAGS="$(TARGET_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)"
endef

define Package/ai-glass-services/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/var/log/ai_glasses

	# 安装服务二进制
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/build/bin/* $(1)/usr/bin/

	# 安装启动脚本
	$(INSTALL_BIN) ./files/S99aiglasses $(1)/etc/init.d/S99aiglasses
endef

$(eval $(call BuildPackage,ai-glass-services))
```

### 步骤 4: 创建应用程序包

**文件**: `openwrt/package/allwinner/ai-glasses/display-qt/Makefile`

```makefile
include $(TOPDIR)/rules.mk

PKG_NAME:=ai-glass-display
PKG_VERSION:=2.0.0
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

SRC_CODE_DIR := $(TOPDIR)/../../src/display_qt

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/ai-glass-display
  SUBMENU:=AI Glasses
  SECTION:=allwinner
  CATEGORY:=Allwinner
  TITLE:=AI Glasses Qt Display Application
  DEPENDS:=+ai-glass-sdk +qt5-core +qt5-gui +qt5-widgets
  DEFAULT:=y
endef

define Package/ai-glass-display/description
	Qt5-based display application for AI Glasses
	Supports MIPI DSI 1280x720 display
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) $(SRC_CODE_DIR)/* $(PKG_BUILD_DIR)/
endef

define Build/Configure
	cd $(PKG_BUILD_DIR) && \
	$(CMAKE) \
		-DCMAKE_TOOLCHAIN_FILE=$(PKG_BUILD_DIR)/toolchain-v853.cmake \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_BUILD_TYPE=Release \
		.
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR)
endef

define Package/ai-glass-display/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/AIGlassesDisplay $(1)/usr/bin/
endef

$(eval $(call BuildPackage,ai-glass-display))
```

### 步骤 5: 将包添加到设备配置

**修改**: `openwrt/target/v853/v853-100ask/defconfig`

在文件末尾添加:

```makefile
# AI Glasses Packages
CONFIG_PACKAGE_ai-glass-sdk=y
CONFIG_PACKAGE_ai-glass-services=y
CONFIG_PACKAGE_ai-glass-display=y
```

### 步骤 6: 构建固件

```bash
cd SDK/tina-v853-open

# 1. 加载环境变量
source build/envsetup.sh

# 2. 选择目标设备
lunch v853-100ask-tina

# 3. 配置包 (可选，检查我们的包是否被选中)
make menuconfig
# 导航到: Allwinner > AI Glasses
# 确认所有包已选中

# 4. 编译固件
./build.sh

# 或者只编译我们的包
make package/allwinner/ai-glasses/ai-glass-sdk/compile V=s
make package/allwinner/ai-glasses/system-services/compile V=s
make package/allwinner/ai-glasses/display-qt/compile V=s

# 5. 重新打包固件
./build.sh pack
```

输出文件: `out/v853/image/tina_v853-100ask_uart0.img`

---

## 🔄 方案对比

### 方案 A: OpenWrt 包系统 (推荐)

**优点**:
- ✅ 完全集成到 Tina 构建流程
- ✅ 依赖管理自动化
- ✅ 符合 Tina SDK 最佳实践
- ✅ 便于版本控制和维护
- ✅ 自动处理交叉编译环境

**缺点**:
- ⏱ 初始设置需要创建 Makefile
- 📚 需要了解 OpenWrt 包系统

**适用场景**: 正式项目、长期维护、需要发布

### 方案 B: Overlay 机制 (快速测试)

**创建 overlay 目录**:

```bash
mkdir -p SDK/tina-v853-open/openwrt/target/v853/v853-100ask/overlay/usr/bin
mkdir -p SDK/tina-v853-open/openwrt/target/v853/v853-100ask/overlay/usr/lib
mkdir -p SDK/tina-v853-open/openwrt/target/v853/v853-100ask/overlay/etc/init.d

# 复制预编译文件
cp src/sdk_adapter/build/*.so openwrt/target/v853/v853-100ask/overlay/usr/lib/
cp src/display_qt/build/AIGlassesDisplay openwrt/target/v853/v853-100ask/overlay/usr/bin/
cp src/system_services/init/S99aiglasses openwrt/target/v853/v853-100ask/overlay/etc/init.d/

# 构建固件
./build.sh
```

**优点**:
- ⚡ 快速部署
- 🔧 适合快速测试
- 💡 无需创建复杂 Makefile

**缺点**:
- ❌ 不符合 Tina 标准
- ❌ 依赖管理手动
- ❌ 难以维护和升级

**适用场景**: 开发调试、快速验证

### 方案 C: 外部编译 + 手动部署 (当前方式)

**保持现状**:

```bash
# 在项目根目录编译
./start-docker.sh build-all

# 手动部署到设备
./start-docker.sh deploy-ssh 192.168.1.100
```

**优点**:
- 🎯 开发灵活
- 🔍 便于调试
- 🚀 快速迭代

**缺点**:
- ❌ 不包含在固件镜像中
- ❌ 每次刷机后需要重新部署
- ❌ 生产环境不适用

**适用场景**: 开发阶段、功能验证

---

## 📝 推荐流程

### 阶段 1: 开发调试 (当前阶段)

使用**方案 C (外部编译)**:

```bash
# 在 v853-ai-glasses/ 目录
./start-docker.sh build-all
./start-docker.sh deploy-ssh <device-ip>
```

### 阶段 2: 集成测试

使用**方案 B (Overlay)**:

```bash
# 快速将编译好的文件打包到固件
cp build/* SDK/tina-v853-open/openwrt/target/v853/v853-100ask/overlay/
cd SDK/tina-v853-open
./build.sh
```

### 阶段 3: 生产发布

使用**方案 A (OpenWrt 包)**:

```bash
# 创建正式的包定义
# 包含在 Tina SDK 构建中
cd SDK/tina-v853-open
./build.sh
```

---

## 🎯 结论

### 直接回答用户问题:

**Q**: `build.sh` 是否需要修改以包含 `src/` 和 `SDK/ai_glass_sdk/`?

**A**: **不需要修改 build.sh**。正确的做法是:

1. **开发阶段** (当前): 使用 `v853-ai-glasses/` 下的独立构建系统 (start-docker.sh)
   - 编译: `./start-docker.sh build-all`
   - 部署: `./start-docker.sh deploy-ssh <ip>`
   - **优势**: 快速迭代、独立调试

2. **生产阶段** (未来): 在 `openwrt/package/allwinner/ai-glasses/` 创建 OpenWrt 包
   - 创建 Makefile 指向 `../../src/` 源代码
   - 包自动集成到固件镜像
   - **优势**: 一次构建、完整固件

### 当前建议:

**不需要修改任何 Tina SDK 文件**。继续使用当前的 Docker 构建流程:

```bash
cd /Users/xzqxnet/Documents/beike/research/OpenSource-Ai-Glasses/v853-ai-glasses

# 编译所有组件
./start-docker.sh build-all

# 部署到设备
./start-docker.sh deploy-ssh 192.168.1.100
```

当需要将应用打包到固件镜像时，再按照上述**步骤 1-6** 创建 OpenWrt 包。

---

## 📚 参考资料

### Tina SDK 文档

- OpenWrt 包系统: `SDK/tina-v853-open/openwrt/README`
- 包定义示例: `openwrt/package/allwinner/power/healthd/Makefile`
- 设备配置: `openwrt/target/v853/v853-100ask/defconfig`

### 我们的文档

- Docker 使用: `v853-ai-glasses/DOCKER_GUIDE.md`
- 构建系统: `v853-ai-glasses/USAGE.md`
- SDK 结构: `v853-ai-glasses/SDK/SDK_STRUCTURE.md`

---

**创建时间**: 2026-01-23
**版本**: v1.0
**状态**: ✅ 完成
