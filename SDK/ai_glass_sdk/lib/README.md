# AI Glass SDK - Library Directory

## 📦 库文件说明

本目录用于存放编译后的SDK库文件。

## 📂 预期内容

编译完成后，本目录应包含：

```
lib/
├── libai_glass_sdk.a      # 静态库
├── libai_glass_sdk.so     # 动态库
└── README.md              # 本文件
```

## 🔨 如何生成库文件

### 方式1: 使用项目构建脚本（推荐）

```bash
# 从项目根目录
cd v853-ai-glasses

# Docker环境
./start-docker.sh start
./start-docker.sh build-sdk

# 本地环境
make sdk
```

### 方式2: 手动编译SDK适配层

```bash
# 1. 进入SDK适配层目录
cd src/sdk_adapter

# 2. 创建构建目录
mkdir -p build && cd build

# 3. 配置CMake
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake -DCMAKE_BUILD_TYPE=Release

# 4. 编译
make -j$(nproc)

# 5. 复制到SDK lib目录
cp libai_glass_sdk_v853.a ../../SDK/ai_glass_sdk/lib/libai_glass_sdk.a
cp libai_glass_sdk_v853.so ../../SDK/ai_glass_sdk/lib/libai_glass_sdk.so
```

### 方式3: 使用SDK Makefile

```bash
# 从SDK目录编译（需要先有适配层编译产物）
cd SDK/ai_glass_sdk
make
```

## 📋 库文件详情

### libai_glass_sdk.a (静态库)

- **大小**: ~500KB
- **用途**: 静态链接到应用程序
- **优点**: 无运行时依赖
- **缺点**: 增加可执行文件大小

**使用方法**:
```bash
arm-openwrt-linux-gcc -o myapp myapp.c \
    -I../include \
    -L. \
    -lai_glass_sdk \
    -lpthread -lrt
```

### libai_glass_sdk.so (动态库)

- **大小**: ~400KB
- **用途**: 动态链接到应用程序
- **优点**: 减小可执行文件大小，多个应用共享
- **缺点**: 需要在目标设备上安装库文件

**使用方法**:
```bash
# 编译
arm-openwrt-linux-gcc -o myapp myapp.c \
    -I../include \
    -L. \
    -lai_glass_sdk \
    -lpthread -lrt

# 部署到设备
scp libai_glass_sdk.so root@192.168.1.100:/usr/lib/
scp myapp root@192.168.1.100:/usr/bin/

# 在设备上运行
ssh root@192.168.1.100
export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH
/usr/bin/myapp
```

## 🔍 库内容说明

SDK库包含以下模块的实现：

| 模块 | 说明 | 实现文件 |
|------|------|---------|
| **GPIO** | GPIO事件订阅 | src/sdk_adapter/src/ai_gpio_v853.c |
| **Camera** | 摄像头捕获 | src/sdk_adapter/src/ai_camera_v853.c |
| **Audio** | 音频播放 | src/sdk_adapter/src/ai_audio_v853.c |
| **Log** | 日志系统 | src/sdk_adapter/src/ai_log_v853.c |

### V853平台实现特性

- **GPIO**: 使用Linux GPIO sysfs接口 (`/sys/class/gpio/`)
- **Camera**: 使用V4L2标准接口 (`/dev/video0`)
- **Audio**: 使用ALSA/tinyalsa框架 (`hw:0,0`)
- **Log**: 线程安全的彩色日志输出

## 🧪 验证库文件

### 检查库文件类型

```bash
# 静态库
file libai_glass_sdk.a
# 预期输出: current ar archive

# 动态库
file libai_glass_sdk.so
# 预期输出: ELF 32-bit LSB shared object, ARM, ...
```

### 查看库导出的符号

```bash
# 静态库
arm-openwrt-linux-nm libai_glass_sdk.a | grep " T "

# 动态库
arm-openwrt-linux-nm -D libai_glass_sdk.so | grep " T "

# 预期看到的符号:
# - gpio_client_init
# - gpio_client_subscribe
# - ai_core_init
# - ai_core_capture
# - ai_audio_init
# - ai_audio_play
# - ai_log_init
# ...
```

### 检查库依赖

```bash
arm-openwrt-linux-readelf -d libai_glass_sdk.so

# 预期依赖:
# - libpthread.so
# - librt.so
# - libc.so
```

