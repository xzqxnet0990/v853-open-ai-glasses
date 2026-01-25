# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

V853 AI Glasses platform migration project - porting an RV1109-based open-source smart glasses system to Allwinner V853 SoC. The core architecture uses an **SDK adapter pattern** to maintain API compatibility while implementing V853-specific backends.

**Key Architecture**: Three-layer design with platform-agnostic applications, SDK adapter layer, and V853 hardware implementations.

---

## Development Commands

### Docker Environment

All compilation must occur in a Docker container with the V853 cross-compilation toolchain.

```bash
# Start container (first time builds image)
./start-docker.sh start

# Enter container for development
./start-docker.sh shell

# Quick build from host (runs build in container)
./start-docker.sh build-all

# Deploy to device via SSH
./start-docker.sh deploy-ssh 192.168.1.100

# Deploy via ADB
./start-docker.sh deploy-adb

# Stop container
./start-docker.sh stop
```

### Building Applications

**Inside Docker container** (`./start-docker.sh shell` first):

```bash
# Build everything (SDK + all applications)
./build_all.sh

# Build specific components
make sdk          # Only SDK adapter layer
make app          # Only applications (LVGL, FFmpeg, GPIO)
make clean        # Clean all build artifacts

# Individual component builds
cd src/sdk_adapter && mkdir -p build && cd build
cmake .. && make

cd src/display_lvgl && mkdir -p build-v853 && cd build-v853
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake && make
```

### Testing on Device

```bash
# Deploy all binaries
./deploy.sh 192.168.1.100   # or ./deploy.sh adb

# SSH into device
ssh root@192.168.1.100

# On device - start services
/usr/bin/touchpad_manager &      # GPIO event manager
/usr/bin/FFlaunch &              # Camera/video service
/usr/bin/AIGlassesDisplayLVGL    # LVGL GUI application

# Test SDK directly
/usr/bin/examples/camera_test    # Camera capture test
/usr/bin/examples/audio_test /tmp/test.pcm
```

### Firmware Compilation (Advanced)

**Only needed for kernel modifications**. For application development, use official firmware + deploy applications.

```bash
# Inside container
./firmware.sh           # Interactive menu
./firmware.sh status    # Check compilation status
./firmware.sh kernel    # Compile kernel only
./firmware.sh pack      # Pack firmware image
```

---

## Architecture & Code Structure

### SDK Adapter Pattern (Critical Concept)

The codebase uses a two-layer SDK design to enable platform abstraction:

```
SDK/ai_glass_sdk/          # Reference API definitions (RV1109)
  ├── include/             # Original API headers
  └── README.md

src/sdk_adapter/           # V853 implementation
  ├── include/             # Same API headers (RV1109 compatible)
  ├── src/                 # V853-specific implementations
  │   ├── ai_camera_v853.c     # V4L2 implementation
  │   ├── ai_gpio_v853.c       # GPIO sysfs implementation
  │   ├── ai_audio_v853.c      # ALSA implementation
  │   └── ai_log_v853.c        # Thread-safe logging
  └── CMakeLists.txt       # Builds libai_glass_sdk_v853.{a,so}
```

**Key Insight**: Applications use RV1109 API headers but link against V853 implementations. This allows zero-change application migration.

### Component Relationships

```
Application Startup Order:
1. touchpad_manager → Exports GPIO, listens for button interrupts
2. FFlaunch → Initializes camera via SDK adapter
3. display_lvgl → Subscribes to GPIO events, displays UI
```

**Dependencies**:
- All applications link against `libai_glass_sdk_v853.{a,so}`
- LVGL app uses V853 SDK's included LVGL 8.x library
- FFmpeg launcher uses system FFmpeg

### Hardware Abstraction Details

**Camera**: V4L2 (`/dev/video0`) instead of Rockchip MPP
**GPIO**: Linux sysfs (`/sys/class/gpio/`) with pin mapping: `gpio_num = bank * 32 + pin`
**Display**: Direct framebuffer (`/dev/fb0`) for LVGL rendering
**Audio**: Standard ALSA interface

### Platform-Specific Notes

