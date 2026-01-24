# V853 AI Glasses - SDK目录结构说明

## 📂 SDK目录概览

V853项目包含两个SDK目录：

```
v853-ai-glasses/
├── SDK/
│   ├── ai_glass_sdk/         # ⭐ 应用层SDK（客户端库）
│   └── tina-v853-open/       # 🔧 V853官方SDK（系统级）
│
└── src/
    └── sdk_adapter/          # 🔌 SDK适配层（实现层）
```

## 🎯 三层架构

### 1. V853 官方SDK (tina-v853-open/)

**位置**: `SDK/tina-v853-open/`
**大小**: ~15GB
**来源**: Allwinner官方

**作用**:
- 提供V853硬件驱动
- Linux内核源码 (kernel/linux-4.9/)
- Buildroot根文件系统
- 交叉编译工具链
- 固件编译环境

**关键目录**:
```
tina-v853-open/
├── kernel/              # Linux 4.9内核
├── buildroot/           # Buildroot根文件系统
├── prebuilt/            # 预编译工具链
│   └── gcc/linux-x86/arm/toolchain-sunxi-musl/
├── device/config/       # 设备树配置
└── build.sh             # 固件编译脚本
```

**用途**:
- 编译完整固件镜像 (.img)
- 提供工具链给SDK适配层
- 系统级开发和调试

---

### 2. SDK适配层 (src/sdk_adapter/)

**位置**: `src/sdk_adapter/`
**大小**: ~1MB (源码)
**作用**: 平台适配实现层

**架构**:
```
src/sdk_adapter/
├── include/                    # API头文件定义
│   ├── ai_camera.h            # 摄像头API
│   ├── ai_gpio.h              # GPIO API
│   ├── ai_audio.h             # 音频API
│   └── ai_log.h               # 日志API
│
├── src/                        # V853平台实现
│   ├── ai_camera_v853.c       # 基于V4L2
│   ├── ai_gpio_v853.c         # 基于GPIO sysfs
│   ├── ai_audio_v853.c        # 基于ALSA/tinyalsa
│   └── ai_log_v853.c          # 日志实现
│
├── build/                      # 编译输出
│   ├── libai_glass_sdk_v853.a # 静态库
│   ├── libai_glass_sdk_v853.so# 动态库
│   └── examples/              # 测试程序
│
├── CMakeLists.txt             # CMake构建脚本
└── toolchain-v853.cmake       # 工具链配置
```

**功能**:
- 实现RV1109 API定义
- 调用V853硬件接口（V4L2, GPIO, ALSA）
- 编译为库文件供应用层使用

**编译**:
```bash
cd src/sdk_adapter
mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake
make
```

---

### 3. 应用层SDK (SDK/ai_glass_sdk/)

**位置**: `SDK/ai_glass_sdk/`
**大小**: ~2MB
**作用**: 应用开发工具包

**结构**:
```
SDK/ai_glass_sdk/
├── include/                    # 📚 公共API头文件
│   ├── ai_gpio.h              # GPIO事件订阅
│   ├── ai_camera.h            # 摄像头捕获
│   ├── ai_audio.h             # 音频播放
│   ├── ai_display.h           # 显示控制
│   ├── ai_text_event.h        # 文本事件
│   ├── ai_ipc.h               # IPC通信
│   ├── ai_log.h               # 日志系统
│   ├── http_client.h          # HTTP客户端
│   └── ws_client.h            # WebSocket客户端
│
├── lib/                        # 📦 预编译库文件
│   ├── libai_glass_sdk.a      # 静态库
│   ├── libai_glass_sdk.so     # 动态库
│   └── *.o                    # 目标文件
│
├── examples/                   # 💡 示例程序
│   ├── gpio_example/          # GPIO事件监听示例
│   ├── camera_capture_example/# 摄像头捕获示例
│   ├── audio_play_example/    # 音频播放示例
│   ├── text_event_example/    # 文本事件示例
│   ├── http_example/          # HTTP客户端示例
│   └── websocket_example/     # WebSocket示例
│
├── docs/                       # 📖 API文档
│   ├── GPIO_Client_API.md
│   ├── Camera_Client_API.md
│   ├── Audio_Client_API.md
│   ├── Display_Client_API.md
│   ├── Text_Event_Client_API.md
│   └── Log_API.md
│
├── README.md                   # 中文文档
├── README.en.md                # 英文文档
├── Makefile                    # 构建脚本
└── VERSION                     # 版本信息
```