## 📦 部署到设备

### 部署动态库

```bash
# 使用项目部署脚本
cd v853-ai-glasses
./scripts/deploy.sh 192.168.1.100

# 或手动部署
scp SDK/ai_glass_sdk/lib/libai_glass_sdk.so root@192.168.1.100:/usr/lib/

# 在设备上设置库路径
ssh root@192.168.1.100
echo 'export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH' >> /etc/profile
source /etc/profile
```

### 验证部署

```bash
# 在V853设备上
ssh root@192.168.1.100

# 检查库文件
ls -lh /usr/lib/libai_glass_sdk.so

# 检查依赖
ldd /usr/bin/your_app
# 应该显示: libai_glass_sdk.so => /usr/lib/libai_glass_sdk.so
```

## ⚠️ 注意事项

### 1. 工具链匹配

- 库文件必须使用V853的 `arm-openwrt-linux-gcc` 工具链编译
- 不要混用RV1109的库文件或工具链
- Docker环境会自动配置正确的工具链

### 2. 依赖库

库文件依赖以下系统库：
- `libpthread.so` (POSIX线程)
- `librt.so` (实时扩展)
- `libc.so` (标准C库)

这些库在V853 Tina Linux中默认已安装。

### 3. 兼容性

- **不向后兼容**: V853库不能在RV1109设备上使用
- **API兼容**: 但应用层API定义完全相同
- **重新编译**: 从RV1109迁移需要重新编译所有组件

### 4. 版本管理

当前SDK版本: **v2.0.0-v853**

检查版本:
```bash
# 查看VERSION文件
cat ../VERSION

# 或通过Makefile
make version
```

## 🔄 更新库文件

当SDK适配层代码有更新时：

```bash
# 1. 重新编译适配层
cd src/sdk_adapter/build
make

# 2. 复制新的库文件
cp libai_glass_sdk_v853.so ../../SDK/ai_glass_sdk/lib/libai_glass_sdk.so
cp libai_glass_sdk_v853.a ../../SDK/ai_glass_sdk/lib/libai_glass_sdk.a

# 3. 重新编译使用SDK的应用
cd src/display_qt/build-v853
make clean && make

# 4. 重新部署
cd ../../../
./scripts/deploy.sh 192.168.1.100
```

## 🐛 故障排查

### 问题1: 库文件不存在

**症状**:
```
cannot find -lai_glass_sdk
```

**解决**:
```bash
# 检查库文件是否存在
ls -l SDK/ai_glass_sdk/lib/

# 如果不存在，编译SDK适配层
cd src/sdk_adapter
make
```

### 问题2: 运行时找不到so库

**症状**:
```
error while loading shared libraries: libai_glass_sdk.so: cannot open shared object file
```

**解决**:
```bash
# 在设备上设置LD_LIBRARY_PATH
export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH

# 或永久设置
echo 'export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH' >> /etc/profile
source /etc/profile

# 或使用ldconfig
echo "/usr/lib" > /etc/ld.so.conf.d/ai_glass.conf
ldconfig
```

### 问题3: 符号未定义

**症状**:
```
undefined reference to `gpio_client_init'
```

**解决**:
```bash
# 检查是否正确链接了SDK库
# 确保编译命令包含: -lai_glass_sdk

# 检查库文件是否包含该符号
arm-openwrt-linux-nm libai_glass_sdk.so | grep gpio_client_init

# 如果没有该符号，需要重新编译SDK适配层
```

## 📚 相关文档

- [SDK主文档](../README.md) - SDK完整使用指南
- [SDK适配层](../../src/sdk_adapter/README.md) - 库实现说明
- [API文档](../docs/) - 详细API说明
- [示例程序](../examples/) - 使用示例

## 🆘 获取帮助

如果遇到库文件相关问题：

1. 查看SDK主文档: `cat ../README.md`
2. 查看构建日志: `make 2>&1 | tee build.log`
3. 检查工具链: `arm-openwrt-linux-gcc --version`
4. 验证库文件: `file libai_glass_sdk.so`

---

**当前状态**: 📦 库文件目录已准备好，等待编译生成

**下一步**: 运行 `make sdk` 或 `./start-docker.sh build-sdk` 编译生成库文件
