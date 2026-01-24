# V853 AI Glasses - Docker开发环境指南

本指南介绍如何使用Docker容器进行V853 AI Glasses项目的开发和编译。

## 📋 目录

- [环境要求](#环境要求)
- [快速开始](#快速开始)
- [容器管理](#容器管理)
- [编译流程](#编译流程)
- [常见问题](#常见问题)

## 🔧 环境要求

### 必需软件

- **Docker**: 20.10+
- **Docker Compose**: 1.29+ 或 Docker Compose V2
- **磁盘空间**: 至少 30GB 可用空间
  - Docker镜像: ~2GB
  - V853 SDK: ~15GB
  - 编译缓存和输出: ~5GB

### 系统要求

- **操作系统**: Linux, macOS, Windows (WSL2)
- **内存**: 建议 8GB+
- **CPU**: 多核处理器（编译加速）

## 🚀 快速开始

### 1. 检查SDK目录

确保V853 SDK已解压到正确位置：

```bash
cd v853-ai-glasses
ls -la SDK/tina-v853-open/
```

应该看到以下目录结构：
```
SDK/tina-v853-open/
├── build.sh              # 固件编译脚本
├── prebuilt/             # 预编译工具链
│   └── gcc/
│       └── linux-x86/
│           └── arm/
│               └── toolchain-sunxi-musl/
├── kernel/               # Linux内核源码
├── buildroot/            # Buildroot
└── ...
```

### 2. 启动开发容器

```bash
# 首次启动（会自动构建Docker镜像）
./start-docker.sh start

# 查看容器状态
./start-docker.sh status
```

### 3. 进入容器Shell

```bash
./start-docker.sh shell
```

进入容器后，你会看到：
```
🐚 进入容器Shell...
工作目录: /workspace
SDK目录:  /opt/v853_sdk

root@v853-aiglasses-dev:/workspace#
```

### 4. 在容器内编译

```bash
# 方式1: 使用脚本命令（推荐）
./start-docker.sh build-all

# 方式2: 进入容器手动编译
./start-docker.sh shell
# 在容器内:
make all
```

## 🎮 容器管理

### 基础命令

| 命令 | 说明 |
|------|------|
| `./start-docker.sh start` | 启动开发容器 |
| `./start-docker.sh stop` | 停止容器 |
| `./start-docker.sh restart` | 重启容器 |
| `./start-docker.sh shell` | 进入容器Shell |
| `./start-docker.sh status` | 查看容器状态 |
| `./start-docker.sh logs` | 查看容器日志 |

### 清理命令

| 命令 | 说明 |
|------|------|
| `./start-docker.sh clean` | 删除容器（保留镜像） |
| `./start-docker.sh clean-all` | 删除容器、镜像和卷 |
| `./start-docker.sh clean-build` | 清理编译产物 |
| `./start-docker.sh clean-cache` | 清理Docker缓存 |

## 🔨 编译流程

### 编译SDK适配层

```bash
# 方式1: 使用脚本（在主机）
./start-docker.sh build-sdk

# 方式2: 在容器内
./start-docker.sh shell
cd /workspace
make sdk
```

**输出位置**:
```
src/sdk_adapter/build/
├── libai_glass_sdk_v853.a   # 静态库
├── libai_glass_sdk_v853.so  # 动态库
└── examples/
    ├── camera_test
    ├── audio_test
    └── gpio_test
```

### 编译应用层

```bash
# 编译所有应用（Qt + FFmpeg + GPIO）
./start-docker.sh build-app
```

**输出位置**:
```
src/display_qt/build-v853/AIGlassesDisplay_V853
src/ffm_launcher/build-v853/FFlaunch
src/touchpad_manager/build-v853/touchpad_manager
```

### 编译完整固件

```bash
# ⚠️ 需要20-40分钟
./start-docker.sh build-firmware
```

**输出位置**: `/opt/v853_sdk/out/v853/image/*.img`

**复制到主机**:
```bash
./start-docker.sh copy-image
# 镜像将复制到: output/boot.img
```

### 一键编译所有组件

```bash
./start-docker.sh build-all
```

## 🧪 测试功能

在容器内或通过脚本测试各个模块：

```bash
# 测试摄像头
./start-docker.sh test-camera

# 测试音频
./start-docker.sh test-audio

# 测试GPIO
./start-docker.sh test-gpio
```

## 📦 部署到设备

### 通过SSH部署

```bash
# 确保设备在同一网络
./start-docker.sh deploy-ssh 192.168.1.100
```

### 通过ADB部署

```bash
# 确保USB连接
./start-docker.sh deploy-adb
```

## 🛠️ 开发辅助

### 查看环境信息

```bash
./start-docker.sh info
```

输出示例：
```
📋 V853开发环境信息

=== 系统信息 ===
Linux v853-aiglasses-dev 5.15.0-91-generic #101-Ubuntu SMP

=== 工具链信息 ===
arm-openwrt-linux-gcc (GCC) 8.4.0

=== 目录信息 ===
SDK目录: /opt/v853_sdk
  ✓ 已挂载
项目目录: /workspace
  ✓ 已挂载

=== 编译状态 ===
  ✓ SDK适配层已编译
  ✗ Qt应用未编译
```

### 查看工具链信息

```bash
./start-docker.sh toolchain
```

## 🗂️ 目录映射

Docker容器将以下目录挂载到容器内：

| 主机路径 | 容器路径 | 说明 |
|----------|----------|------|
| `./` | `/workspace` | 项目源码 |
| `./SDK/tina-v853-open` | `/opt/v853_sdk` | V853 SDK |
| Docker Volume | `/workspace/.build-cache` | 编译缓存 |
| Docker Volume | `/workspace/output` | 编译输出 |

### 访问容器内的文件

```bash
# 从容器复制到主机
docker cp v853_ai_glasses_dev:/workspace/output/file.img ./

# 从主机复制到容器
docker cp ./local-file.txt v853_ai_glasses_dev:/workspace/
```

## 🔍 调试技巧

### 查看编译日志

```bash
# 查看容器日志
./start-docker.sh logs

# 或者进入容器查看
./start-docker.sh shell
cat /tmp/build.log
```

### 手动执行编译步骤

```bash
./start-docker.sh shell

# 在容器内:
cd /workspace/src/sdk_adapter
mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake
make VERBOSE=1  # 显示详细编译信息
```

### 检查工具链

```bash
./start-docker.sh shell

# 检查编译器
arm-openwrt-linux-gcc --version

# 检查环境变量
echo $PATH
echo $V853_SDK_PATH
echo $TOOLCHAIN_PATH

# 测试编译简单程序
cat > test.c << 'EOF'
#include <stdio.h>
int main() { printf("Hello V853\n"); return 0; }
EOF

arm-openwrt-linux-gcc test.c -o test
file test  # 查看文件类型
```

## ❓ 常见问题

### Q1: 容器启动失败

**问题**: `ERROR: Cannot start service v853-dev`

**解决方案**:
```bash
# 1. 检查Docker服务
docker info

# 2. 检查SDK目录
ls SDK/tina-v853-open/

# 3. 查看详细错误
./start-docker.sh logs

# 4. 重新构建镜像
./start-docker.sh clean
./start-docker.sh start
```

### Q2: 工具链未找到

**问题**: `arm-openwrt-linux-gcc: command not found`

**解决方案**:
```bash
# 进入容器检查
./start-docker.sh shell

# 检查PATH
echo $PATH

# 手动添加到PATH
export PATH=/opt/v853_sdk/prebuilt/gcc/linux-x86/arm/toolchain-sunxi-musl/toolchain/bin:$PATH

# 或重启容器（PATH会自动设置）
exit
./start-docker.sh restart
./start-docker.sh shell
```

### Q3: 编译速度慢

**优化方案**:
```bash
# 1. 使用多核编译
make -j$(nproc)

# 2. 使用编译缓存（已自动配置Docker Volume）

# 3. 增加Docker资源限制
# 编辑 docker-compose.yml:
deploy:
  resources:
    limits:
      cpus: '4'
      memory: 8G
```

### Q4: Qt依赖缺失

**问题**: `fatal error: QApplication: No such file or directory`

**解决方案**:
```bash
./start-docker.sh shell

# 检查Qt5是否安装
pkg-config --modversion Qt5Core

# 如果缺失，在Dockerfile中添加Qt5依赖
apt-get install -y qtbase5-dev qtbase5-dev-tools

# 重新构建镜像
exit
./start-docker.sh clean
./start-docker.sh start
```

### Q5: 磁盘空间不足

**问题**: `no space left on device`

**解决方案**:
```bash
# 1. 清理Docker缓存
./start-docker.sh clean-cache

# 2. 清理编译产物
./start-docker.sh clean-build

# 3. 清理无用镜像
docker image prune -a

# 4. 查看Docker磁盘使用
docker system df
```

### Q6: 无法访问USB设备（烧录器）

**问题**: USB烧录器在容器内不可见

**解决方案**:
```bash
# 1. 确保docker-compose.yml配置了USB设备
privileged: true
devices:
  - /dev/bus/usb:/dev/bus/usb

# 2. 在Linux主机添加用户到docker组
sudo usermod -aG docker $USER
sudo usermod -aG plugdev $USER

# 3. 重启容器
./start-docker.sh restart
```

## 📚 进阶使用

### 自定义Dockerfile

如果需要添加额外工具或依赖，编辑 `Dockerfile`:

```dockerfile
# 添加自定义工具
RUN apt-get update && apt-get install -y \
    your-package \
    && rm -rf /var/lib/apt/lists/*
```

然后重新构建：
```bash
./start-docker.sh clean
./start-docker.sh start
```

### 使用VSCode Remote-Containers

1. 安装VSCode扩展: `Remote - Containers`
2. 打开项目目录
3. 按 `F1` → `Remote-Containers: Attach to Running Container`
4. 选择 `v853_ai_glasses_dev`
5. 在容器内开发，自动代码补全和调试

### CI/CD集成

在GitLab CI或GitHub Actions中使用：

```yaml
# .gitlab-ci.yml
build:
  image: aiglasses/v853-dev:v1.0.0
  script:
    - cd /workspace
    - make all
  artifacts:
    paths:
      - src/*/build*/
```

## 🔗 相关文档

- [README.md](README.md) - 项目概述
- [QUICK_START.md](QUICK_START.md) - 快速入门（非Docker）
- [PROJECT_STATUS.md](PROJECT_STATUS.md) - 开发进度

## 📞 获取帮助

```bash
# 显示所有可用命令
./start-docker.sh help

# 查看容器状态
./start-docker.sh status

# 查看环境信息
./start-docker.sh info
```

---

**Happy Coding!** 🚀