**用途**:
- 应用层开发使用
- 提供完整的API接口
- 包含示例程序和文档
- 可独立分发给第三方开发者

**使用方式**:
```c
// 在应用中包含头文件
#include "ai_gpio.h"
#include "ai_camera.h"

// 链接SDK库
// gcc app.c -I./SDK/ai_glass_sdk/include \
//          -L./SDK/ai_glass_sdk/lib \
//          -lai_glass_sdk -lpthread -lrt
```

---

## 🔄 三层关系

```
┌─────────────────────────────────────────────────┐
│         应用程序 (User Application)              │
│  ┌───────────────────────────────────────────┐  │
│  │  #include "ai_gpio.h"                    │  │
│  │  #include "ai_camera.h"                  │  │
│  │  gpio_client_t *gpio = gpio_client_init()│  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
                      ↓ 链接
┌─────────────────────────────────────────────────┐
│    应用层SDK (SDK/ai_glass_sdk/)                │
│  ┌───────────────────────────────────────────┐  │
│  │  API定义 (include/)                      │  │
│  │  预编译库 (lib/libai_glass_sdk.so)      │  │
│  │  示例程序 (examples/)                    │  │
│  │  文档 (docs/)                            │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
                      ↓ 实现自
┌─────────────────────────────────────────────────┐
│    SDK适配层 (src/sdk_adapter/)                 │
│  ┌───────────────────────────────────────────┐  │
│  │  V853平台实现                             │  │
│  │  • ai_camera_v853.c → V4L2              │  │
│  │  • ai_gpio_v853.c → GPIO sysfs          │  │
│  │  • ai_audio_v853.c → ALSA               │  │
│  │  编译输出: libai_glass_sdk_v853.so      │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
                      ↓ 使用
┌─────────────────────────────────────────────────┐
│    V853官方SDK (SDK/tina-v853-open/)           │
│  ┌───────────────────────────────────────────┐  │
│  │  工具链 (prebuilt/gcc/)                  │  │
│  │  内核驱动 (kernel/)                      │  │
│  │  硬件接口 (V4L2, GPIO, ALSA)            │  │
│  │  固件编译 (build.sh)                     │  │
│  └───────────────────────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

---

## 🎯 使用场景

### 场景1: 应用开发者

**目标**: 开发运行在V853智能眼镜上的应用

**使用SDK**: `SDK/ai_glass_sdk/`

```bash
# 1. 包含SDK头文件
#include "ai_gpio.h"
#include "ai_camera.h"

# 2. 链接SDK库
gcc my_app.c \
    -I./SDK/ai_glass_sdk/include \
    -L./SDK/ai_glass_sdk/lib \
    -lai_glass_sdk -lpthread -lrt

# 3. 部署到设备
scp my_app root@192.168.1.100:/usr/bin/
```

**需要了解**:
- ✅ API文档 (docs/)
- ✅ 示例程序 (examples/)
- ❌ 不需要了解SDK适配层实现
- ❌ 不需要了解V853官方SDK

---

### 场景2: SDK维护者

**目标**: 维护和改进SDK适配层

**使用目录**: `src/sdk_adapter/`

```bash
# 1. 修改适配层代码
vim src/sdk_adapter/src/ai_camera_v853.c

# 2. 编译SDK适配层
cd src/sdk_adapter/build
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake
make

# 3. 更新应用层SDK
cp libai_glass_sdk_v853.so ../../SDK/ai_glass_sdk/lib/libai_glass_sdk.so
```

**需要了解**:
- ✅ V853硬件接口（V4L2, GPIO, ALSA）
- ✅ SDK适配层架构
- ✅ V853官方SDK工具链
- ❌ 不需要修改应用层SDK

---

### 场景3: 系统开发者

**目标**: 定制V853固件，集成SDK

**使用SDK**: `SDK/tina-v853-open/`

```bash
# 1. 进入V853 SDK
cd SDK/tina-v853-open

# 2. 配置环境
source build/envsetup.sh
lunch v853-100ask-tina

# 3. 集成SDK到固件
# 将 src/sdk_adapter/ 编译输出集成到 buildroot/

# 4. 编译固件
./build.sh

