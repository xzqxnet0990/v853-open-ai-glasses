# LVGL Display - Build Instructions

## Quick Start

### In Docker Container

```bash
# Enter Docker container
docker exec -it v853_ai_glasses_dev bash

# Navigate to project
cd /workspace/src/display_lvgl

# Build
mkdir -p build-v853
cd build-v853

cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake \
         -DCMAKE_BUILD_TYPE=Release

make -j4
```

### Or Use Build Script

```bash
# Enter Docker container
docker exec -it v853_ai_glasses_dev bash

# Navigate to project root
cd /workspace

# Build all components (includes LVGL display)
./build_all.sh

# Or build just the LVGL display
cd src/display_lvgl
mkdir -p build-v853
cd build-v853
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake -DCMAKE_BUILD_TYPE=Release
make -j4
```

## Expected Output

```
build-v853/AIGlassesDisplayLVGL    # ARM executable (~150KB)
```

## Verify Binary

```bash
file AIGlassesDisplayLVGL
# Should show: ELF 32-bit LSB executable, ARM, EABI5, ...

ls -lh AIGlassesDisplayLVGL
# Should show: ~150-200KB
```

## Deploy to Device

```bash
# Via ADB
adb push AIGlassesDisplayLVGL /usr/bin/

# Or copy to device
scp AIGlassesDisplayLVGL root@192.168.x.x:/usr/bin/
```

## Run on Device

```bash
# Via ADB shell
adb shell
/usr/bin/AIGlassesDisplayLVGL

# Or via SSH
ssh root@192.168.x.x
/usr/bin/AIGlassesDisplayLVGL
```

## Troubleshooting

### LVGL Headers Not Found

**Error**: `'lvgl/lvgl.h' file not found`

**Solution**: Ensure V853_SDK_PATH is set correctly:

```bash
export V853_SDK_PATH=/opt/v853_sdk
# OR
export V853_SDK_PATH=/workspace/SDK/tina-v853-open
```

Check LVGL exists:
```bash
ls $V853_SDK_PATH/platform/thirdparty/gui/lvgl-8/lvgl/src/
```

### AI Glass SDK Not Found

**Error**: `undefined reference to ai_core_init`

**Solution**: Build AI Glass SDK first:

```bash
cd /workspace
./build_all.sh sdk
```

### Compiler Not Found

**Error**: `arm-openwrt-linux-gcc: not found`

**Solution**: Check toolchain path:

```bash
export V853_SDK_PATH=/opt/v853_sdk
ls $V853_SDK_PATH/prebuilt/rootfsbuilt/arm/toolchain-sunxi-musl-gcc-830/toolchain/bin/arm-openwrt-linux-gcc
```

## Next Steps

After successful compilation:

1. Deploy binary to V853 device
2. Start GPIO service: `touchpad_manager &`
3. Start camera service: `FFlaunch &`
4. Run display application: `AIGlassesDisplayLVGL`
5. Use temple buttons to navigate

## Docker Command Reference

```bash
# Start container
docker start v853_ai_glasses_dev

# Enter container
docker exec -it v853_ai_glasses_dev bash

# Check environment
echo $V853_SDK_PATH
which arm-openwrt-linux-gcc

# Build from scratch
cd /workspace
./build_all.sh clean
./build_all.sh
```

## Files Created

- `AIGlassesDisplayLVGL` - Main executable
- `CMakeCache.txt` - CMake configuration cache
- `Makefile` - Generated makefile
- Object files: `*.o` - Compiled object files
- `cmake_install.cmake` - Install script

## Clean Build

```bash
cd /workspace/src/display_lvgl
rm -rf build-v853
mkdir -p build-v853
cd build-v853
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake -DCMAKE_BUILD_TYPE=Release
make -j4
```

---

**Ready to build!** Run these commands in Docker to compile the LVGL display application.
