# AI Glass SDK - V853 Platform

中文版本 | [English Version](README.en.md)

## 🎯 简介

本SDK为基于Allwinner V853平台的AI智能眼镜提供完整的客户端开发套件，支持GPIO事件订阅、摄像头调用和音频播放功能。

**目标平台**: DongshanPI-AICT V853 开发板
**工具链**: arm-openwrt-linux-gcc (Tina Linux)
**版本**: v2.0.0-v853

## 📦 SDK内容

```
ai_glass_sdk/
├── include/              # 头文件
│   ├── ai_gpio.h         # GPIO事件客户端API
│   ├── ai_camera.h       # 摄像头客户端API
│   ├── ai_audio.h        # 音频客户端API
│   ├── ai_display.h      # 显示客户端API
│   ├── ai_text_event.h   # 文本事件API
│   ├── ai_ipc.h          # IPC通信API
│   ├── ai_log.h          # 日志系统API
│   ├── http_client.h     # HTTP客户端API
│   └── ws_client.h       # WebSocket客户端API
│
├── lib/                  # 编译后的库文件
│   ├── libai_glass_sdk.a # 静态库 (V853版本)
│   └── libai_glass_sdk.so# 动态库 (V853版本)
│
├── examples/             # 示例程序
│   ├── gpio_example/     # GPIO事件示例
│   ├── camera_capture_example/  # 摄像头捕获示例
│   ├── audio_play_example/      # 音频播放示例
│   ├── text_event_example/      # 文本事件示例
│   ├── http_example/            # HTTP客户端示例
│   └── websocket_example/       # WebSocket示例
│
├── docs/                 # API文档
│   ├── GPIO_Client_API.md       # GPIO API文档
│   ├── Camera_Client_API.md     # 摄像头API文档
│   ├── Audio_Client_API.md      # 音频API文档
│   ├── Display_Client_API.md    # 显示API文档
│   ├── Text_Event_Client_API.md # 文本事件API文档
│   └── Log_API.md               # 日志API文档
│
├── README.md             # 本文件
├── README.en.md          # English README
├── Makefile              # SDK编译脚本
└── VERSION               # 版本信息
```

## 🎯 主要功能

### 1. GPIO事件订阅
- 支持多进程同时监听GPIO按键事件
- 异步事件回调机制
- 低延迟（< 13ms）
- **V853特性**: 使用Linux GPIO sysfs接口

### 2. 摄像头调用
- 通过共享内存零拷贝图像传输
- 支持JPEG和NV12格式
- 多客户端并发支持
- **V853特性**: 基于V4L2标准接口，支持1080P@60fps

### 3. 音频播放控制
- Unix Socket通信控制音频播放
- 支持音量调节、采样率配置
- 强制播放和停止功能
- **V853特性**: 使用ALSA/tinyalsa音频框架

### 4. 显示控制
- MIPI DSI显示屏控制
- 支持Qt5图形界面
- 分辨率: 1280x720@60Hz

### 5. 网络通信
- HTTP客户端（基于mongoose）
- WebSocket客户端
- 支持JSON数据交换

## 🚀 快速开始

### 环境要求

#### Docker环境（推荐）
```bash
cd v853-ai-glasses
./start-docker.sh start
./start-docker.sh shell
```

#### 本地环境
- V853 交叉编译工具链
- CMake 3.10+
- Make

### 编译SDK库

```bash
cd SDK/ai_glass_sdk

# 使用Makefile编译
make

# 输出:
# lib/libai_glass_sdk.a   - 静态库
# lib/libai_glass_sdk.so  - 动态库
```

### 编译示例程序

```bash
# 编译所有示例
make examples

# 或单独编译
cd examples/gpio_example
make

cd ../camera_capture_example
make
```

## 📝 使用示例

### 1. GPIO事件订阅

```c
#include "ai_gpio.h"

// 定义回调函数
void gpio_callback(int gpio_num, gpio_event_t event, void *user_data) {
    if (event == GPIO_EVENT_PRESSED) {
        printf("Button pressed: GPIO %d\n", gpio_num);
    }
}

int main() {
    // 初始化GPIO客户端
    gpio_client_t *client = gpio_client_init(NULL);

    // 订阅GPIO事件 (V853: PH9 = 7*32+9 = 233)
    gpio_client_subscribe(client, 233, gpio_callback, NULL);

    // 等待事件
    sleep(60);

    // 清理
    gpio_client_cleanup(client);
    return 0;
}
```

**编译**:
```bash
arm-openwrt-linux-gcc -o gpio_test gpio_test.c \
    -I./include -L./lib -lai_glass_sdk -lpthread -lrt
```

### 2. 摄像头捕获

