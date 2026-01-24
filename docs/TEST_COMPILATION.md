# 编译测试计划

**日期**: 2026-01-24
**目标**: 验证修改后的build_all.sh可以成功编译ffm_launcher和touchpad_manager

---

## 🧪 测试步骤

### 1. 进入Docker容器

```bash
cd /Users/xzqxnet/Documents/beike/research/OpenSource-Ai-Glasses/v853-ai-glasses
./start-docker.sh shell
```

### 2. 验证环境变量

在容器内执行：
```bash
echo "V853_SDK_PATH = $V853_SDK_PATH"
echo "TOOLCHAIN_PATH = $TOOLCHAIN_PATH"
echo "STAGING_DIR = $STAGING_DIR"

# 应该输出:
# V853_SDK_PATH = /opt/v853_sdk
# TOOLCHAIN_PATH = /opt/v853_sdk/prebuilt/rootfsbuilt/arm/toolchain-sunxi-musl-gcc-830/toolchain
# STAGING_DIR = /opt/v853_sdk/prebuilt/rootfsbuilt/arm/toolchain-sunxi-musl-gcc-830/toolchain
```

### 3. 执行编译

```bash
cd /workspace
make app
```

或者：
```bash
./build_all.sh app
```

### 4. 预期输出

```
=== V853 AI Glasses Build Script ===
Project root: /workspace
Found V853 SDK: SDK/tina-v853-open

⚠️  跳过 display-qt（需要Qt5支持，Buildroot未编译）

[3/4] 编译 FFmpeg 启动器...
-- V853 Toolchain Configuration:
--   使用环境变量 V853_SDK_PATH: /opt/v853_sdk
--   SDK Path: /opt/v853_sdk
--   Toolchain: /opt/v853_sdk/prebuilt/rootfsbuilt/arm/toolchain-sunxi-musl-gcc-830/toolchain
--   C Compiler: /opt/v853_sdk/prebuilt/.../arm-openwrt-linux-gcc
--   CXX Compiler: /opt/v853_sdk/prebuilt/.../arm-openwrt-linux-g++
-- The C compiler identification is GNU 8.3.0
-- The CXX compiler identification is GNU 8.3.0
...
FFmpeg启动器编译完成
  输出: FFlaunch

[4/4] 编译 GPIO 管理器...
...
GPIO管理器编译完成
  输出: touchpad_manager

Done!
```

### 5. 验证编译产物

```bash
# 检查FFmpeg启动器
ls -lh /workspace/src/ffm_launcher/build-v853/FFlaunch
file /workspace/src/ffm_launcher/build-v853/FFlaunch

# 检查GPIO管理器
ls -lh /workspace/src/touchpad_manager/build-v853/touchpad_manager
file /workspace/src/touchpad_manager/build-v853/touchpad_manager

# 应该看到:
# FFlaunch: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), dynamically linked...
# touchpad_manager: ELF 32-bit LSB executable, ARM, EABI5 version 1 (SYSV), dynamically linked...
```

---

## ✅ 成功标准

1. ✅ display-qt被跳过，显示警告信息
2. ✅ ffm_launcher编译成功，生成FFlaunch可执行文件
3. ✅ touchpad_manager编译成功，生成touchpad_manager可执行文件
4. ✅ 所有编译的二进制文件都是ARM架构
5. ✅ 没有编译错误或严重警告

---

## ❌ 可能的问题

### 问题1: 环境变量未设置

**症状**: CMake找不到编译器

**解决**:
```bash
# 退出容器
exit

# 重启容器
./start-docker.sh restart

# 重新进入
./start-docker.sh shell
```

### 问题2: CMake缓存问题

**症状**: 编译器路径仍然使用主机路径

**解决**:
```bash
cd /workspace
find src -name "build-v853" -type d -exec rm -rf {} + 2>/dev/null
make app
```

### 问题3: 依赖库未找到

**症状**: 链接时找不到libai_glass_sdk_v853

**解决**:
```bash
# 先编译SDK
cd /workspace
make sdk

# 再编译应用
make app
```

---

## 📊 测试结果记录

### 测试环境
- 主机系统: macOS (Apple Silicon)
- Docker: OrbStack / Docker Desktop
- 镜像: aiglasses/v853-dev

### 编译结果

| 组件 | 状态 | 输出文件 | 文件大小 | 架构 |
|------|------|---------|---------|------|
| SDK适配层 | ✅ | libai_glass_sdk_v853.a | | ARM |
| SDK适配层 | ✅ | libai_glass_sdk_v853.so | | ARM |
| FFmpeg启动器 | ⏳ | FFlaunch | | ARM |
| GPIO管理器 | ⏳ | touchpad_manager | | ARM |
| Qt显示应用 | ⏸️ 跳过 | - | - | - |

### 编译时间

- SDK适配层: ~X分钟
- FFmpeg启动器: ~X分钟
- GPIO管理器: ~X分钟
- 总计: ~X分钟

---

## 🎯 下一步

编译成功后:

1. 将二进制文件部署到V853设备
2. 测试FFmpeg视频/音频功能
3. 测试GPIO按键响应
4. 验证SDK API调用
5. 如需GUI，再编译Buildroot和Qt5

---

**准备开始测试编译！** 🚀
