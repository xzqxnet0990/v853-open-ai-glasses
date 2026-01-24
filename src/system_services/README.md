# System Services - V853 Platform

V853 AI Glasses 系统服务层

## 📋 概述

本目录包含V853平台的系统级服务程序，这些服务在系统启动时运行，为应用层提供底层硬件支持。

## 🎯 服务列表

### 1. ai-core Service (核心服务)

**位置**: `ai-core/`
**功能**: 提供核心硬件抽象服务

**子模块**:
- **GPIO Service** - GPIO事件处理和分发
- **Camera Service** - 摄像头数据捕获和共享
- **Audio Service** - 音频播放控制

**运行方式**:
```bash
# 启动完整服务
./ai-core --enable-gpio --enable-camera --enable-audio

# 只启动特定服务
./ai-core --enable-gpio
./ai-core --enable-camera --enable-jpeg
```

**通信方式**:
- Unix Domain Socket: 事件分发、控制命令
- Shared Memory: 图像数据传输 (零拷贝)

---

### 2. Display Manager (显示管理器)

**位置**: `display_manager/`
**功能**: 管理MIPI DSI显示屏

**特性**:
- 显示模式切换 (GUI模式 / 调试模式)
- 亮度控制
- 帧率管理
- DRM/KMS接口抽象

**运行方式**:
```bash
./display_manager --mode=gui --brightness=80
```

---

### 3. Power Manager (电源管理器)

**位置**: `power_manager/`
**功能**: 电源监控和管理

**特性**:
- 双电源监控 (12V外部 + 3.7V电池)
- 电量检测和报警
- 低电量自动关机
- 电源状态上报

**运行方式**:
```bash
./power_manager --check-interval=5
```

**监控项**:
- `/sys/class/power_supply/aiglasses-power/online` - 12V电源状态
- `/sys/class/power_supply/rk817-battery/capacity` - 电池电量
- `/sys/class/power_supply/rk817-battery/voltage_now` - 电池电压

---

### 4. WiFi Manager (WiFi管理器)

**位置**: `wifi_manager/`
**功能**: WiFi连接和配置

**特性**:
- AP模式配置 (首次启动)
- STA模式连接
- 网络状态监控
- 自动重连

**运行方式**:
```bash
# 配置模式 (AP)
./wifi_manager --mode=config

# 连接模式 (STA)
./wifi_manager --mode=client --ssid="MyWiFi" --password="password"
```

---

### 5. Log Daemon (日志守护进程)

**位置**: `log_daemon/`
**功能**: 统一日志收集和管理

**特性**:
- 多进程日志收集
- 日志分级存储
- 自动日志轮转
- 远程日志上传 (可选)

**运行方式**:
```bash
./log_daemon --log-dir=/var/log/ai_glasses --max-size=100M
```

---

## 🏗️ 目录结构

```
system_services/
├── ai-core/                    # 核心服务
│   ├── gpio_service.c         # GPIO服务实现
│   ├── camera_service.c       # 摄像头服务实现
│   ├── audio_service.c        # 音频服务实现
│   ├── ipc_server.c           # IPC服务器
│   ├── main.c                 # 主程序入口
│   ├── CMakeLists.txt         # 构建脚本
│   └── README.md              # 详细文档
│
├── display_manager/            # 显示管理器
│   ├── drm_manager.c          # DRM/KMS接口
│   ├── mipi_dsi_ctrl.c        # MIPI DSI控制
│   ├── brightness_ctrl.c      # 亮度控制
│   ├── main.c
│   ├── CMakeLists.txt
│   └── README.md
│
├── power_manager/              # 电源管理器
│   ├── battery_monitor.c      # 电池监控
│   ├── power_supply.c         # 电源供应监控
│   ├── power_alarm.c          # 电源报警
│   ├── main.c
│   ├── CMakeLists.txt
│   └── README.md
│
├── wifi_manager/               # WiFi管理器
│   ├── ap_mode.c              # AP模式
│   ├── sta_mode.c             # STA模式
│   ├── wpa_ctrl.c             # WPA控制
│   ├── main.c
│   ├── CMakeLists.txt
│   └── README.md
│
├── log_daemon/                 # 日志守护进程
│   ├── log_collector.c        # 日志收集
│   ├── log_rotate.c           # 日志轮转
│   ├── log_upload.c           # 日志上传
│   ├── main.c
│   ├── CMakeLists.txt
│   └── README.md
│
├── init/                       # 初始化脚本
│   ├── ai-glasses.service     # systemd服务文件
│   ├── S99aiglasses           # init.d脚本
│   └── README.md
│
├── CMakeLists.txt              # 总构建脚本
├── toolchain-v853.cmake        # V853工具链配置
└── README.md                   # 本文件
```

