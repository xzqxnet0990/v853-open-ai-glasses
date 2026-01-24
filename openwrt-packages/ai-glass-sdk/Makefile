# OpenWrt Package Makefile for AI Glass SDK
# V853 Platform - SDK Adapter Layer
#
# Usage:
#   1. Copy this directory to: SDK/tina-v853-open/openwrt/package/allwinner/ai-glasses/ai-glass-sdk/
#   2. Run: make menuconfig (select Allwinner > AI Glasses > ai-glass-sdk)
#   3. Run: make package/allwinner/ai-glasses/ai-glass-sdk/compile V=s

include $(TOPDIR)/rules.mk

PKG_NAME:=ai-glass-sdk
PKG_VERSION:=2.0.0
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

# 指向外部源代码目录
# 假设 v853-ai-glasses/ 和 tina-v853-open/ 在同一父目录下
SRC_CODE_DIR := $(TOPDIR)/../../../v853-ai-glasses/src/sdk_adapter
SDK_INCLUDE_DIR := $(TOPDIR)/../../../v853-ai-glasses/SDK/ai_glass_sdk/include
SDK_EXAMPLES_DIR := $(TOPDIR)/../../../v853-ai-glasses/SDK/ai_glass_sdk/examples

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
	AI Glass SDK adapter layer for V853 platform.
	Provides unified API for GPIO, Camera (V4L2), and Audio (ALSA).

	Features:
	- GPIO sysfs interface with event monitoring
	- V4L2 camera capture (1920x1080 NV12/JPEG)
	- ALSA audio playback
	- Thread-safe logging system
endef

define Package/ai-glass-sdk/config
	source "$(SOURCE)/Config.in"
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) $(SRC_CODE_DIR)/* $(PKG_BUILD_DIR)/
endef

define Build/Configure
	cd $(PKG_BUILD_DIR) && \
	mkdir -p build && cd build && \
	cmake .. \
		-DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_C_COMPILER=$(TARGET_CC) \
		-DCMAKE_CXX_COMPILER=$(TARGET_CXX) \
		-DCMAKE_C_FLAGS="$(TARGET_CFLAGS)" \
		-DCMAKE_CXX_FLAGS="$(TARGET_CXXFLAGS)" \
		-DCMAKE_EXE_LINKER_FLAGS="$(TARGET_LDFLAGS)"
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR)/build \
		VERBOSE=1
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_DIR) $(1)/usr/include

	# 安装库文件
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/build/libai_glass_sdk_v853.so $(1)/usr/lib/libai_glass_sdk.so
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/build/libai_glass_sdk_v853.a $(1)/usr/lib/libai_glass_sdk.a

	# 安装头文件
	$(CP) $(SDK_INCLUDE_DIR)/* $(1)/usr/include/
endef

define Package/ai-glass-sdk/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_DIR) $(1)/usr/bin

	# 安装共享库
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/build/libai_glass_sdk_v853.so $(1)/usr/lib/libai_glass_sdk.so

	# 安装测试程序 (如果编译了 examples)
	if [ -d "$(PKG_BUILD_DIR)/examples/build" ]; then \
		$(INSTALL_BIN) $(PKG_BUILD_DIR)/examples/build/camera_test $(1)/usr/bin/ || true; \
		$(INSTALL_BIN) $(PKG_BUILD_DIR)/examples/build/audio_test $(1)/usr/bin/ || true; \
		$(INSTALL_BIN) $(PKG_BUILD_DIR)/examples/build/gpio_test $(1)/usr/bin/ || true; \
	fi
endef

define Package/ai-glass-sdk/postinst
#!/bin/sh
echo "AI Glass SDK installed successfully"
echo "Libraries: /usr/lib/libai_glass_sdk.so"
echo "Test programs: /usr/bin/*_test"
endef

$(eval $(call BuildPackage,ai-glass-sdk))
