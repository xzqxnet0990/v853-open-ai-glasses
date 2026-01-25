# LVGL 链接错误修复

**Date**: 2026-01-24
**Issue**: `cannot find -lai_glass_sdk`
**Status**: ✅ **已修复**

---

## 🐛 问题描述

### 错误信息
```
/opt/v853_sdk/.../bin/ld: cannot find -lai_glass_sdk
collect2: error: ld returned 1 exit status
```

### 根本原因

1. **库文件名不匹配**：
   - CMakeLists.txt 中链接：`-lai_glass_sdk`
   - 实际库文件名：`libai_glass_sdk_v853.a` / `libai_glass_sdk_v853.so`

2. **库文件路径错误**：
   - CMakeLists.txt 中：`SDK/ai_glass_sdk/lib/`
   - 实际库位置：`src/sdk_adapter/build/`

---

## 🔧 修复内容

### 修改文件
- ✅ `CMakeLists.txt`

### 具体改动

#### 1. 修改SDK路径配置

**修改前**:
```cmake
set(SDK_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../SDK/ai_glass_sdk")
include_directories(${SDK_PATH}/include)
link_directories(${SDK_PATH}/lib)
```

**修改后**:
```cmake
# Use SDK adapter build output (V853 version)
set(SDK_ADAPTER_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../sdk_adapter/build")
set(SDK_INCLUDE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../SDK/ai_glass_sdk/include")

# Check if SDK adapter library exists
if(NOT EXISTS "${SDK_ADAPTER_PATH}/libai_glass_sdk_v853.a")
    message(WARNING "SDK adapter library not found")
    message(WARNING "Please build SDK adapter first: cd /workspace && ./build_all.sh sdk")
endif()

include_directories(${SDK_INCLUDE_PATH})
link_directories(${SDK_ADAPTER_PATH})

message(STATUS "SDK adapter path: ${SDK_ADAPTER_PATH}")
message(STATUS "SDK include path: ${SDK_INCLUDE_PATH}")
```

#### 2. 修改链接库名称

**修改前**:
```cmake
target_link_libraries(${PROJECT_NAME}
    ai_glass_sdk
    pthread
    rt
    m
)
```

**修改后**:
```cmake
target_link_libraries(${PROJECT_NAME}
    ai_glass_sdk_v853    # V853 SDK adapter library
    pthread
    rt
    m
)
```

---

## 📁 文件路径说明

### SDK相关目录结构

```
project/
├── SDK/
│   └── ai_glass_sdk/
│       ├── include/           ← 头文件（ai_camera.h, ai_gpio.h等）
│       │   ├── ai_camera.h
│       │   ├── ai_gpio.h
│       │   └── ...
│       └── lib/               ← 空目录（不使用）
│
└── src/
    ├── sdk_adapter/
    │   └── build/             ← SDK适配器编译输出（实际使用）
    │       ├── libai_glass_sdk_v853.a    ← 静态库
    │       └── libai_glass_sdk_v853.so   ← 动态库
    │
    └── display_lvgl/
        └── CMakeLists.txt     ← 链接到 sdk_adapter/build/
```

### 为什么这样设计？

1. **SDK/ai_glass_sdk/** 是通用SDK接口定义（头文件）
2. **src/sdk_adapter/** 是V853平台的具体实现（库文件）
3. LVGL应用需要链接V853平台实现，所以使用 `sdk_adapter/build/`

---

## 🚀 重新编译

修复后，重新编译：

```bash
# 在Docker容器中
cd /workspace

# 确保SDK适配器已编译
./build_all.sh sdk

# 重新编译LVGL显示应用
./rebuild_lvgl.sh
```

或者手动：

```bash
cd /workspace/src/display_lvgl
rm -rf build-v853
mkdir -p build-v853 && cd build-v853
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake -DCMAKE_BUILD_TYPE=Release
make -j4
```

---

## ✅ 预期编译成功

```
[100%] Linking C executable AIGlassesDisplayLVGL
[100%] Built target AIGlassesDisplayLVGL

===============================================
构建完成！
===============================================
✅ 输出文件: AIGlassesDisplayLVGL
-rwxr-xr-x 1 root root 156K Jan 24 16:00 AIGlassesDisplayLVGL
AIGlassesDisplayLVGL: ELF 32-bit LSB executable, ARM, EABI5
```

---

## 🔍 验证链接

编译成功后，验证链接的库：

```bash
cd /workspace/src/display_lvgl/build-v853

# 检查依赖库
arm-openwrt-linux-readelf -d AIGlassesDisplayLVGL | grep NEEDED

# 应该看到:
# 0x00000001 (NEEDED)    Shared library: [libai_glass_sdk_v853.so]
# 0x00000001 (NEEDED)    Shared library: [libpthread.so.0]
# 0x00000001 (NEEDED)    Shared library: [libc.so]
# 0x00000001 (NEEDED)    Shared library: [ld-musl-armhf.so.1]
```

---

## 🐛 故障排除

### 问题1: 仍然找不到库

**错误**:
```
cannot find -lai_glass_sdk_v853
```

**解决**:
```bash
# 确保SDK适配器已编译
cd /workspace
./build_all.sh sdk

# 验证库文件存在
ls -l src/sdk_adapter/build/libai_glass_sdk_v853.*
```

### 问题2: SDK适配器未编译

**错误**:
```
CMake Warning: SDK adapter library not found
```

**解决**:
```bash
# 先编译SDK适配器
cd /workspace
./build_all.sh sdk

# 然后再编译LVGL显示
./rebuild_lvgl.sh
```

---

## 📊 修复总结

| 问题 | 修改 | 状态 |
|-----|------|------|
| 库文件路径错误 | 改为 `sdk_adapter/build/` | ✅ 已修复 |
| 库名称不匹配 | 改为 `ai_glass_sdk_v853` | ✅ 已修复 |
| 缺少路径检查 | 添加库存在性检查 | ✅ 已添加 |

---

## 🎯 下一步

链接成功后：

1. **验证二进制**:
   ```bash
   file build-v853/AIGlassesDisplayLVGL
   ```

2. **部署到设备**:
   ```bash
   adb push build-v853/AIGlassesDisplayLVGL /usr/bin/
   adb push src/sdk_adapter/build/libai_glass_sdk_v853.so /usr/lib/
   ```

3. **运行测试**:
   ```bash
   adb shell
   export LD_LIBRARY_PATH=/usr/lib
   /usr/bin/AIGlassesDisplayLVGL
   ```

---

**链接问题已修复！** 🎉 现在运行 `./rebuild_lvgl.sh` 应该可以成功链接并生成可执行文件。