## 🔨 编译所有服务

### 使用CMake构建

```bash
cd src/system_services
mkdir build && cd build

# 配置
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake -DCMAKE_BUILD_TYPE=Release

# 编译所有服务
make -j4

# 输出位置
ls -lh bin/
# ai-core
# display_manager
# power_manager
# wifi_manager
# log_daemon
```

### 使用项目构建脚本

```bash
# 从项目根目录
./start-docker.sh build-all

# 或
make all
```

## 📦 部署到设备

### 1. 部署二进制文件

```bash
# 复制所有服务到设备
scp bin/* root@192.168.1.100:/usr/bin/

# 设置执行权限
ssh root@192.168.1.100 "chmod +x /usr/bin/ai-core /usr/bin/display_manager /usr/bin/power_manager /usr/bin/wifi_manager /usr/bin/log_daemon"
```

### 2. 部署启动脚本

```bash
# systemd方式
scp init/ai-glasses.service root@192.168.1.100:/etc/systemd/system/
ssh root@192.168.1.100 "systemctl enable ai-glasses"

# init.d方式
scp init/S99aiglasses root@192.168.1.100:/etc/init.d/
ssh root@192.168.1.100 "chmod +x /etc/init.d/S99aiglasses"
```

### 3. 启动服务

```bash
ssh root@192.168.1.100

# systemd
systemctl start ai-glasses

# init.d
/etc/init.d/S99aiglasses start

# 手动启动
/usr/bin/ai-core --enable-gpio --enable-camera --enable-audio &
/usr/bin/power_manager &
/usr/bin/log_daemon &
```

## 🧪 测试服务

### 测试GPIO服务

```bash
# 在设备上
# 1. 启动GPIO服务
/usr/bin/ai-core --enable-gpio &

# 2. 使用SDK测试
/usr/bin/examples/gpio_test

# 3. 按下按键，应该看到事件输出
```

### 测试摄像头服务

```bash
# 1. 启动摄像头服务
/usr/bin/ai-core --enable-camera --enable-jpeg &

# 2. 测试捕获
/usr/bin/examples/camera_test

# 3. 查看共享内存
ls -lh /dev/shm/ai_*
```

### 测试电源管理

```bash
# 1. 启动电源管理器
/usr/bin/power_manager &

# 2. 查看电源状态
cat /sys/class/power_supply/aiglasses-power/online
cat /sys/class/power_supply/rk817-battery/capacity

# 3. 查看日志
logcat | grep PowerManager
```

## 🔧 开发指南

### 添加新服务

1. **创建服务目录**:
   ```bash
   mkdir src/system_services/my_service
   cd src/system_services/my_service
   ```

2. **创建源文件**:
   ```c
   // main.c
   #include <stdio.h>
   #include "ai_log.h"

   int main(int argc, char *argv[]) {
       ai_log_init(AI_LOG_INFO);

       AI_LOG_INFO("MyService", "Service started");

       // 你的服务逻辑...

       return 0;
   }
   ```

3. **创建CMakeLists.txt**:
   ```cmake
   cmake_minimum_required(VERSION 3.10)
   project(my_service)

   add_executable(my_service main.c)
   target_link_libraries(my_service ai_glass_sdk pthread)

   install(TARGETS my_service DESTINATION bin)
   ```

