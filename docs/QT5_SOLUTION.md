# Qt5依赖问题解决方案

**日期**: 2026-01-23
**更新**: 2026-01-24 - ✅ 已实施方案A
**问题**: CMake找不到Qt5Config.cmake
**根本原因**: Buildroot尚未编译，没有生成Qt5库和配置文件
**状态**: ✅ 已修改build_all.sh跳过display-qt，其他组件可正常编译

---

> **⚠️ 更新说明**: 方案A已经实施完成。详见 `SKIP_QT5_WORKAROUND.md`

---

## 🔍 问题分析

### 当前状态

```
SDK/tina-v853-open/buildroot/buildroot-201902/
├── source/      ✓ 源码存在
├── configs/     ✓ 配置文件存在
└── output/      ❌ 编译输出不存在（包括Qt5）
```

### 缺失的关键文件

```
output/
└── target/
    └── usr/
        ├── lib/
        │   ├── libQt5Core.so          ❌ Qt5库不存在
        │   ├── libQt5Widgets.so       ❌
        │   └── cmake/Qt5/             ❌ Qt5Config.cmake不存在
        └── include/
            └── qt5/                    ❌ Qt5头文件不存在
```

---

## 💡 解决方案（3种）

### 方案A: 暂时跳过Qt应用（推荐，快速）

**适用场景**:
- 只需要验证SDK编译
- 暂时不需要GUI应用
- 想快速测试其他组件

**步骤**:

1. **修改Makefile，跳过display_qt**

编辑 `Makefile`:
```makefile
# 原来:
app: display-qt ffm-launcher touchpad

# 修改为:
app: ffm-launcher touchpad
    @echo "  ⚠️  跳过display-qt（需要Qt5）"
```

2. **或者修改build_all.sh**

编辑 `build_all.sh`，注释掉Qt编译:
```bash
# 原来:
build_display_qt
build_ffm_launcher
build_touchpad

# 修改为:
# build_display_qt  # 暂时跳过，需要Qt5
build_ffm_launcher
build_touchpad
```

3. **重新编译**
```bash
./start-docker.sh shell
cd /workspace
make app
```

**优点**:
- ✅ 立即可用
- ✅ 其他组件可以正常编译
- ✅ SDK已经成功编译

**缺点**:
- ⚠️ 没有GUI显示应用
- ⚠️ 需要使用命令行测试

---

### 方案B: 使用预编译的Qt5库（中等复杂度）

**适用场景**:
- 需要Qt应用但不想等待长时间编译
- 有预编译的Qt5库可用

**步骤**:

1. **查找预编译的Qt5**

V853 SDK可能在其他位置有预编译的Qt5:
```bash
find SDK/tina-v853-open -name "libQt5Core.so*" 2>/dev/null
find SDK/tina-v853-open/prebuilt -name "*qt*" -type d 2>/dev/null
```

2. **如果找到，添加Qt5路径到CMakeLists.txt**

编辑 `src/display_qt/CMakeLists.txt`:
```cmake
# 在 find_package(Qt5 ...) 之前添加:
set(CMAKE_PREFIX_PATH
    "/opt/v853_sdk/prebuilt/qt5"  # 替换为实际路径
    ${CMAKE_PREFIX_PATH}
)

find_package(Qt5 REQUIRED COMPONENTS Core Widgets Gui)
```

3. **重新编译**
```bash
cd /workspace/src/display_qt
rm -rf build-v853
mkdir build-v853 && cd build-v853
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake
make
```

---

### 方案C: 编译完整的Buildroot（耗时，完整）

**适用场景**:
- 需要完整的系统环境
- 有时间等待编译（2-4小时）
- 准备生成最终固件

**步骤**:

1. **在Docker容器内进入Tina SDK**
```bash
./start-docker.sh shell
cd /opt/v853_sdk
```

2. **选择配置**
```bash
source build/envsetup.sh
lunch  # 选择对应的产品配置
```

3. **配置Buildroot启用Qt5**
```bash
make menuconfig

# 在menuconfig中选择:
Target packages --->
    Graphic libraries and applications (graphic/text) --->
        [*] Qt5
            [*] gui module
            [*] widgets module
            [*] network module
```

4. **编译Buildroot**
```bash
make  # 这会花费2-4小时
```

5. **验证Qt5**
```bash
ls buildroot/buildroot-201902/output/target/usr/lib/libQt5*.so
```

6. **重新编译应用**
```bash
cd /workspace
make app
```

---

## 🎯 推荐方案：方案A（暂时跳过Qt应用）

**理由**:
1. SDK编译已经成功 ✅
2. 其他组件（FFmpeg、GPIO）可以独立工作
3. 可以先测试核心功能
4. 节省大量编译时间
5. 后续需要时再编译Buildroot

---

## 📝 具体实施：修改Makefile

编辑项目根目录的 `Makefile`:

```makefile
# 找到 app target，修改为:
app: sdk ffm-launcher touchpad
    @echo "  ✓ 应用层编译完成（跳过display-qt）"
    @echo ""
    @echo "  ⚠️  注意: display-qt需要Qt5支持，已暂时跳过"
    @echo "  如需编译Qt应用，请先编译Buildroot: make buildroot"
    @echo ""

# 添加单独的display-qt target
display-qt: sdk
    @echo "[2/4] 编译 Qt 显示应用..."
    cd src/display_qt && \
    mkdir -p build-v853 && cd build-v853 && \
    cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc)

# 保留原来的target
ffm-launcher: sdk
    @echo "[3/4] 编译 FFmpeg 启动器..."
    cd src/ffm_launcher && \
    mkdir -p build-v853 && cd build-v853 && \
    cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc)

touchpad: sdk
    @echo "[4/4] 编译 GPIO 管理器..."
    cd src/touchpad_manager && \
    mkdir -p build-v853 && cd build-v853 && \
    cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc)
```

---

## 🚀 立即执行

### 步骤1: 修改Makefile（或build_all.sh）

选择一个修改：

**选项1**: 修改 `Makefile`（如上所示）

**选项2**: 修改 `build_all.sh`，注释掉 `build_display_qt` 调用

### 步骤2: 重新编译

```bash
./start-docker.sh shell
cd /workspace
make app
```

### 步骤3: 验证输出

```bash
ls -lh src/ffm_launcher/build-v853/FFlaunch
ls -lh src/touchpad_manager/build-v853/touchpad_manager
```

---

## 📊 编译时间对比

| 方案 | 编译时间 | Qt支持 | 推荐 |
|------|---------|--------|------|
| A: 跳过Qt | 5-10分钟 | ❌ | ✅ 推荐 |
| B: 预编译Qt5 | 10-20分钟 | ✅ | ⚠️ 如果有预编译 |
| C: 完整Buildroot | 2-4小时 | ✅ | ⚠️ 最终发布时 |

---

## 🎉 总结

**当前状态**:
- ✅ SDK适配层编译成功
- ✅ 工具链配置正确
- ✅ FFmpeg和GPIO应用可以编译
- ⚠️ Qt应用需要Buildroot支持

**推荐行动**:
1. 暂时跳过Qt应用（方案A）
2. 先编译和测试其他组件
3. 等需要GUI时再编译Buildroot

**命令**:
```bash
# 修改Makefile或build_all.sh后
./start-docker.sh shell
cd /workspace
make app
```

---

**现在可以继续编译其他组件了！** 🚀
