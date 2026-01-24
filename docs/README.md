# OpenSource AI Glasses - V853 Platform

基于 Allwinner V853 SoC 的开源AI智能眼镜项目

[![Docker](https://img.shields.io/badge/Docker-Ready-blue.svg)](DOCKER_GUIDE.md)
[![Platform](https://img.shields.io/badge/Platform-V853-green.svg)](https://www.allwinnertech.com)
[![Status](https://img.shields.io/badge/Status-In%20Development-yellow.svg)](PROJECT_STATUS.md)

## 🎯 项目目标

将原有基于 RV1109 的 OpenSource-Ai-Glasses 项目迁移到 Allwinner V853 平台，利用 V853 的以下优势：
- ✅ **NPU加速**: 1 TOPS INT8 算力，支持深度学习推理
- ✅ **异构处理器**: RISC-V E907 协处理器 @ 600MHz
- ✅ **高性能ISP**: 支持 1080P@60fps 视频处理
- ✅ **MIPI DSI**: 支持高分辨率显示屏

## 🚀 快速开始

### 方式1: Docker开发环境（推荐）

```bash
# 1. 启动Docker容器
./start-docker.sh start

# 2. 进入容器
./start-docker.sh shell

# 3. 编译所有组件
make all

# 4. 部署到设备
./deploy.sh 192.168.1.100
```

**详细文档**: [DOCKER_GUIDE.md](DOCKER_GUIDE.md)

### 方式2: 本地编译

```bash
# 1. 确保V853工具链在PATH中
export PATH=/path/to/tina-v853-open/prebuilt/gcc/linux-x86/arm/toolchain-sunxi-musl/toolchain/bin:$PATH

# 2. 编译
make all

# 3. 部署
./deploy.sh 192.168.1.100
```

**详细文档**: [QUICK_START.md](QUICK_START.md)

## 📁 项目结构

```
v853-ai-glasses/
├── tina-v853-open/          # V853 官方SDK (15GB)
│   ├── kernel/linux-4.9/    # Linux内核源码
│   ├── device/config/       # 设备树配置
│   ├── openwrt/package/     # 软件包
│   └── buildroot/           # Buildroot根文件系统
│
├── src/                     # 应用层源码
│   ├── sdk_adapter/         # ⭐ SDK适配层 (RV1109 API → V853 API)
│   │   ├── include/         # 保持RV1109的API定义
│   │   │   ├── ai_camera.h
│   │   │   ├── ai_gpio.h
│   │   │   └── ai_audio.h
│   │   ├── src/             # V853平台实现
│   │   │   ├── ai_camera_v853.c   # 使用V4L2实现
│   │   │   ├── ai_gpio_v853.c     # 使用Linux GPIO实现
│   │   │   └── ai_audio_v853.c    # 使用ALSA实现
│   │   └── examples/        # 测试示例
│   │
│   ├── display_qt/          # Qt5显示应用 (从RV1109复制)
│   │   ├── mainwindow.cpp
│   │   ├── widgets/
│   │   └── CMakeLists_v853.txt
│   │
│   ├── ffm_launcher/        # FFmpeg视频服务
│   ├── touchpad_manager/    # GPIO按键管理
│   └── system_services/     # 系统服务
│
├── analysis/                # 分析文档
│   ├── rv1109_vs_v853/      # 平台对比分析
│   ├── sdk_adapter_design/  # SDK适配层设计
│   └── migration_notes/     # 迁移笔记
│
└── README.md               # 本文件
```

## 🏗️ 架构设计

### SDK适配层 (核心设计)

```
应用层 (display_qt, ffm_launcher等)
    ↓ 调用
ai_camera.h / ai_gpio.h / ai_audio.h (RV1109兼容API)
    ↓ 实现
┌─────────────────────────────────────┐
│  SDK Adapter Layer (src/sdk_adapter) │
│  - ai_camera_v853.c                  │
│  - ai_gpio_v853.c                    │
│  - ai_audio_v853.c                   │
└─────────────────────────────────────┘
    ↓ 调用
┌─────────────────────────────────────┐
│  V853 Platform APIs                 │
│  - V4L2 (camera)                    │
│  - Linux GPIO sysfs (gpio)          │
│  - ALSA (audio)                     │
│  - CedarX (video codec)             │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│  V853 Hardware (DongshanPI-AICT)    │
└─────────────────────────────────────┘
```

**关键特性**:
- ✅ 应用层代码无需修改
- ✅ API定义保持不变 (ai_camera.h等)
- ✅ 底层实现适配V853硬件
- ✅ 编译时静态链接适配层

## 🚀 快速开始

### 1. 环境准备

#### 硬件需求
- DongshanPI-AICT V853 开发板
- MIPI DSI 显示屏
- USB Type-C 数据线
- TF卡 (32GB+)

#### 软件环境
```bash
# 已解压的V853 SDK
ls tina-v853-open/
# 输出: kernel/ device/ openwrt/ buildroot/ ...

# Docker编译环境 (可选)
docker pull ubuntu:20.04
```

### 2. 编译SDK适配层

```bash
cd src/sdk_adapter
mkdir build && cd build

# 使用V853工具链编译
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake
make -j$(nproc)

# 输出:
#   libai_glass_sdk_v853.a      (静态库)
#   libai_glass_sdk_v853.so     (动态库)
#   camera_test                 (测试程序)
```

### 3. 编译Qt应用

```bash
cd src/display_qt
mkdir build-v853 && cd build-v853

# 配置V853交叉编译
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake \
         -DCMAKE_BUILD_TYPE=Release

make -j4

# 输出: AIGlassesDisplay_V853
```

### 4. 部署到设备

```bash
# 通过ADB或SSH部署
scp AIGlassesDisplay_V853 root@192.168.1.100:/usr/bin/
scp libai_glass_sdk_v853.so root@192.168.1.100:/usr/lib/

# 运行
ssh root@192.168.1.100
./usr/bin/AIGlassesDisplay_V853
```

## 📚 API文档

### Camera API

```c
#include "ai_camera.h"

// 1. 初始化摄像头
ai_core_client_t *camera = ai_core_init();

// 2. 捕获图像
ai_core_data_t data;
int ret = ai_core_capture(camera, &data, 2000);  // 2秒超时

// 3. 处理图像
printf("Frame: %dx%d, size=%zu\n", data.width, data.height, data.size);

// 4. 释放数据
ai_core_free_data(&data);

// 5. 清理
ai_core_cleanup(camera);
```

### GPIO API

```c
#include "ai_gpio.h"

// 1. 初始化GPIO
gpio_client_ctx_t *gpio = gpio_client_init(GPIO_NUM);

// 2. 注册回调
gpio_register_callback(gpio, my_callback, user_data);

// 3. 清理
gpio_client_cleanup(gpio);
```

## 🔄 迁移进度

### 已完成 ✅
- [x] V853 SDK解压和验证
- [x] 项目目录结构搭建
- [x] SDK适配层框架
- [x] Camera适配实现 (ai_camera_v853.c)
- [x] GPIO适配实现 (ai_gpio_v853.c)
- [x] Qt应用复制和配置
- [x] CMake构建系统
- [x] 测试示例程序

### 进行中 🚧
- [ ] Audio适配实现 (ai_audio_v853.c)
- [ ] FFmpeg launcher适配
- [ ] 设备树定制
- [ ] 完整系统编译
- [ ] 硬件测试

### 待开始 📋
- [ ] NPU集成 (利用V853优势)
- [ ] RISC-V E907协处理器
- [ ] 性能优化
- [ ] 文档完善

## 🛠️ 开发指南

### 添加新的API适配

1. **定义接口** (保持RV1109兼容):
```c
// src/sdk_adapter/include/ai_xxx.h
int ai_xxx_init(void);
```

2. **V853实现**:
```c
// src/sdk_adapter/src/ai_xxx_v853.c
int ai_xxx_init(void) {
    // 调用V853底层API
    return 0;
}
```

3. **更新CMakeLists.txt**:
```cmake
set(SDK_ADAPTER_SOURCES
    ...
    src/ai_xxx_v853.c
)
```

### 调试技巧

```bash
# 在V853设备上查看日志
logcat | grep "V853-Camera"
logcat | grep "V853-GPIO"

# 测试摄像头
v4l2-ctl --list-devices
v4l2-ctl -d /dev/video0 --list-formats

# 测试GPIO
cat /sys/kernel/debug/gpio
```

## 📊 性能对比

| 指标 | RV1109 | V853 | 提升 |
|------|--------|------|------|
| CPU | Cortex-A7 双核 @ 1.4GHz | Cortex-A7 双核 @ 1.4GHz | - |
| NPU | 无 | 1 TOPS INT8 | ✅ |
| 协处理器 | 无 | RISC-V E907 @ 600MHz | ✅ |
| ISP | 1080P@30fps | 1080P@60fps | 2x |
| 内存 | 1GB DDR3 | 1GB DDR3 | - |

## 🤝 贡献指南

欢迎提交 Pull Request！

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/xxx`)
3. 提交更改 (`git commit -m 'Add xxx'`)
4. 推送到分支 (`git push origin feature/xxx`)
5. 创建 Pull Request

## 📄 许可证

本项目基于原 OpenSource-Ai-Glasses 项目，继承其许可证。

## 📮 联系方式

- 原项目: [OpenSource-Ai-Glasses](https://github.com/Iam5tillLearning/OpenSource-Ai-Glasses)
- 问题反馈: GitHub Issues

---

**注意**: 本项目目前处于开发阶段，部分功能尚未完成。请参考"迁移进度"章节了解最新状态。
