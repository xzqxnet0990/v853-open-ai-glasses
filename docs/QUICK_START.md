# V853 AI Glasses - 快速入门指南

## 📋 前置要求

### 硬件
- [x] DongshanPI-AICT V853 开发板
- [x] MIPI DSI 显示屏
- [x] USB Type-C 数据线
- [x] TF卡 (32GB+，用于烧录固件)

### 软件
- [x] Linux 或 macOS 开发环境
- [x] V853 SDK (已解压到 `SDK/tina-v853-open/`)
- [x] 交叉编译工具链 (SDK自带)
- [x] Docker (推荐) 或本地编译环境

## 🚀 快速开始

### 🐳 方式A: Docker开发环境（推荐）

使用Docker可以避免环境配置问题，一键启动完整开发环境。

#### 步骤1: 启动Docker容器

```bash
cd v853-ai-glasses

# 启动容器（首次启动会自动构建镜像）
./start-docker.sh start

# 查看容器状态
./start-docker.sh status
```

#### 步骤2: 在容器内编译

```bash
# 方式1: 使用脚本命令
./start-docker.sh build-all

# 方式2: 进入容器手动编译
./start-docker.sh shell
# 在容器内执行:
make all
```

#### 步骤3: 部署到设备

```bash
# 通过SSH部署
./start-docker.sh deploy-ssh 192.168.1.100

# 或通过ADB部署
./start-docker.sh deploy-adb
```

**详细文档**: 请参考 [DOCKER_GUIDE.md](DOCKER_GUIDE.md)

---

### 💻 方式B: 本地编译（传统方式）

如果你不想使用Docker，可以直接在本地编译。

## 🚀 快速开始 (3步)

### 步骤1: 编译所有组件

```bash
cd v853-ai-glasses

# 方式1: 使用Makefile
make all

# 方式2: 使用脚本
./build_all.sh

# 预计编译时间: 5-10分钟
```

**编译输出**:
```
src/sdk_adapter/build/
├── libai_glass_sdk_v853.a       # SDK静态库
├── libai_glass_sdk_v853.so      # SDK动态库
└── examples/
    ├── camera_test              # 摄像头测试
    └── audio_test               # 音频测试

src/display_qt/build-v853/
└── AIGlassesDisplay_V853        # Qt主应用

src/ffm_launcher/build-v853/
└── FFlaunch                     # FFmpeg启动器

src/touchpad_manager/build-v853/
└── touchpad_manager             # GPIO管理器
```

### 步骤2: 部署到设备

#### 方式A: 通过SSH (推荐)
```bash
# 确保设备连接到同一网络
ping 192.168.1.100

# 部署
make deploy-ssh IP=192.168.1.100

# 或使用脚本
./deploy.sh 192.168.1.100
```

#### 方式B: 通过ADB
```bash
# 连接USB
adb devices

# 部署
make deploy-adb

# 或使用脚本
./deploy.sh adb
```

### 步骤3: 运行应用

```bash
# SSH登录到设备
ssh root@192.168.1.100

# 启动主应用
/usr/bin/AIGlassesDisplay_V853

# 或在后台运行
nohup /usr/bin/AIGlassesDisplay_V853 &

# 查看日志
logcat | grep V853
```

---

## 🔧 详细编译指南

### 只编译SDK适配层
```bash
make sdk

# 或
./build_all.sh sdk
```

### 只编译应用层
```bash
make app

# 或
./build_all.sh app
```

### 清理编译输出
```bash
make clean

# 或
./build_all.sh clean
```

---

## 🧪 测试SDK适配层

### 测试Camera功能
```bash
# 在V853设备上运行
/usr/bin/examples/camera_test

# 期望输出:
# [V853-Camera] Opened /dev/video0 successfully
# Frame #1: 1920x1080, size=3110400 bytes, format=NV12
# ...
```

### 测试Audio功能
```bash
# 准备测试文件 (16kHz, 16bit, Mono PCM)
# 运行测试
/usr/bin/examples/audio_test /tmp/test.pcm

# 期望输出:
# [V853-Audio] PCM device opened: card=0 device=0
# [V853-Audio] Played 32000/32000 bytes
```

### 测试GPIO功能
```bash
# 查看GPIO状态
cat /sys/kernel/debug/gpio

# 测试按键 (在应用中注册回调)
# 按下左侧按键，应触发事件
```

---

## 📁 项目结构速览

```
v853-ai-glasses/
├── build_all.sh         # 一键编译脚本 ⭐
├── deploy.sh            # 部署脚本 ⭐
├── Makefile             # Make编译配置 ⭐
│
├── tina-v853-open/      # V853官方SDK (15GB)
│
└── src/                 # 源代码
    ├── sdk_adapter/     # SDK适配层 (核心)
    │   ├── include/     # API头文件
    │   ├── src/         # V853实现
    │   │   ├── ai_camera_v853.c
    │   │   ├── ai_gpio_v853.c
    │   │   ├── ai_audio_v853.c
    │   │   └── ai_log_v853.c
    │   └── examples/    # 测试程序
    │
    ├── display_qt/      # Qt显示应用
    ├── ffm_launcher/    # FFmpeg启动器
    └── touchpad_manager/# GPIO管理器
```

---

## ⚠️ 常见问题

### Q1: 编译失败 - 找不到工具链
**解决**:
```bash
# 检查V853 SDK是否完整
ls tina-v853-open/prebuilt/gcc/linux-x86/arm/

# 如果缺失，重新解压SDK
cd ../06_Tina_SDK包
cat tina-v853-open.tar.gz.* | tar -xzf - -C ../v853-ai-glasses/
```

### Q2: Qt编译失败 - 找不到Qt5
**解决**:
```bash
# 检查Buildroot是否包含Qt5
ls tina-v853-open/buildroot/buildroot-201902/output/host/usr/lib/cmake/Qt5/

# 如果没有，需要先编译Buildroot
cd tina-v853-open
source build/envsetup.sh
lunch v853_100ask-tina
make menuconfig
# 启用Qt5支持
```

### Q3: 部署失败 - 连接不上设备
**解决**:
```bash
# 检查网络连接
ping 192.168.1.100

# 检查SSH服务
ssh root@192.168.1.100

# 如果使用ADB
adb devices
adb connect 192.168.1.100:5555
```

### Q4: 运行时错误 - 找不到so库
**解决**:
```bash
# 在设备上设置LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH

# 或添加到 /etc/profile
echo 'export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH' >> /etc/profile
source /etc/profile
```

---

## 🎯 下一步

1. **验证基础功能**: 确保摄像头、音频、GPIO都正常
2. **定制设备树**: 根据实际硬件配置修改 `device/config/chips/v853/configs/100ask/board.dts`
3. **集成到固件**: 将应用集成到Buildroot，生成完整固件
4. **性能优化**: 使用V853的NPU进行AI加速

---

## 📚 更多文档

- [README.md](README.md) - 项目概述
- [PROJECT_STATUS.md](PROJECT_STATUS.md) - 开发进度
- [API文档](src/sdk_adapter/include/) - SDK接口说明

---

## 🆘 获取帮助

- **查看Makefile帮助**: `make help`
- **查看脚本帮助**: `./build_all.sh`
- **查看部署帮助**: `./deploy.sh`

---

**祝你开发顺利！** 🎉
