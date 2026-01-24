# OpenWrt 包定义 - AI Glasses V853

本目录包含用于集成到 Tina SDK 构建系统的 OpenWrt 包定义。

---

## 📦 包列表

### 1. ai-glass-sdk
**路径**: `ai-glass-sdk/`
**描述**: SDK 适配层库
**源代码**: `../src/sdk_adapter/`
**输出**:
- `/usr/lib/libai_glass_sdk.so`
- `/usr/lib/libai_glass_sdk.a`
- `/usr/bin/camera_test`, `audio_test`, `gpio_test` (可选)

### 2. system-services
**路径**: `system-services/`
**描述**: 系统服务 (ai-core, power_manager, log_daemon)
**源代码**: `../src/system_services/`
**输出**:
- `/usr/bin/ai-core`
- `/usr/bin/power_manager`
- `/usr/bin/log_daemon`
- `/etc/init.d/S99aiglasses`

### 3. display-qt
**路径**: `display-qt/`
**描述**: Qt5 显示应用
**源代码**: `../src/display_qt/`
**输出**:
- `/usr/bin/AIGlassesDisplay`
- `/etc/init.d/S98display` (可选)

---

## 🚀 使用方法

### 方法 1: 手动复制 (推荐用于学习)

```bash
# 1. 复制包定义到 Tina SDK
cp -r openwrt-packages/ai-glass-sdk \
      SDK/tina-v853-open/openwrt/package/allwinner/ai-glasses/

cp -r openwrt-packages/system-services \
      SDK/tina-v853-open/openwrt/package/allwinner/ai-glasses/

cp -r openwrt-packages/display-qt \
      SDK/tina-v853-open/openwrt/package/allwinner/ai-glasses/

# 2. 进入 Tina SDK 目录
cd SDK/tina-v853-open

# 3. 加载环境
source build/envsetup.sh

# 4. 选择目标
lunch v853-100ask-tina

# 5. 配置包 (可选)
make menuconfig
# 导航到: Allwinner > AI Glasses
# 确认所有包已选中

# 6. 编译单个包 (测试)
make package/allwinner/ai-glasses/ai-glass-sdk/compile V=s

# 7. 编译所有包
make package/allwinner/ai-glasses/compile V=s

# 8. 构建完整固件
./build.sh
```

### 方法 2: 使用安装脚本 (推荐用于生产)

```bash
# 运行安装脚本
./openwrt-packages/install-packages.sh

# 该脚本会:
# 1. 检查 Tina SDK 路径
# 2. 创建目标目录
# 3. 复制所有包定义
# 4. 更新设备配置 (可选)
# 5. 打印后续操作指南
```

---

## 📝 包结构说明

每个包目录包含:

```
package-name/
├── Makefile        # OpenWrt 包定义 (编译规则)
├── Config.in       # 配置选项 (menuconfig)
└── files/          # 附加文件 (启动脚本、配置等)
    ├── S99xxx      # Init.d 启动脚本
    └── xxx.conf    # 配置文件
```

### Makefile 关键部分

```makefile
# 1. 包信息
PKG_NAME:=package-name
PKG_VERSION:=2.0.0

# 2. 源代码位置
SRC_CODE_DIR := $(TOPDIR)/../../../v853-ai-glasses/src/xxx

# 3. 依赖
DEPENDS:=+ai-glass-sdk +libpthread

# 4. 编译步骤
Build/Prepare    # 复制源代码
Build/Configure  # CMake 配置
Build/Compile    # 编译
Build/Install    # 安装到固件
```

---

## 🔧 开发工作流

### 阶段 1: 开发调试 (当前推荐)

**不使用 OpenWrt 包系统**，使用独立构建:

```bash
cd v853-ai-glasses/

# Docker 环境编译
./start-docker.sh build-all

# 部署到设备
./start-docker.sh deploy-ssh 192.168.1.100
```

**优势**: 快速迭代、独立调试、灵活修改

### 阶段 2: 集成测试

**使用 OpenWrt 包系统**，集成到固件:

