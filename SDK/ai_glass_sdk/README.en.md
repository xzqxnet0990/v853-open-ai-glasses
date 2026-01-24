# AI Glass SDK - V853 Platform

[中文版本](README.md) | English Version

## 🎯 Introduction

This SDK provides a complete client development kit for AI smart glasses based on the Allwinner V853 platform, supporting GPIO event subscription, camera capture, and audio playback functions.

**Target Platform**: DongshanPI-AICT V853 Development Board
**Toolchain**: arm-openwrt-linux-gcc (Tina Linux)
**Version**: v2.0.0-v853

## 📦 SDK Contents

```
ai_glass_sdk/
├── include/              # Header files
│   ├── ai_gpio.h         # GPIO event client API
│   ├── ai_camera.h       # Camera client API
│   ├── ai_audio.h        # Audio client API
│   ├── ai_display.h      # Display client API
│   ├── ai_text_event.h   # Text event API
│   ├── ai_ipc.h          # IPC communication API
│   ├── ai_log.h          # Logging system API
│   ├── http_client.h     # HTTP client API
│   └── ws_client.h       # WebSocket client API
│
├── lib/                  # Compiled libraries
│   ├── libai_glass_sdk.a # Static library (V853 version)
│   └── libai_glass_sdk.so# Shared library (V853 version)
│
├── examples/             # Example programs
│   ├── gpio_example/     # GPIO event example
│   ├── camera_capture_example/  # Camera capture example
│   ├── audio_play_example/      # Audio playback example
│   ├── text_event_example/      # Text event example
│   ├── http_example/            # HTTP client example
│   └── websocket_example/       # WebSocket example
│
├── docs/                 # API documentation
│   ├── GPIO_Client_API.en.md       # GPIO API docs
│   ├── Camera_Client_API.en.md     # Camera API docs
│   ├── Audio_Client_API.en.md      # Audio API docs
│   ├── Display_Client_API.en.md    # Display API docs
│   ├── Text_Event_Client_API.en.md # Text event API docs
│   └── Log_API.en.md               # Logging API docs
│
├── README.md             # Chinese README
├── README.en.md          # This file
├── Makefile              # SDK build script
└── VERSION               # Version information
```

## 🎯 Main Features

### 1. GPIO Event Subscription
- Multi-process GPIO button event monitoring
- Asynchronous event callback mechanism
- Low latency (< 13ms)
- **V853 Feature**: Linux GPIO sysfs interface

### 2. Camera Capture
- Zero-copy image transfer via shared memory
- JPEG and NV12 format support
- Multi-client concurrent access
- **V853 Feature**: V4L2 standard interface, 1080P@60fps

### 3. Audio Playback Control
- Unix Socket communication for audio control
- Volume adjustment and sample rate configuration
- Force play and stop functions
- **V853 Feature**: ALSA/tinyalsa audio framework

### 4. Display Control
- MIPI DSI display control
- Qt5 GUI support
- Resolution: 1280x720@60Hz

### 5. Network Communication
- HTTP client (mongoose-based)
- WebSocket client
- JSON data exchange support

## 🚀 Quick Start

### Requirements

#### Docker Environment (Recommended)
```bash
cd v853-ai-glasses
./start-docker.sh start
./start-docker.sh shell
```

#### Local Environment
- V853 cross-compilation toolchain
- CMake 3.10+
- Make

### Build SDK Libraries

```bash
cd SDK/ai_glass_sdk

# Build using Makefile
make

# Output:
# lib/libai_glass_sdk.a   - Static library
# lib/libai_glass_sdk.so  - Shared library
```

### Build Example Programs

```bash
# Build all examples
make examples

# Or build individually
cd examples/gpio_example
make

cd ../camera_capture_example
make
```

## 📝 Usage Examples

### 1. GPIO Event Subscription

```c
#include "ai_gpio.h"

// Define callback function
void gpio_callback(int gpio_num, gpio_event_t event, void *user_data) {
    if (event == GPIO_EVENT_PRESSED) {
        printf("Button pressed: GPIO %d\n", gpio_num);
    }
}

int main() {
    // Initialize GPIO client
    gpio_client_t *client = gpio_client_init(NULL);

    // Subscribe to GPIO event (V853: PH9 = 7*32+9 = 233)
    gpio_client_subscribe(client, 233, gpio_callback, NULL);

    // Wait for events
    sleep(60);

    // Cleanup
    gpio_client_cleanup(client);
    return 0;
}
```

**Compile**:
```bash
arm-openwrt-linux-gcc -o gpio_test gpio_test.c \
    -I./include -L./lib -lai_glass_sdk -lpthread -lrt
```

### 2. Camera Capture