**V853 GPIO Pin Mapping**:
```c
// Example: PH9 = Bank H (7) * 32 + Pin 9 = 233
PH9  (Left button)  = 233
PH10 (Right button) = 234
```

**Display Configuration**:
- MIPI DSI interface, 1280x720@60Hz
- LVGL renders directly to framebuffer (zero-copy)

**Camera Configuration**:
- Format: NV12 (YUV 4:2:0)
- Resolution: 1920x1080
- ISP: Allwinner VIND framework

---

## Build System Architecture

### CMake Toolchain Pattern

**Critical Rule**: Never hardcode compiler paths in `CMakeLists.txt`. Always use toolchain files.

```cmake
# ✅ Correct: Use toolchain file
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake

# ❌ Wrong: Hardcode paths in CMakeLists.txt
set(CMAKE_C_COMPILER "/opt/v853_sdk/...")  # Don't do this!
```

**Toolchain File Structure** (`toolchain-v853.cmake`):
```cmake
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR arm)

# Finds toolchain via V853_SDK_PATH environment variable
find_program(CMAKE_C_COMPILER arm-openwrt-linux-gcc ...)
set(CMAKE_SYSROOT "${TOOLCHAIN_PATH}")
set(CMAKE_C_FLAGS "-march=armv7-a -mfpu=neon ...")
```

### Environment Variables

The build system relies on these variables (set by `docker-compose.yml`):

```bash
V853_SDK_PATH=/opt/v853_sdk              # SDK root in container
TOOLCHAIN_PATH=/opt/v853_sdk/.../toolchain
STAGING_DIR=$TOOLCHAIN_PATH              # OpenWrt compatibility
PATH includes toolchain/bin
```

### Docker Configuration

**Important**: The Docker container forces `platform: linux/amd64` because:
- V853 toolchain is x86_64 only
- Apple Silicon Macs need Rosetta translation
- This is expected behavior, not an error

**Volume Mounts**:
```yaml
/workspace           → Project root (read/write)
/opt/v853_sdk        → Tina SDK (read-only)
/root/.buildcache    → Compilation cache
```

---

## Common Development Patterns

### Adding New SDK Functions

1. Add function declaration to `src/sdk_adapter/include/ai_*.h`
2. Implement V853-specific version in `src/sdk_adapter/src/ai_*_v853.c`
3. Export symbol in `CMakeLists.txt` if needed
4. Rebuild SDK: `make sdk`
5. Applications automatically get new functionality

### Creating New Applications

```bash
cd src/
mkdir my_new_app
cd my_new_app

# Create toolchain file (copy from other apps)
cp ../display_lvgl/toolchain-v853.cmake .

# Create CMakeLists.txt
cat > CMakeLists.txt << 'EOF'
cmake_minimum_required(VERSION 3.10)
project(MyNewApp C)

find_library(AI_SDK ai_glass_sdk_v853 PATHS ${SDK_LIB_PATH})
add_executable(MyNewApp main.c)
target_link_libraries(MyNewApp ${AI_SDK} pthread rt)
EOF

# Add to build_all.sh
# Edit build_all.sh and add a build_my_app() function
```

### Debugging Build Issues

**Problem**: `CMAKE_C_COMPILER not found`
**Solution**: Ensure you're in Docker container and `V853_SDK_PATH` is set

**Problem**: `cannot find -lai_glass_sdk_v853`
**Solution**: Build SDK first: `make sdk` or `./build_all.sh sdk`

**Problem**: Kernel header errors in userspace code
**Solution**: Check `#include` paths - use toolchain's userspace headers, not kernel headers

**Problem**: Docker platform warning on Apple Silicon
**Solution**: This is expected (x86_64 emulation). Ignore unless build fails.

---

## Project-Specific Conventions

### Code Organization

- `src/sdk_adapter/`: Platform abstraction layer - **never include hardware-specific code here beyond the implementation files**
- `src/display_lvgl/`: LVGL GUI application - keep UI logic separate from hardware
- `src/ffm_launcher/`: Video encoding/streaming service
- `src/touchpad_manager/`: GPIO event distribution daemon

### Documentation Standards

This project maintains extensive documentation:
- `docs/`: All major documentation files
- `docs/archive/`: Historical build fixes (preserved for reference)
- `docs/reference/`: Deprecated code (qt_legacy, system_services_design, openwrt_packages_legacy)

