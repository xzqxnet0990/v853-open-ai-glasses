# V853 AI Glasses - 使用指南

完整的开发、编译、部署和调试指南。

## 📚 目录

1. [开发环境选择](#开发环境选择)
2. [项目初始化](#项目初始化)
3. [编译流程](#编译流程)
4. [测试验证](#测试验证)
5. [部署到设备](#部署到设备)
6. [固件编译](#固件编译)
7. [常用命令速查](#常用命令速查)

## 开发环境选择

### Docker环境（推荐）✅

**优点**:
- ✅ 环境隔离，不污染主机
- ✅ 一键启动，无需配置工具链
- ✅ 跨平台支持（Linux/macOS/Windows WSL2）
- ✅ 编译缓存持久化
- ✅ 支持固件编译

**适用场景**:
- 初次接触项目
- 需要快速编译验证
- 多人协作开发
- CI/CD自动化

**快速开始**:
```bash
./start-docker.sh start    # 启动容器
./start-docker.sh shell    # 进入容器
make all                   # 编译所有组件
```

**详细文档**: [DOCKER_GUIDE.md](DOCKER_GUIDE.md)

---

### 本地环境

**优点**:
- ⚡ 编译速度稍快（无容器开销）
- 🔧 可直接使用本地IDE调试
- 💾 节省Docker磁盘空间

**前提条件**:
- Linux或macOS系统
- V853 SDK已解压
- 工具链已添加到PATH

**快速开始**:
```bash
# 初始化SDK路径
./init_sdk_path.sh

# 设置工具链PATH
export PATH=/path/to/toolchain/bin:$PATH

# 编译
make all
```

**详细文档**: [QUICK_START.md](QUICK_START.md)

---

## 项目初始化

### 1. 克隆项目

```bash
git clone <repository-url> v853-ai-glasses
cd v853-ai-glasses
```

### 2. 准备V853 SDK

V853 SDK应放置在 `SDK/tina-v853-open/` 目录：

```bash
# 检查SDK是否存在
ls SDK/tina-v853-open/

# 应该看到以下关键目录:
# ├── build.sh
# ├── kernel/
# ├── prebuilt/gcc/
# ├── buildroot/
# └── ...
```

### 3. 初始化路径（仅本地环境需要）

```bash
# Docker环境自动处理，跳过此步骤
# 本地环境需要运行:
./init_sdk_path.sh
```

### 4. 验证环境

#### Docker环境:
```bash
./start-docker.sh start
./start-docker.sh info
```

#### 本地环境:
```bash
# 检查工具链
arm-openwrt-linux-gcc --version

# 检查CMake
cmake --version
```

---

## 编译流程

### 完整编译流程图

```
┌─────────────────────────────────────────────────┐
│           V853 AI Glasses 编译流程              │
└─────────────────────────────────────────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │   1. SDK适配层编译            │
        │   (Camera + GPIO + Audio)     │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │   2. 应用层编译                │
        │   - Qt显示应用                 │
        │   - FFmpeg启动器               │
        │   - GPIO管理器                 │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │   3. 测试程序编译              │
        │   (camera_test, audio_test)   │
        └───────────────┬───────────────┘
                        │
                        ▼
        ┌───────────────────────────────┐
        │   4. 打包部署                  │
        │   (SSH/ADB)                   │
        └───────────────────────────────┘
```

### 编译命令对照表

| 任务 | Docker命令 | 本地命令 | 说明 |
|------|-----------|---------|------|
| 编译SDK适配层 | `./start-docker.sh build-sdk` | `make sdk` | 编译libai_glass_sdk_v853.so |
| 编译应用层 | `./start-docker.sh build-app` | `make app` | 编译Qt+FFmpeg+GPIO管理器 |
| 编译所有组件 | `./start-docker.sh build-all` | `make all` | 一键编译SDK+应用 |
| 清理编译产物 | `./start-docker.sh clean-build` | `make clean` | 删除build目录 |
| 编译固件 | `./start-docker.sh build-firmware` | （需要SDK环境） | 编译完整系统镜像 |

### 详细编译步骤

#### 步骤1: 编译SDK适配层

**作用**: 将RV1109 API适配到V853平台

```bash
# Docker
./start-docker.sh build-sdk

# 本地
make sdk
```

**输出**:
```
src/sdk_adapter/build/
├── libai_glass_sdk_v853.a       # 静态库
├── libai_glass_sdk_v853.so      # 动态库 (约200KB)
└── examples/
    ├── camera_test              # 摄像头测试程序
    ├── audio_test               # 音频测试程序
    └── gpio_test                # GPIO测试程序
```

**验证**:
```bash
file src/sdk_adapter/build/libai_glass_sdk_v853.so
# 应显示: ELF 32-bit LSB shared object, ARM, ...
```

#### 步骤2: 编译Qt显示应用

```bash
# Docker
./start-docker.sh shell
cd src/display_qt
mkdir build-v853 && cd build-v853
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake
make -j4

# 或使用脚本
./start-docker.sh build-app
```

**输出**: `src/display_qt/build-v853/AIGlassesDisplay_V853` (~5MB)

#### 步骤3: 编译FFmpeg启动器

```bash
cd src/ffm_launcher
mkdir build-v853 && cd build-v853
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake
make
```

**输出**: `src/ffm_launcher/build-v853/FFlaunch` (~100KB)

#### 步骤4: 编译GPIO管理器

```bash
cd src/touchpad_manager
mkdir build-v853 && cd build-v853
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake
make
```

**输出**: `src/touchpad_manager/build-v853/touchpad_manager` (~50KB)

---

## 测试验证

### 在开发机测试（交叉编译验证）

```bash
# 检查ELF文件类型
file src/sdk_adapter/build/libai_glass_sdk_v853.so
# 预期: ELF 32-bit LSB shared object, ARM

# 检查依赖库
arm-openwrt-linux-readelf -d src/sdk_adapter/build/libai_glass_sdk_v853.so
```

### 在设备上测试

#### 1. 测试摄像头

```bash
# Docker环境
./start-docker.sh test-camera

# 在设备上
ssh root@192.168.1.100
/usr/bin/examples/camera_test

# 预期输出:
# [V853-Camera] Opened /dev/video0 successfully
# Frame #1: 1920x1080, size=3110400 bytes, format=NV12
# ...
```

#### 2. 测试GPIO按键

```bash
# 在设备上
/usr/bin/examples/gpio_test

# 按下左侧按键，应看到:
# [GPIO] Button pressed: GPIO 233
```

#### 3. 测试音频播放

```bash
# 准备测试音频文件 (16kHz, 16bit, Mono PCM)
/usr/bin/examples/audio_test /tmp/test.pcm

# 预期输出:
# [V853-Audio] PCM device opened: hw:0,0
# [V853-Audio] Played 32000/32000 bytes
```

---

## 部署到设备

### 方式1: SSH部署（推荐）

**前提条件**:
- 设备已连接到网络
- 设备IP可访问

```bash
# Docker环境
./start-docker.sh deploy-ssh 192.168.1.100

# 本地环境
./deploy.sh 192.168.1.100
```

**部署文件**:
```
/usr/lib/libai_glass_sdk_v853.so        # SDK库
/usr/bin/AIGlassesDisplay_V853          # Qt应用
/usr/bin/FFlaunch                       # FFmpeg启动器
/usr/bin/touchpad_manager               # GPIO管理器
/usr/bin/examples/camera_test           # 测试程序
/usr/bin/examples/audio_test
/usr/bin/examples/gpio_test
```

### 方式2: ADB部署

**前提条件**:
- USB连接到设备
- ADB已安装并授权

```bash
# 检查设备连接
adb devices

# 部署
./start-docker.sh deploy-adb
# 或
./deploy.sh adb
```

### 方式3: 手动复制

```bash
# SCP复制
scp src/sdk_adapter/build/libai_glass_sdk_v853.so root@192.168.1.100:/usr/lib/
scp src/display_qt/build-v853/AIGlassesDisplay_V853 root@192.168.1.100:/usr/bin/

# 设置权限
ssh root@192.168.1.100 "chmod +x /usr/bin/AIGlassesDisplay_V853"
```

### 在设备上运行

```bash
# SSH登录
ssh root@192.168.1.100

# 启动主应用
/usr/bin/AIGlassesDisplay_V853

# 或后台运行
nohup /usr/bin/AIGlassesDisplay_V853 &

# 查看日志
logcat | grep V853
```

---

## 固件编译

### 编译完整系统镜像

**⚠️ 注意**: 固件编译需要20-40分钟，建议使用Docker环境。

```bash
# Docker环境
./start-docker.sh build-firmware

# 手动编译（在容器内）
./start-docker.sh shell
cd /opt/v853_sdk
source build/envsetup.sh
lunch v853-100ask-tina   # 选择板型
./build.sh
```

**输出**:
```
/opt/v853_sdk/out/v853/image/
├── boot.img              # 启动镜像
├── rootfs.img            # 根文件系统
└── update.img            # 完整固件（用于烧录）
```

### 复制固件到主机

```bash
# Docker环境
./start-docker.sh copy-image

# 手动复制
docker cp v853_ai_glasses_dev:/opt/v853_sdk/out/v853/image/boot.img ./output/
```

### 烧录固件

请参考 Allwinner 官方烧录工具文档。

---

## 常用命令速查

### Docker环境

| 命令 | 说明 |
|------|------|
| `./start-docker.sh start` | 启动容器 |
| `./start-docker.sh stop` | 停止容器 |
| `./start-docker.sh shell` | 进入容器Shell |
| `./start-docker.sh status` | 查看容器状态 |
| `./start-docker.sh build-all` | 编译所有组件 |
| `./start-docker.sh build-firmware` | 编译固件 |
| `./start-docker.sh deploy-ssh <IP>` | SSH部署 |
| `./start-docker.sh test-camera` | 测试摄像头 |
| `./start-docker.sh info` | 显示环境信息 |
| `./start-docker.sh clean` | 删除容器 |
| `./start-docker.sh help` | 显示帮助 |

### 本地环境

| 命令 | 说明 |
|------|------|
| `make all` | 编译所有组件 |
| `make sdk` | 只编译SDK适配层 |
| `make app` | 只编译应用层 |
| `make clean` | 清理编译产物 |
| `./deploy.sh <IP>` | 部署到设备 |
| `./init_sdk_path.sh` | 初始化SDK路径 |

### 在设备上

| 命令 | 说明 |
|------|------|
| `/usr/bin/AIGlassesDisplay_V853` | 启动主应用 |
| `/usr/bin/examples/camera_test` | 测试摄像头 |
| `/usr/bin/examples/gpio_test` | 测试GPIO |
| `logcat \| grep V853` | 查看应用日志 |
| `cat /sys/class/gpio/export` | 导出GPIO |
| `ls /dev/video*` | 查看视频设备 |

---

## 🆘 故障排查

### 编译错误

**问题**: `arm-openwrt-linux-gcc: command not found`

**解决**:
```bash
# Docker环境: 重启容器
./start-docker.sh restart

# 本地环境: 检查PATH
echo $PATH
export PATH=/opt/v853_sdk/prebuilt/gcc/linux-x86/arm/toolchain-sunxi-musl/toolchain/bin:$PATH
```

### 部署失败

**问题**: `ssh: connect to host 192.168.1.100 port 22: Connection refused`

**解决**:
```bash
# 1. 检查网络连接
ping 192.168.1.100

# 2. 检查SSH服务
ssh root@192.168.1.100

# 3. 尝试ADB部署
./deploy.sh adb
```

### 运行时错误

**问题**: `error while loading shared libraries: libai_glass_sdk_v853.so`

**解决**:
```bash
# 在设备上设置库路径
ssh root@192.168.1.100
export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH
echo 'export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH' >> /etc/profile
```

---

## 📚 相关文档

- [README.md](README.md) - 项目概述
- [DOCKER_GUIDE.md](DOCKER_GUIDE.md) - Docker详细指南
- [QUICK_START.md](QUICK_START.md) - 本地编译快速开始
- [PROJECT_STATUS.md](PROJECT_STATUS.md) - 开发进度

---

**Happy Hacking!** 🚀