```bash
# 安装包定义
./openwrt-packages/install-packages.sh

# 编译固件
cd SDK/tina-v853-open
./build.sh
```

**优势**: 完整固件镜像、生产环境验证

### 阶段 3: 持续集成

**自动化构建**:

```bash
# CI/CD 脚本
./scripts/ci-build-firmware.sh
```

**优势**: 自动化、可重复、版本控制

---

## 📊 包依赖关系

```
ai-glass-display
    └─> ai-glass-sdk
        └─> libpthread, librt
    └─> qt5-core, qt5-gui, qt5-widgets

system-services
    └─> ai-glass-sdk
        └─> libpthread, librt
```

**构建顺序**:
1. ai-glass-sdk (基础库)
2. system-services (依赖 SDK)
3. display-qt (依赖 SDK)

---

## 🐛 故障排除

### 问题 1: 找不到源代码

**错误**: `No such file or directory: ../../../v853-ai-glasses/src`

**原因**: Tina SDK 和项目不在同一父目录

**解决**:
```bash
# 修改 Makefile 中的 SRC_CODE_DIR 路径
# 例如: SRC_CODE_DIR := /absolute/path/to/v853-ai-glasses/src/xxx
```

### 问题 2: CMake 找不到工具链

**错误**: `CMAKE_C_COMPILER not found`

**解决**:
```bash
# 确保已加载 Tina 环境
cd SDK/tina-v853-open
source build/envsetup.sh
lunch v853-100ask-tina

# 检查工具链
echo $PATH | grep arm-openwrt-linux
```

### 问题 3: 依赖库未找到

**错误**: `cannot find -lai_glass_sdk`

**解决**:
```bash
# 先编译依赖包
make package/allwinner/ai-glasses/ai-glass-sdk/compile V=s

# 再编译依赖该库的包
make package/allwinner/ai-glasses/system-services/compile V=s
```

### 问题 4: 包未出现在 menuconfig

**解决**:
```bash
# 清除配置缓存
make dirclean

# 重新配置
make menuconfig
# 导航到: Allwinner > AI Glasses
```

---

## 📚 参考文档

### OpenWrt 构建系统
- [OpenWrt Developer Guide](https://openwrt.org/docs/guide-developer/start)
- [OpenWrt Package Makefile](https://openwrt.org/docs/guide-developer/packages)
- [CMake in OpenWrt](https://openwrt.org/docs/guide-developer/cmake)

### Tina SDK 文档
- Tina SDK 目录: `SDK/tina-v853-open/README`
- 包示例: `openwrt/package/allwinner/power/healthd/`
- 设备配置: `openwrt/target/v853/v853-100ask/`

### 项目文档
- 集成指南: `../TINA_SDK_INTEGRATION.md`
- Docker 使用: `../DOCKER_GUIDE.md`
- SDK 结构: `../SDK/SDK_STRUCTURE.md`

---

## ✅ 检查清单

使用 OpenWrt 包系统前，确认:

- [ ] 已熟悉独立构建流程 (`./start-docker.sh build-all`)
- [ ] 源代码编译通过 (CMake + make)
- [ ] 测试程序在设备上运行正常
- [ ] 了解 OpenWrt Makefile 语法
- [ ] Tina SDK 环境已配置 (`source build/envsetup.sh`)
- [ ] 确定源代码路径 (SRC_CODE_DIR)
- [ ] 了解包依赖关系

---

## 🎯 最佳实践

1. **开发阶段**: 使用独立构建 + SSH 部署
   - 快速迭代
   - 便于调试

2. **测试阶段**: 使用 OpenWrt 包 + 完整固件
   - 验证集成
   - 测试依赖关系

3. **生产阶段**: 使用 OpenWrt 包 + CI/CD
   - 自动化构建
   - 版本控制

4. **包维护**:
   - 保持 Makefile 简洁
   - 记录依赖关系
   - 添加 postinst/prerm 脚本
   - 提供配置选项 (Config.in)

---

**创建时间**: 2026-01-23
**版本**: v1.0
**状态**: ✅ 可用
