# V853 AI Glasses 脚本说明

## 📜 核心脚本（4个）

### 1. `start-docker.sh` - Docker 容器管理 ⭐

**用途**: 管理 V853 开发容器

**常用命令**:
```bash
./start-docker.sh start        # 启动容器
./start-docker.sh shell        # 进入容器
./start-docker.sh stop         # 停止容器
./start-docker.sh build-all    # 编译应用层
./start-docker.sh deploy-ssh <IP>   # 部署到设备
./start-docker.sh copy-image   # 复制固件镜像
./start-docker.sh help         # 查看所有命令
```

---

### 2. `build_all.sh` - 应用层编译 ⭐⭐⭐

**用途**: 编译 SDK、LVGL 应用、FFmpeg 启动器、GPIO 管理器

**使用**:
```bash
# 在容器内运行
./build_all.sh

# 或使用 make
make all    # 编译所有
make sdk    # 只编译 SDK
make app    # 只编译应用
make clean  # 清理
```

**编译产物**:
- `src/sdk_adapter/build/libai_glass_sdk_v853.so`
- `src/display_lvgl/build-v853/AIGlassesDisplayLVGL`
- `src/ffm_launcher/build-v853/FFlaunch`
- `src/touchpad_manager/build-v853/touchpad_manager`

**推荐**: 🌟 日常开发使用这个，5-10 分钟完成

---

### 3. `deploy.sh` - 部署工具 ⭐⭐

**用途**: 将编译产物部署到 V853 设备

**使用**:
```bash
# SSH 部署
./deploy.sh 192.168.1.100

# ADB 部署
./deploy.sh adb
```

**部署位置**:
- `/usr/bin/` - 应用程序
- `/usr/lib/` - 库文件
- `/usr/bin/examples/` - 测试程序

---

### 4. `firmware.sh` - 固件编译工具 ⭐

**用途**: 编译内核、打包固件镜像（高级功能）

**使用**:
```bash
# 在容器内运行

# 交互模式（推荐）
./firmware.sh

# 命令行模式
./firmware.sh status   # 检查状态
./firmware.sh kernel   # 编译内核
./firmware.sh pack     # 打包镜像
./firmware.sh all      # 完整流程
```

**注意**: 固件编译复杂且容易失败，**不推荐日常使用**

---

## 🎯 推荐工作流

### 日常开发（推荐）⭐⭐⭐

```bash
# 1. 启动容器
./start-docker.sh start
./start-docker.sh shell

# 2. 编译应用（容器内）
./build_all.sh

# 3. 部署（退出容器后）
exit
./start-docker.sh deploy-ssh 192.168.1.100

# 4. 测试
ssh root@192.168.1.100
/usr/bin/AIGlassesDisplayLVGL
```

**时间**: 5-10 分钟
**成功率**: 95%+

---

### 固件定制（高级）

```bash
# 1. 进入容器
./start-docker.sh shell

# 2. 编译固件
./firmware.sh

# 选择：
# - 2: 编译内核
# - 3: 打包镜像
# - 4: 完整流程

# 3. 复制镜像
exit
./start-docker.sh copy-image
```

**时间**: 30-60 分钟
**成功率**: 30-50%
**建议**: 使用官方预编译固件

---

## 📋 快速参考

| 任务 | 命令 | 位置 |
|------|------|------|
| 启动开发环境 | `./start-docker.sh start` | macOS |
| 进入容器 | `./start-docker.sh shell` | macOS |
| 编译应用 | `./build_all.sh` | 容器内 |
| 部署应用 | `./start-docker.sh deploy-ssh <IP>` | macOS |
| 检查固件状态 | `./firmware.sh status` | 容器内 |
| 编译内核 | `./firmware.sh kernel` | 容器内 |

---

## 🆘 常见任务

### 首次使用

```bash
# 1. 启动容器（首次会构建镜像）
./start-docker.sh start

# 2. 进入容器
./start-docker.sh shell

# 3. 编译应用
./build_all.sh

# 4. 退出
exit
```

### 修改代码后重新编译

```bash
./start-docker.sh shell
./build_all.sh
exit
./start-docker.sh deploy-ssh 192.168.1.100
```

### 清理编译产物

```bash
# 应用层
./start-docker.sh shell
make clean

# 固件（在容器内）
cd /opt/v853_sdk
make clean
```

### 查看帮助

```bash
./start-docker.sh help     # Docker 容器帮助
./firmware.sh              # 固件工具交互菜单
make help                  # Makefile 帮助
```

---

## 📚 相关文档

- **DEPLOYMENT_READY.md** - 部署和测试指南
- **BUILD_STRATEGY.md** - 编译策略说明
- **FIRMWARE_BUILD_GUIDE.md** - 固件编译详细指南
- **docs/QUICK_START.md** - 快速入门

---

## 💡 提示

1. **日常开发**: 只使用 `build_all.sh` + `deploy.sh`
2. **固件编译**: 非必需，使用官方固件即可
3. **遇到问题**: 查看对应的 `.md` 文档
4. **脚本位置**: 所有脚本都在项目根目录

---

**记住**: 简单最好！大部分情况下只需要 `build_all.sh` 编译应用层。🎯
