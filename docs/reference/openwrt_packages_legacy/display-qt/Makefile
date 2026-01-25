# OpenWrt Package Makefile for AI Glasses Display Application
# V853 Platform - Qt5 Display Application
#
# Usage:
#   1. Copy to: SDK/tina-v853-open/openwrt/package/allwinner/ai-glasses/display-qt/
#   2. Ensure Qt5 is enabled in buildroot/openwrt
#   3. Run: make menuconfig (select Allwinner > AI Glasses > ai-glass-display)
#   4. Run: make package/allwinner/ai-glasses/display-qt/compile V=s

include $(TOPDIR)/rules.mk

PKG_NAME:=ai-glass-display
PKG_VERSION:=2.0.0
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

# 指向外部源代码目录
SRC_CODE_DIR := $(TOPDIR)/../../../v853-ai-glasses/src/display_qt
SDK_LIB_DIR := $(TOPDIR)/../../../v853-ai-glasses/SDK/ai_glass_sdk/lib
SDK_INCLUDE_DIR := $(TOPDIR)/../../../v853-ai-glasses/SDK/ai_glass_sdk/include

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/cmake.mk

define Package/ai-glass-display
  SUBMENU:=AI Glasses
  SECTION:=allwinner
  CATEGORY:=Allwinner
  TITLE:=AI Glasses Qt5 Display Application
  DEPENDS:=+ai-glass-sdk +qt5-core +qt5-gui +qt5-widgets +fontconfig
  DEFAULT:=y
endef

define Package/ai-glass-display/description
	Qt5-based display application for AI Glasses.

	Features:
	- MIPI DSI display support (1280x720@60Hz)
	- Three-screen UI: Battery/Camera/Settings
	- Dual power source monitoring
	- Chinese font support
	- LinuxFB/EGLFS backend support
endef

define Package/ai-glass-display/config
	source "$(SOURCE)/Config.in"
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) $(SRC_CODE_DIR)/* $(PKG_BUILD_DIR)/
endef

define Build/Configure
	cd $(PKG_BUILD_DIR) && \
	mkdir -p build-arm && cd build-arm && \
	cmake .. \
		-DCMAKE_TOOLCHAIN_FILE=../toolchain-arm.cmake \
		-DCMAKE_INSTALL_PREFIX=/usr \
		-DCMAKE_BUILD_TYPE=Release \
		-DCMAKE_C_COMPILER=$(TARGET_CC) \
		-DCMAKE_CXX_COMPILER=$(TARGET_CXX) \
		-DCMAKE_C_FLAGS="$(TARGET_CFLAGS) -I$(SDK_INCLUDE_DIR)" \
		-DCMAKE_CXX_FLAGS="$(TARGET_CXXFLAGS)" \
		-DCMAKE_EXE_LINKER_FLAGS="$(TARGET_LDFLAGS) -L$(SDK_LIB_DIR)" \
		-DQT_QMAKE_EXECUTABLE=$(STAGING_DIR_HOST)/bin/qmake
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR)/build-arm \
		VERBOSE=1
endef

define Package/ai-glass-display/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/usr/share/fonts

	# 安装主程序
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/build-arm/AIGlassesDisplay $(1)/usr/bin/

	# 安装启动脚本
	$(INSTALL_BIN) ./files/S98display $(1)/etc/init.d/ || true

	# 安装字体 (如果有)
	# $(CP) $(SRC_CODE_DIR)/fonts/* $(1)/usr/share/fonts/ || true
endef

define Package/ai-glass-display/postinst
#!/bin/sh
echo "AI Glasses Display Application installed"
echo "Binary: /usr/bin/AIGlassesDisplay"
echo ""
echo "To run:"
echo "  export QT_QPA_PLATFORM=linuxfb:/dev/fb0"
echo "  /usr/bin/AIGlassesDisplay"
echo ""
echo "For hardware acceleration:"
echo "  export QT_QPA_PLATFORM=eglfs"
echo "  export QT_QPA_EGLFS_INTEGRATION=eglfs_kms"

# 自动启用服务
if [ -z "$$IPKG_INSTROOT" ] && [ -f "/etc/init.d/S98display" ]; then
	/etc/init.d/S98display enable
fi
endef

$(eval $(call BuildPackage,ai-glass-display))