4. **添加到主CMakeLists.txt**:
   ```cmake
   add_subdirectory(my_service)
   ```

### 使用SDK功能

所有系统服务都可以使用AI Glass SDK：

```c
#include "ai_gpio.h"
#include "ai_camera.h"
#include "ai_audio.h"
#include "ai_log.h"

int main() {
    // 初始化日志
    ai_log_init(AI_LOG_DEBUG);

    // 使用GPIO
    gpio_client_t *gpio = gpio_client_init(NULL);

    // 使用摄像头
    ai_core_client_t *camera = ai_core_init();

    // 你的服务逻辑...

    return 0;
}
```

## 🛠️ V853平台特性

### GPIO访问

```c
// V853 GPIO编号: Bank * 32 + Pin
#define GPIO_BUTTON_LEFT  233  // PH9
#define GPIO_BUTTON_RIGHT 234  // PH10

// 导出GPIO
echo 233 > /sys/class/gpio/export
echo in > /sys/class/gpio/gpio233/direction
echo both > /sys/class/gpio/gpio233/edge
```

### V4L2摄像头

```c
// V853摄像头设备
#define CAMERA_DEVICE "/dev/video0"

// 配置1080P NV12格式
v4l2_ctl --device=/dev/video0 \
    --set-fmt-video=width=1920,height=1080,pixelformat=NV12
```

### ALSA音频

```c
// V853音频设备
#define AUDIO_DEVICE "hw:0,0"

// 播放PCM
aplay -D hw:0,0 -f S16_LE -c 1 -r 16000 audio.pcm
```

### 电源监控

```c
// 12V外部电源
#define POWER_ONLINE "/sys/class/power_supply/aiglasses-power/online"

// RK817电池
#define BATTERY_CAPACITY "/sys/class/power_supply/rk817-battery/capacity"
#define BATTERY_VOLTAGE  "/sys/class/power_supply/rk817-battery/voltage_now"
```

## ⚠️ 注意事项

### 1. 权限要求

- GPIO服务需要root权限或gpio组
- 摄像头服务需要video组权限
- 音频服务需要audio组权限
- 电源管理需要读取sysfs权限

### 2. 依赖关系

服务启动顺序：
1. log_daemon (日志服务)
2. ai-core (核心服务)
3. power_manager (电源管理)
4. display_manager (显示管理)
5. wifi_manager (WiFi管理)

### 3. 资源占用

- ai-core: ~5MB内存，<5% CPU
- display_manager: ~2MB内存
- power_manager: ~1MB内存
- wifi_manager: ~2MB内存
- log_daemon: ~1MB内存

### 4. 日志位置

- 系统日志: `/var/log/ai_glasses/`
- 服务日志: `/var/log/ai_glasses/<service_name>.log`
- 调试日志: `logcat | grep <TAG>`

## 📚 相关文档

- [ai-core详细文档](ai-core/README.md) - 核心服务说明
- [display_manager文档](display_manager/README.md) - 显示管理器
- [power_manager文档](power_manager/README.md) - 电源管理器
- [SDK文档](../../SDK/ai_glass_sdk/README.md) - SDK API参考

## 🔄 从RV1109迁移

RV1109项目使用的是单个display-service，V853项目采用了模块化的多服务架构：

| RV1109 | V853 | 说明 |
|--------|------|------|
| display-service | ai-core + display_manager | 功能拆分 |
| 单进程 | 多进程 | 更好的隔离和稳定性 |
| JBD013 SPI | MIPI DSI | 显示接口不同 |

## 🎉 当前状态

- [ ] **ai-core服务** - 待实现
- [ ] **display_manager** - 待实现
- [ ] **power_manager** - 待实现
- [ ] **wifi_manager** - 待实现
- [ ] **log_daemon** - 待实现
- [ ] **启动脚本** - 待实现

**下一步**: 根据需要实现各个服务模块

---

**版本**: v1.0.0
**平台**: Allwinner V853
**更新时间**: 2026-01-23