```c
#include "ai_camera.h"

int main() {
    // 初始化摄像头客户端
    ai_core_client_t *camera = ai_core_init();

    // 捕获一帧 (1920x1080, NV12)
    ai_core_data_t data;
    if (ai_core_capture(camera, &data, 2000) == 0) {
        printf("Captured frame: %dx%d, %d bytes\n",
               data.width, data.height, data.size);

        // 处理图像数据 data.data

        // 释放数据
        ai_core_free_data(&data);
    }

    // 清理
    ai_core_cleanup(camera);
    return 0;
}
```

### 3. 音频播放

```c
#include "ai_audio.h"

int main() {
    // 初始化音频客户端
    ai_audio_t *audio = ai_audio_init(NULL);

    // 配置播放参数
    ai_audio_params_t params = ai_audio_create_default_params("/path/to/audio.pcm");
    params.volume = 80;          // 音量80%
    params.sample_rate = 16000;  // 16kHz
    params.channels = 1;         // 单声道
    params.bit_width = 16;       // 16位

    // 播放音频
    ai_audio_play(audio, &params);

    // 清理
    ai_audio_cleanup(audio);
    return 0;
}
```

## 🔧 集成到应用

### 1. 添加头文件路径

```cmake
# CMakeLists.txt
include_directories(${PROJECT_SOURCE_DIR}/SDK/ai_glass_sdk/include)
```

### 2. 链接SDK库

```cmake
# 链接静态库
target_link_libraries(your_app
    ${PROJECT_SOURCE_DIR}/SDK/ai_glass_sdk/lib/libai_glass_sdk.a
    pthread
    rt
)

# 或链接动态库
target_link_libraries(your_app
    ai_glass_sdk
    pthread
    rt
)
link_directories(${PROJECT_SOURCE_DIR}/SDK/ai_glass_sdk/lib)
```

### 3. 在应用中使用

```c
#include "ai_gpio.h"
#include "ai_camera.h"
#include "ai_audio.h"
#include "ai_log.h"

int main() {
    // 初始化日志
    ai_log_init(AI_LOG_INFO);

    // 使用SDK功能
    gpio_client_t *gpio = gpio_client_init(NULL);
    ai_core_client_t *camera = ai_core_init();
    ai_audio_t *audio = ai_audio_init(NULL);

    // 你的应用逻辑...

    // 清理
    gpio_client_cleanup(gpio);
    ai_core_cleanup(camera);
    ai_audio_cleanup(audio);

    return 0;
}
```

## 🏗️ V853平台特性

### 硬件接口映射

| 功能 | RV1109实现 | V853实现 |
|------|-----------|---------|
| **摄像头** | Rockchip ISP + RKMPP | V4L2 (/dev/video0) |
| **GPIO** | Rockchip GPIO驱动 | Linux GPIO sysfs |
| **音频** | Rockchip ALSA | ALSA/tinyalsa |
| **显示** | DRM/KMS | MIPI DSI + DRM/KMS |

### GPIO编号计算（V853）

V853 GPIO编号 = Bank * 32 + Pin

示例:
- **PH9** = 7 * 32 + 9 = **233** (左侧按键)
- **PH10** = 7 * 32 + 10 = **234** (右侧按键)
- **PA0** = 0 * 32 + 0 = **0**
- **PB5** = 1 * 32 + 5 = **37**

Bank映射: PA=0, PB=1, PC=2, PD=3, PE=4, PF=5, PG=6, PH=7

### V4L2摄像头配置

```bash
# 查看摄像头设备
ls /dev/video*

# 查看设备信息
v4l2-ctl --device=/dev/video0 --all

# 设置格式
v4l2-ctl --device=/dev/video0 \
    --set-fmt-video=width=1920,height=1080,pixelformat=NV12
```

### ALSA音频配置

```bash
# 列出音频设备
aplay -l

# 播放PCM文件
aplay -D hw:0,0 -f S16_LE -c 1 -r 16000 audio.pcm

# 调整音量
amixer set Master 80%
```

## 📚 API文档

详细的API文档请查看 `docs/` 目录：

- [GPIO客户端API](docs/GPIO_Client_API.md) - GPIO事件订阅和控制
- [摄像头客户端API](docs/Camera_Client_API.md) - 摄像头捕获和图像获取
- [音频客户端API](docs/Audio_Client_API.md) - 音频播放和控制
- [显示客户端API](docs/Display_Client_API.md) - 显示屏控制
- [文本事件API](docs/Text_Event_Client_API.md) - 文本事件处理
- [日志API](docs/Log_API.md) - 日志系统使用

## 🔍 示例程序

所有示例程序位于 `examples/` 目录：

| 示例 | 说明 | 位置 |
|------|------|------|
| gpio_example | GPIO按键事件监听 | examples/gpio_example/ |
| camera_capture_example | 摄像头图像捕获 | examples/camera_capture_example/ |
| audio_play_example | 音频播放控制 | examples/audio_play_example/ |
| text_event_example | 文本事件处理 | examples/text_event_example/ |
| http_example | HTTP客户端 | examples/http_example/ |
| websocket_example | WebSocket客户端 | examples/websocket_example/ |

