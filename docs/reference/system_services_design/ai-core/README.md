# AI Core Service - V853 Platform

V853 AI Glasses 核心服务

## 📋 概述

ai-core是V853 AI Glasses的核心系统服务，提供GPIO、摄像头、音频等硬件抽象接口，为应用层提供统一的硬件访问API。

## 🎯 功能模块

### 1. GPIO服务
- GPIO事件监听和分发
- 支持多客户端订阅
- 异步事件回调
- 低延迟 (<13ms)

### 2. 摄像头服务
- V4L2接口封装
- 共享内存图像传输
- JPEG/NV12格式支持
- 多客户端并发访问

### 3. 音频服务
- ALSA音频播放控制
- 音量调节
- 采样率配置
- 播放队列管理

## 🚀 快速开始

### 编译

```bash
cd src/system_services/ai-core
mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake
make
```

### 运行

```bash
# 启动所有服务
./ai-core --enable-gpio --enable-camera --enable-audio

# 只启动GPIO服务
./ai-core --enable-gpio --gpio-number 233,234

# 启动摄像头服务（JPEG格式）
./ai-core --enable-camera --enable-jpeg --width 1920 --height 1080
```

## 📂 文件结构

```
ai-core/
├── gpio_service.c       # GPIO服务实现
├── camera_service.c     # 摄像头服务实现
├── audio_service.c      # 音频服务实现
├── ipc_server.c         # IPC通信服务器
├── main.c               # 主程序
├── CMakeLists.txt       # 构建脚本
└── README.md            # 本文件
```

## 🔧 配置选项

### 命令行参数

| 参数 | 说明 | 默认值 |
|------|------|--------|
| `--enable-gpio` | 启用GPIO服务 | 禁用 |
| `--gpio-number <nums>` | GPIO编号（逗号分隔） | 233,234 |
| `--enable-camera` | 启用摄像头服务 | 禁用 |
| `--enable-jpeg` | 启用JPEG编码 | NV12 |
| `--width <w>` | 图像宽度 | 1920 |
| `--height <h>` | 图像高度 | 1080 |
| `--enable-audio` | 启用音频服务 | 禁用 |
| `--log-level <level>` | 日志级别 (DEBUG/INFO/WARN/ERROR) | INFO |

### 配置文件

`/etc/ai-glasses/ai-core.conf`:
```ini
[gpio]
enabled = true
gpio_numbers = 233,234

[camera]
enabled = true
device = /dev/video0
width = 1920
height = 1080
format = NV12
enable_jpeg = false

[audio]
enabled = true
device = hw:0,0
sample_rate = 16000
channels = 1
```

## 📡 IPC接口

### Unix Domain Socket

ai-core通过Unix Socket提供服务：

- **GPIO**: `/tmp/ai_gpio_event_<pid>`
- **Camera**: `/tmp/ai_camera_<pid>`
- **Audio**: `/tmp/ai_audio_<pid>`

### Shared Memory

摄像头图像数据通过共享内存传输：

- **路径**: `/dev/shm/ai_camera_<client_id>`
- **大小**: width × height × 1.5 (NV12格式)

## 🔄 工作流程

### GPIO服务流程

```
GPIO硬件 (/sys/class/gpio/)
    ↓
GPIO服务线程 (poll监听)
    ↓
事件队列
    ↓
IPC Server (Unix Socket)
    ↓
客户端订阅 (gpio_client)
```

### 摄像头服务流程

```
V4L2设备 (/dev/video0)
    ↓
摄像头捕获线程 (mmap buffers)
    ↓
图像数据 → Shared Memory
    ↓
通知客户端 (Unix Socket)
    ↓
客户端读取 (ai_core_capture)
```

## 🧪 测试

### 单元测试

```bash
cd build
make test
```

### 集成测试

```bash
# 启动服务
./ai-core --enable-gpio --enable-camera &

# 测试GPIO
/usr/bin/examples/gpio_test

# 测试摄像头
/usr/bin/examples/camera_test
```

## ⚠️ 注意事项

1. **权限要求**: 需要root权限或加入相应组 (gpio, video, audio)
2. **资源占用**: 约5MB内存，<5% CPU
3. **依赖库**: pthread, rt, V4L2, ALSA
4. **单实例**: 使用pidfile确保只运行一个实例

## 📚 API文档

详见: [SDK/ai_glass_sdk/docs/](../../../SDK/ai_glass_sdk/docs/)

---

**状态**: 📋 待实现
**下一步**: 根据需求实现各模块功能
