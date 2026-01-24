# Tina SDK build.sh 集成答案

**用户问题**:
> `/Users/xzqxnet/Documents/beike/research/OpenSource-Ai-Glasses/v853-ai-glasses/SDK/tina-v853-open/build.sh` 是否需要修改，编译时需要包含 `/Users/xzqxnet/Documents/beike/research/OpenSource-Ai-Glasses/v853-ai-glasses/src` 和 `/Users/xzqxnet/Documents/beike/research/OpenSource-Ai-Glasses/v853-ai-glasses/SDK/ai_glass_sdk`

---

## 🎯 简短答案

**不需要修改 build.sh**

正确的做法有两种:

### 方案 1: 独立构建 + 部署 (推荐 - 开发阶段)

```bash
# 在 v853-ai-glasses/ 目录
./start-docker.sh build-all

# 部署到设备
./start-docker.sh deploy-ssh 192.168.1.100
```

**优势**: 快速迭代、灵活调试、独立开发

### 方案 2: OpenWrt 包集成 (可选 - 生产阶段)

```bash
# 安装包定义到 Tina SDK
./openwrt-packages/install-packages.sh

# 在 Tina SDK 中编译固件
cd SDK/tina-v853-open
source build/envsetup.sh
lunch v853-100ask-tina
./build.sh
```

**优势**: 完整固件镜像、一次刷机包含所有内容

---

## 📖 详细说明

### 为什么不需要修改 build.sh?

1. **build.sh 是 Tina SDK 的核心脚本**
   - 它通过 OpenWrt 包系统工作
   - 不应该直接修改核心构建脚本

2. **Tina SDK 使用包管理系统**
   - 所有自定义代码应该定义为 OpenWrt 包
   - 放在 `openwrt/package/allwinner/` 下
   - 通过 Makefile 指向外部源代码

3. **我们有更好的方法**
   - 开发阶段: 使用独立构建系统 (更快、更灵活)
   - 生产阶段: 使用 OpenWrt 包系统 (完整集成)

---

## 🔧 当前推荐流程 (开发阶段)

### 步骤 1: 使用 Docker 环境编译

```bash
cd /Users/xzqxnet/Documents/beike/research/OpenSource-Ai-Glasses/v853-ai-glasses

# 启动 Docker 容器
./start-docker.sh start

# 进入容器
./start-docker.sh shell

# 编译所有组件
make all
# 或者
./start-docker.sh build-all
```

### 步骤 2: 部署到设备

```bash
# 方法 1: SSH 部署
./start-docker.sh deploy-ssh 192.168.1.100

# 方法 2: ADB 部署
./start-docker.sh deploy-adb
```

### 步骤 3: 在设备上测试

```bash
# SSH 到设备
ssh root@192.168.1.100

# 测试 SDK
/usr/bin/camera_test
/usr/bin/audio_test
/usr/bin/gpio_test

# 运行显示应用
export QT_QPA_PLATFORM=linuxfb:/dev/fb0
/usr/bin/AIGlassesDisplay
```

---

## 🚀 未来集成方案 (生产阶段)

当需要将代码打包到固件镜像时 (给最终用户刷机):

### 步骤 1: 安装 OpenWrt 包定义

```bash
cd /Users/xzqxnet/Documents/beike/research/OpenSource-Ai-Glasses/v853-ai-glasses

# 运行安装脚本
./openwrt-packages/install-packages.sh

# 脚本会自动将包定义复制到:
# SDK/tina-v853-open/openwrt/package/allwinner/ai-glasses/
```

### 步骤 2: 配置和编译固件

```bash
cd SDK/tina-v853-open

# 加载环境
source build/envsetup.sh

# 选择目标
lunch v853-100ask-tina

# 配置包 (可选)
make menuconfig
# 导航到: Allwinner > AI Glasses
# 确认包已选中

# 编译固件
./build.sh

# 输出: out/v853/image/tina_v853-100ask_uart0.img
```

### 步骤 3: 刷写固件

```bash
# 使用 PhoenixSuit 或 LiveSuit 刷写
# 或使用 fastboot
fastboot flash system out/v853/image/tina_v853-100ask_uart0.img
```

---

## 📂 工作原理

### OpenWrt 包系统架构

```
tina-v853-open/
├── build.sh  (不需要修改!)
│   └─> 调用 OpenWrt 构建系统
│
├── openwrt/package/allwinner/ai-glasses/  (这里放我们的包)
│   ├── ai-glass-sdk/
│   │   └── Makefile  (指向 ../../../v853-ai-glasses/src/sdk_adapter)
│   ├── system-services/
│   │   └── Makefile  (指向 ../../../v853-ai-glasses/src/system_services)
│   └── display-qt/
│       └── Makefile  (指向 ../../../v853-ai-glasses/src/display_qt)
│
└── out/v853/image/  (最终固件输出)
```

### Makefile 如何指向外部源代码

示例 (ai-glass-sdk/Makefile):

```makefile
# 定义外部源代码路径
SRC_CODE_DIR := $(TOPDIR)/../../../v853-ai-glasses/src/sdk_adapter

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
	$(CP) $(SRC_CODE_DIR)/* $(PKG_BUILD_DIR)/
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) ...
endef
```

---

## ✅ 对比总结

| 特性 | 独立构建 | OpenWrt 包集成 |
|------|----------|----------------|
| **修改 build.sh** | ❌ 不需要 | ❌ 不需要 |
| **开发速度** | ⚡ 快速 | 🐢 较慢 (完整构建) |
| **调试便利** | ✅ 很方便 | ⚠️ 需要重新编译固件 |
| **固件集成** | ❌ 需要手动部署 | ✅ 自动包含在镜像 |
| **适用阶段** | 开发调试 | 生产发布 |
| **推荐度** | ⭐⭐⭐⭐⭐ (当前) | ⭐⭐⭐ (未来) |

---

## 📚 相关文档

- **详细集成指南**: `TINA_SDK_INTEGRATION.md` (700+行，完整说明)
- **OpenWrt 包文档**: `openwrt-packages/README.md` (400+行)
- **Docker 使用指南**: `DOCKER_GUIDE.md`
- **SDK 结构说明**: `SDK/SDK_STRUCTURE.md`

---

## 🎯 建议

### 当前阶段 (开发)

**使用独立构建**，不需要修改任何 Tina SDK 文件:

```bash
./start-docker.sh build-all
./start-docker.sh deploy-ssh <device-ip>
```

### 未来阶段 (生产发布)

**使用 OpenWrt 包集成**:

```bash
./openwrt-packages/install-packages.sh
cd SDK/tina-v853-open
./build.sh
```

---

## ❓ 常见问题

### Q: 为什么不直接修改 build.sh?

A:
- build.sh 是 Tina SDK 核心脚本，不应修改
- 修改后升级 SDK 会丢失更改
- OpenWrt 包系统是正确的扩展方式

### Q: 我的代码会被包含在固件中吗 (独立构建)?

A:
- 独立构建: ❌ 不会，需要手动部署
- OpenWrt 包: ✅ 会，自动包含在 .img 中

### Q: 我应该用哪种方式?

A:
- **开发阶段**: 独立构建 (快速、灵活)
- **测试阶段**: OpenWrt 包 (完整验证)
- **发布阶段**: OpenWrt 包 (生产固件)

---

**创建时间**: 2026-01-23
**作者**: Claude Code
**相关文档**: TINA_SDK_INTEGRATION.md