## 🐛 调试和测试

### 启用调试日志

```c
#include "ai_log.h"

// 在main函数开始处
ai_log_init(AI_LOG_DEBUG);  // 启用DEBUG级别日志
ai_log_set_color(1);        // 启用彩色输出
```

### 测试GPIO

```bash
# 导出GPIO
echo 233 > /sys/class/gpio/export

# 设置为输入
echo in > /sys/class/gpio/gpio233/direction

# 设置中断类型
echo both > /sys/class/gpio/gpio233/edge

# 读取值
cat /sys/class/gpio/gpio233/value
```

### 测试摄像头

```bash
# V853摄像头测试
cd examples/camera_capture_example
make
./camera_test

# 预期输出:
# [V853-Camera] Opened /dev/video0 successfully
# Frame #1: 1920x1080, size=3110400 bytes
```

### 测试音频

```bash
# 准备测试文件 (16kHz, 16bit, Mono PCM)
cd examples/audio_play_example
make
./audio_test test.pcm

# 预期输出:
# [V853-Audio] PCM device opened: hw:0,0
# [V853-Audio] Played bytes: 32000/32000
```

## ⚠️ 注意事项

### 1. 工具链
- 必须使用V853的arm-openwrt-linux-gcc工具链
- 不要混用RV1109的工具链
- 推荐使用Docker环境避免工具链问题

### 2. 权限
- GPIO需要root权限或添加到gpio组
- 摄像头需要video组权限
- 音频需要audio组权限

### 3. 依赖库
运行时需要以下库：
- pthread (线程支持)
- rt (实时扩展)
- ALSA库 (音频)
- V4L2库 (摄像头)

### 4. 共享内存
摄像头使用共享内存传输图像，确保：
- `/dev/shm` 有足够空间（至少10MB）
- 正确清理共享内存：`rm -f /dev/shm/ai_*`

## 🔄 从RV1109迁移

如果你有基于RV1109的代码，迁移到V853平台：

1. **API兼容**: SDK API完全兼容，无需修改应用代码
2. **GPIO编号**: 更新GPIO编号计算方式（见上文）
3. **重新编译**: 使用V853工具链重新编译
4. **测试验证**: 在V853硬件上测试所有功能

示例：
```bash
# RV1109代码
gpio_client_subscribe(client, 1, callback, NULL);  // GPIO 1

# V853代码
gpio_client_subscribe(client, 233, callback, NULL);  // GPIO PH9 = 233
```

## 📦 安装到设备

### 方式1: 使用部署脚本

```bash
# 从项目根目录
cd v853-ai-glasses
./deploy.sh 192.168.1.100  # SSH部署
# 或
./deploy.sh adb            # ADB部署
```

### 方式2: 手动安装

```bash
# 复制SDK库到设备
scp lib/libai_glass_sdk.so root@192.168.1.100:/usr/lib/

# 复制头文件（如果需要在设备上编译）
scp -r include/ root@192.168.1.100:/usr/include/ai_glass/

# 设置库路径
ssh root@192.168.1.100
export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH
```

### 方式3: 集成到固件

将SDK集成到Buildroot固件：

```bash
# 在V853 SDK中
cd /opt/v853_sdk/buildroot
# 添加SDK到package/
# 修改Config.in和package.mk
# 重新编译固件
make menuconfig
make
```

## 🆘 故障排查

### 问题1: 编译错误 - 找不到工具链

```bash
# Docker环境
./start-docker.sh restart
./start-docker.sh shell

# 本地环境
export PATH=/path/to/v853/toolchain/bin:$PATH
arm-openwrt-linux-gcc --version
```

### 问题2: 运行时找不到so库

```bash
# 在设备上
export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH
ldconfig
```

### 问题3: GPIO权限被拒绝

```bash
# 在设备上
chmod 666 /sys/class/gpio/export
chmod 666 /sys/class/gpio/unexport
# 或以root运行
```

### 问题4: 摄像头无法打开

```bash
# 检查设备节点
ls -l /dev/video*

# 检查权限
chmod 666 /dev/video0

# 检查驱动
lsmod | grep video
dmesg | grep video
```

## 🔗 相关链接

- [V853项目主README](../../README.md)
- [Docker开发环境指南](../../DOCKER_GUIDE.md)
- [快速入门指南](../../QUICK_START.md)
- [完整使用手册](../../USAGE.md)

## 📄 许可证

本SDK遵循与主项目相同的许可证。

## 🙏 致谢

本SDK基于RV1109 AI Glass SDK v1.1移植和改进。

---

**版本**: v2.0.0-v853
**最后更新**: 2026-01-23
**维护者**: OpenSource AI Glasses Team