```c
#include "ai_camera.h"

int main() {
    // Initialize camera client
    ai_core_client_t *camera = ai_core_init();

    // Capture one frame (1920x1080, NV12)
    ai_core_data_t data;
    if (ai_core_capture(camera, &data, 2000) == 0) {
        printf("Captured frame: %dx%d, %d bytes\n",
               data.width, data.height, data.size);

        // Process image data.data

        // Free data
        ai_core_free_data(&data);
    }

    // Cleanup
    ai_core_cleanup(camera);
    return 0;
}
```

### 3. Audio Playback

```c
#include "ai_audio.h"

int main() {
    // Initialize audio client
    ai_audio_t *audio = ai_audio_init(NULL);

    // Configure playback parameters
    ai_audio_params_t params = ai_audio_create_default_params("/path/to/audio.pcm");
    params.volume = 80;          // Volume 80%
    params.sample_rate = 16000;  // 16kHz
    params.channels = 1;         // Mono
    params.bit_width = 16;       // 16-bit

    // Play audio
    ai_audio_play(audio, &params);

    // Cleanup
    ai_audio_cleanup(audio);
    return 0;
}
```

## 🏗️ V853 Platform Features

### Hardware Interface Mapping

| Function | RV1109 Implementation | V853 Implementation |
|----------|----------------------|---------------------|
| **Camera** | Rockchip ISP + RKMPP | V4L2 (/dev/video0) |
| **GPIO** | Rockchip GPIO driver | Linux GPIO sysfs |
| **Audio** | Rockchip ALSA | ALSA/tinyalsa |
| **Display** | DRM/KMS | MIPI DSI + DRM/KMS |

### GPIO Number Calculation (V853)

V853 GPIO Number = Bank * 32 + Pin

Examples:
- **PH9** = 7 * 32 + 9 = **233** (Left button)
- **PH10** = 7 * 32 + 10 = **234** (Right button)
- **PA0** = 0 * 32 + 0 = **0**
- **PB5** = 1 * 32 + 5 = **37**

Bank mapping: PA=0, PB=1, PC=2, PD=3, PE=4, PF=5, PG=6, PH=7

## 📚 API Documentation

For detailed API documentation, see the `docs/` directory:

- [GPIO Client API](docs/GPIO_Client_API.en.md)
- [Camera Client API](docs/Camera_Client_API.en.md)
- [Audio Client API](docs/Audio_Client_API.en.md)
- [Display Client API](docs/Display_Client_API.en.md)
- [Text Event API](docs/Text_Event_Client_API.en.md)
- [Logging API](docs/Log_API.en.md)

## 🐛 Debugging and Testing

### Enable Debug Logging

```c
#include "ai_log.h"

// At the beginning of main function
ai_log_init(AI_LOG_DEBUG);  // Enable DEBUG level
ai_log_set_color(1);        // Enable colored output
```

### Test GPIO

```bash
# Export GPIO
echo 233 > /sys/class/gpio/export

# Set as input
echo in > /sys/class/gpio/gpio233/direction

# Set interrupt type
echo both > /sys/class/gpio/gpio233/edge

# Read value
cat /sys/class/gpio/gpio233/value
```

## 🔄 Migration from RV1109

If you have code based on RV1109, migrate to V853 platform:

1. **API Compatible**: SDK APIs are fully compatible, no application code changes needed
2. **GPIO Numbers**: Update GPIO number calculation (see above)
3. **Recompile**: Rebuild with V853 toolchain
4. **Test**: Validate all functions on V853 hardware

## 📦 Installation to Device

### Method 1: Using Deployment Script

```bash
# From project root
cd v853-ai-glasses
./deploy.sh 192.168.1.100  # SSH deployment
# or
./deploy.sh adb            # ADB deployment
```

### Method 2: Manual Installation

```bash
# Copy SDK library to device
scp lib/libai_glass_sdk.so root@192.168.1.100:/usr/lib/

# Set library path
ssh root@192.168.1.100
export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH
```

## 🆘 Troubleshooting

### Issue 1: Toolchain Not Found

```bash
# Docker environment
./start-docker.sh restart
./start-docker.sh shell

# Local environment
export PATH=/path/to/v853/toolchain/bin:$PATH
arm-openwrt-linux-gcc --version
```

### Issue 2: Shared Library Not Found at Runtime

```bash
# On device
export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH
ldconfig
```

### Issue 3: GPIO Permission Denied

```bash
# On device
chmod 666 /sys/class/gpio/export
chmod 666 /sys/class/gpio/unexport
# Or run as root
```

## 🔗 Related Links

- [V853 Project Main README](../../README.md)
- [Docker Development Guide](../../DOCKER_GUIDE.md)
- [Quick Start Guide](../../QUICK_START.md)
- [Complete Usage Manual](../../USAGE.md)

## 📄 License

This SDK follows the same license as the main project.

## 🙏 Acknowledgments

This SDK is ported and improved from RV1109 AI Glass SDK v1.1.

---

**Version**: v2.0.0-v853
**Last Updated**: 2026-01-23
**Maintainer**: OpenSource AI Glasses Team
