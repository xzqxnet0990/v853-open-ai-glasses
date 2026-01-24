# OpenWrt Package Makefile for AI Glasses System Services
# V853 Platform - Core System Services
#
# Services included:
#   - ai-core: GPIO/Camera/Audio hardware service
#   - power_manager: Power monitoring daemon
#   - log_daemon: System log collector
#
# Usage:
#   1. Copy to: SDK/tina-v853-open/openwrt/package/allwinner/ai-glasses/system-services/
#   2. Run: make menuconfig (select Allwinner > AI Glasses > ai-glass-services)
#   3. Run: make package/allwinner/ai-glasses/system-services/compile V=s

include $(TOPDIR)/rules.mk

PKG_NAME:=ai-glass-services
PKG_VERSION:=2.0.0
PKG_RELEASE:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

# 指向外部源代码目录
SRC_CODE_DIR := $(TOPDIR)/../../../v853-ai-glasses/src/system_services
SDK_LIB_DIR := $(TOPDIR)/../../../v853-ai-glasses/SDK/ai_glass_sdk/lib
SDK_INCLUDE_DIR := $(TOPDIR)/../../../v853-ai-glasses/SDK/ai_glass_sdk/include

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
	System services for AI Glasses V853 platform.

	Services:
	- ai-core: Core hardware service (GPIO/Camera/Audio)
	- power_manager: Battery and power monitoring
	- log_daemon: Multi-process log collection

	IPC: Unix Domain Sockets + Shared Memory
	Startup: Init.d script (S99aiglasses)
endef

define Package/ai-glass-services/config
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
		-DCMAKE_C_FLAGS="$(TARGET_CFLAGS) -I$(SDK_INCLUDE_DIR)" \
		-DCMAKE_CXX_FLAGS="$(TARGET_CXXFLAGS)" \
		-DCMAKE_EXE_LINKER_FLAGS="$(TARGET_LDFLAGS) -L$(SDK_LIB_DIR)"
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR)/build \
		VERBOSE=1
endef

define Package/ai-glass-services/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DIR) $(1)/var/log/ai_glasses

	# 安装服务二进制 (如果已实现)
	# 注意: 当前框架中服务代码未实现，这里仅作为示例
	# $(INSTALL_BIN) $(PKG_BUILD_DIR)/build/bin/ai-core $(1)/usr/bin/ || true
	# $(INSTALL_BIN) $(PKG_BUILD_DIR)/build/bin/power_manager $(1)/usr/bin/ || true
	# $(INSTALL_BIN) $(PKG_BUILD_DIR)/build/bin/log_daemon $(1)/usr/bin/ || true

	# 安装启动脚本
	$(INSTALL_BIN) ./files/S99aiglasses $(1)/etc/init.d/S99aiglasses

	# 安装配置文件
	$(INSTALL_CONF) ./files/ai-glasses.conf $(1)/etc/config/ai-glasses || true
endef

define Package/ai-glass-services/postinst
#!/bin/sh
echo "AI Glasses Services installed"
echo "Enable at boot: /etc/init.d/S99aiglasses enable"
echo "Start manually: /etc/init.d/S99aiglasses start"

# 自动启用服务
if [ -z "$$IPKG_INSTROOT" ]; then
	/etc/init.d/S99aiglasses enable
	echo "Service enabled at boot"
fi
endef

define Package/ai-glass-services/prerm
#!/bin/sh
# 卸载前停止服务
if [ -z "$$IPKG_INSTROOT" ]; then
	/etc/init.d/S99aiglasses stop
fi
endef

$(eval $(call BuildPackage,ai-glass-services))
