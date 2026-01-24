# 🔧 完整重建步骤

**问题**: CMake缓存了错误的路径
**解决**: 彻底清理 + 重启容器 + 重新编译

---

## ✅ 步骤1: 清理（已完成）

构建目录已清理：
- ✅ `src/sdk_adapter/build`
- ✅ `src/display_qt/build-v853`
- ✅ `src/ffm_launcher/build-v853`
- ✅ `src/touchpad_manager/build-v853`
- ✅ CMake缓存文件

---

## 🔄 步骤2: 重启Docker容器（重要！）

**为什么需要重启?**
- 环境变量更改需要容器重启才能生效
- 确保 `V853_SDK_PATH=/opt/v853_sdk`

**执行命令**:
```bash
./start-docker.sh restart
```

或者:
```bash
./start-docker.sh stop
./start-docker.sh start
```

---

## 🔍 步骤3: 验证环境变量

进入容器验证环境：

```bash
./start-docker.sh shell
```

**在容器内执行**:
```bash
# 检查环境变量
echo "V853_SDK_PATH = $V853_SDK_PATH"
echo "TOOLCHAIN_PATH = $TOOLCHAIN_PATH"
echo "STAGING_DIR = $STAGING_DIR"

# 检查SDK目录
ls -la /opt/v853_sdk

# 检查工具链
ls -la /opt/v853_sdk/prebuilt/rootfsbuilt/arm/toolchain-sunxi-musl-gcc-830/toolchain/bin/arm-openwrt-linux-gcc
```

**预期输出**:
```bash
V853_SDK_PATH = /opt/v853_sdk  ✓
TOOLCHAIN_PATH = /opt/v853_sdk/prebuilt/.../toolchain  ✓
STAGING_DIR = /opt/v853_sdk/prebuilt/.../toolchain  ✓

/opt/v853_sdk:
drwxr-xr-x  buildroot
drwxr-xr-x  kernel
drwxr-xr-x  prebuilt
...

/opt/v853_sdk/.../arm-openwrt-linux-gcc  ✓ 存在且可执行
```

---

## 🛠️ 步骤4: 重新编译

### 方式1: 使用Makefile（推荐）

**在容器内**:
```bash
cd /workspace

# 编译SDK（如果之前清理了）
make sdk

# 编译应用层
make app

# 或者编译所有
make all
```

### 方式2: 使用build_all.sh

**在容器内**:
```bash
cd /workspace

# 编译所有
./build_all.sh
```

### 方式3: 逐个编译

**在容器内**:
```bash
cd /workspace

# 1. SDK适配层
cd src/sdk_adapter
rm -rf build && mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake
make -j4

# 2. Qt显示应用
cd ../../display_qt
rm -rf build-v853 && mkdir build-v853 && cd build-v853
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake
make -j4

# 3. FFmpeg启动器
cd ../../ffm_launcher
rm -rf build-v853 && mkdir build-v853 && cd build-v853
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake
make -j4

# 4. GPIO管理器
cd ../../touchpad_manager
rm -rf build-v853 && mkdir build-v853 && cd build-v853
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake
make -j4
```

---

## 📊 步骤5: 验证编译结果

### 检查CMake输出

**成功的CMake输出应该是**:
```
-- 使用环境变量 V853_SDK_PATH: /opt/v853_sdk  ✓
-- V853 Toolchain Configuration:
--   SDK Path: /opt/v853_sdk  ✓
--   Toolchain: /opt/v853_sdk/prebuilt/.../toolchain  ✓
--   C Compiler: /opt/v853_sdk/.../arm-openwrt-linux-gcc  ✓
--   CXX Compiler: /opt/v853_sdk/.../arm-openwrt-linux-g++  ✓
--   Sysroot: /opt/v853_sdk/buildroot/.../target  ✓
-- The C compiler identification is GNU 8.3.0  ✓
-- The CXX compiler identification is GNU 8.3.0  ✓
```

**关键点**:
- ✅ 所有路径都以 `/opt/v853_sdk` 开头（容器路径）
- ✅ 编译器被正确识别（GNU 8.3.0）
- ✅ 没有 "compiler not found" 错误

### 检查编译输出

```bash
# SDK库
ls -lh /workspace/src/sdk_adapter/build/libai_glass_sdk_v853.*

# Qt应用
ls -lh /workspace/src/display_qt/build-v853/AIGlassesDisplay_V853

# FFmpeg启动器
ls -lh /workspace/src/ffm_launcher/build-v853/FFlaunch

# GPIO管理器
ls -lh /workspace/src/touchpad_manager/build-v853/touchpad_manager
```

---

## 🐛 如果仍然失败

### 问题A: 环境变量仍然错误

**症状**: `V853_SDK_PATH` 不是 `/opt/v853_sdk`

**解决**:
```bash
# 退出容器
exit

# 完全删除容器并重建
./start-docker.sh clean
./start-docker.sh start
./start-docker.sh shell

# 验证
echo $V853_SDK_PATH
```

### 问题B: 工具链不存在

**症状**:
```
-- The C compiler identification is unknown
```

**检查**:
```bash
./start-docker.sh shell
ls -la /opt/v853_sdk/prebuilt/rootfsbuilt/arm/
```

**如果目录不存在**: 检查SDK挂载是否正确
```bash
# 在主机上检查
ls -la SDK/tina-v853-open/prebuilt/rootfsbuilt/arm/
```

### 问题C: 权限问题

**症状**:
```
Permission denied
```

**解决**:
```bash
./start-docker.sh shell
sudo chown -R $(whoami):$(whoami) /workspace
```

---

## 📝 快速命令清单

```bash
# 1. 重启容器（必须！）
./start-docker.sh restart

# 2. 进入容器
./start-docker.sh shell

# 3. 验证环境
echo $V853_SDK_PATH  # 应该是 /opt/v853_sdk
ls /opt/v853_sdk     # 应该看到 buildroot, kernel, prebuilt

# 4. 编译
cd /workspace
make all

# 5. 检查结果
find src -name "*.so" -o -name "*.a" | head -5
```

---

## 🎯 总结

**核心问题**: CMake缓存 + 环境变量未刷新

**解决方案**:
1. ✅ 清理所有构建目录和CMake缓存
2. 🔄 **重启Docker容器**（最关键！）
3. 🔍 验证环境变量
4. 🛠️ 重新编译

---

**现在执行**: `./start-docker.sh restart` 然后重新编译！