When making architectural changes, update relevant docs in `docs/`.

### Commit Practices

The project uses descriptive commit messages. Follow the existing pattern:
- Document build fixes in separate markdown files
- Update `CLEANUP_PLAN.md` when removing code
- Preserve historical context (moved to `docs/reference/`, not deleted)

---

## Hardware Platform Details

### V853 SoC Capabilities

- **CPU**: ARM Cortex-A7 Dual-core @ 1.4GHz
- **Co-processor**: RISC-V E907 @ 600MHz (not yet utilized)
- **NPU**: 1 TOPS INT8 (not yet integrated)
- **ISP**: 1080P@60fps camera pipeline
- **Memory**: 1GB DDR3

### Target Device Configuration

**Default firmware**: Uses official Tina SDK firmware (pre-built)
**Application deployment**: SSH or ADB push to `/usr/bin/` and `/usr/lib/`
**Runtime environment**: Busybox-based Linux with musl libc

### Peripheral Access

All peripherals use standard Linux interfaces:
- Camera: `/dev/video0` (V4L2 API)
- GPIO: `/sys/class/gpio/gpio*/` (sysfs)
- Display: `/dev/fb0` (framebuffer)
- Audio: ALSA PCM devices

---

## Key Lessons & Gotchas

### Build System Lessons

1. **Never hardcode toolchain paths** in CMakeLists.txt - use toolchain files and environment variables
2. **Kernel headers in userspace**: Don't mix kernel includes with userspace builds
3. **Docker platform**: x86_64 emulation on ARM hosts is expected and working
4. **SDK must build first**: Applications depend on `libai_glass_sdk_v853.so`

### Architectural Decisions

1. **LVGL over Qt**: Chose LVGL for lightweight GUI (5MB vs 40MB memory, 150KB vs 500KB+ binary)
2. **Standard APIs over vendor**: V4L2/ALSA/sysfs instead of proprietary libraries for portability
3. **Application-layer development**: Faster iteration than full firmware compilation (5-10 min vs 30-60 min)
4. **SDK adapter pattern**: Maintains RV1109 API compatibility while implementing V853 backends

### Development Workflow Insights

1. **Docker is mandatory**: No cross-compilation on host directly
2. **Incremental builds**: Use `make sdk` and `make app` for faster iteration
3. **Test on hardware early**: Emulation doesn't cover V853-specific ISP/GPIO behavior
4. **Deploy frequently**: SSH deployment is fast, test often on actual device

---

## Important File Locations

### Build Scripts
- `build_all.sh` - Main build orchestrator (150+ lines)
- `deploy.sh` - Deployment script (SSH/ADB)
- `firmware.sh` - Kernel compilation and firmware packing
- `start-docker.sh` - Docker management wrapper (626 lines)

### Core Source
- `src/sdk_adapter/` - Platform abstraction layer (1,316 LOC)
- `src/display_lvgl/main.c` - LVGL application entry point
- `src/sdk_adapter/include/*.h` - Public SDK API headers

### Configuration
- `docker-compose.yml` - Container configuration with volume mounts
- `Dockerfile` - Development environment definition
- `src/*/toolchain-v853.cmake` - CMake toolchain files (one per app)

### Documentation
- `docs/BUILD_STRATEGY.md` - Compilation strategy explanation
- `docs/DEPLOYMENT_READY.md` - Deployment guide
- `docs/SCRIPTS.md` - Script usage reference
- `CLEANUP_PLAN.md` - Code organization and cleanup history

---

## References

### SDK Documentation
- `SDK/ai_glass_sdk/README.md` - Original RV1109 SDK reference
- `src/sdk_adapter/include/*.h` - API header comments

### Technical Documents
- Review `docs/*.md` for detailed build fixes and architectural decisions
- `docs/archive/` contains historical compilation fixes (learning material)

### Hardware Reference
- V853 datasheet: Check Allwinner documentation
- MIPI DSI driver: `docs/reference/mipi_dsi/`
- GPIO reference: See `src/sdk_adapter/include/ai_gpio.h` for pin mapping formulas