# 5. 烧录
# 使用PhoenixCard或其他工具烧录 out/*/image/boot.img
```

**需要了解**:
- ✅ V853硬件架构
- ✅ Buildroot系统
- ✅ 设备树配置
- ✅ 驱动开发

---

## 📊 各层对比

| 层级 | 位置 | 大小 | 用途 | 修改频率 | 开发者 |
|------|------|------|------|---------|--------|
| **V853官方SDK** | SDK/tina-v853-open/ | 15GB | 系统级开发 | 低 | 系统开发者 |
| **SDK适配层** | src/sdk_adapter/ | 1MB | 平台适配 | 中 | SDK维护者 |
| **应用层SDK** | SDK/ai_glass_sdk/ | 2MB | 应用开发 | 高 | 应用开发者 |

---

## 🔧 编译流程

### 完整编译流程

```bash
# 1. 编译SDK适配层
cd src/sdk_adapter
mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake
make
# 输出: libai_glass_sdk_v853.so

# 2. 更新应用层SDK
cp libai_glass_sdk_v853.so ../../../SDK/ai_glass_sdk/lib/libai_glass_sdk.so

# 3. 编译示例程序
cd ../../../SDK/ai_glass_sdk
make examples
# 输出: examples/*/example_binary

# 4. 编译应用层（使用应用层SDK）
cd ../../src/display_qt
mkdir build-v853 && cd build-v853
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake
make
# 链接: SDK/ai_glass_sdk/lib/libai_glass_sdk.so
```

### 简化编译（推荐）

```bash
# 使用Docker环境
./start-docker.sh start
./start-docker.sh build-all

# 或使用Makefile
make all
```

---

## 📚 文档索引

| 文档 | 位置 | 说明 |
|------|------|------|
| SDK结构说明 | 本文档 | SDK目录结构详解 |
| 应用层SDK | SDK/ai_glass_sdk/README.md | 应用开发指南 |
| API文档 | SDK/ai_glass_sdk/docs/ | 详细API文档 |
| 适配层实现 | src/sdk_adapter/README.md | 平台适配说明 |
| V853官方文档 | SDK/tina-v853-open/docs/ | 系统级文档 |

---

## 🆘 常见问题

### Q1: 应该使用哪个SDK目录？

**答**:
- **开发应用**: 使用 `SDK/ai_glass_sdk/`
- **修改SDK实现**: 修改 `src/sdk_adapter/`
- **系统级开发**: 使用 `SDK/tina-v853-open/`

### Q2: 为什么有两个libai_glass_sdk.so？

**答**:
```
src/sdk_adapter/build/libai_glass_sdk_v853.so  # 适配层编译输出
SDK/ai_glass_sdk/lib/libai_glass_sdk.so        # 应用层SDK（从上面复制）
```

适配层编译后，需要手动或通过脚本复制到应用层SDK。

### Q3: 如何添加新的API？

**步骤**:
1. 在 `src/sdk_adapter/include/` 添加头文件
2. 在 `src/sdk_adapter/src/` 实现V853版本
3. 编译适配层: `make sdk`
4. 复制到应用层SDK: `cp ... SDK/ai_glass_sdk/lib/`
5. 同步头文件: `cp include/*.h SDK/ai_glass_sdk/include/`
6. 更新文档: `SDK/ai_glass_sdk/docs/`

### Q4: 应用层SDK可以独立分发吗？

**答**: 可以。`SDK/ai_glass_sdk/` 包含：
- 头文件 (include/)
- 预编译库 (lib/)
- 示例程序 (examples/)
- 完整文档 (docs/)

可以打包为独立SDK给第三方开发者使用，无需提供源码。

---

## 🎉 总结

V853项目采用**三层架构**:

1. **V853官方SDK** - 系统基础，提供工具链和驱动
2. **SDK适配层** - 平台实现，适配V853硬件
3. **应用层SDK** - 开发工具包，面向应用开发者

这种分层设计实现了：
- ✅ **API稳定性** - 应用层API与平台无关
- ✅ **可维护性** - 各层职责清晰
- ✅ **可分发性** - 应用层SDK可独立分发
- ✅ **可扩展性** - 易于添加新功能

**推荐工作流**:
- 应用开发 → 使用 `SDK/ai_glass_sdk/`
- SDK维护 → 修改 `src/sdk_adapter/`
- 系统定制 → 使用 `SDK/tina-v853-open/`

---

**文档版本**: v1.0
**最后更新**: 2026-01-23
