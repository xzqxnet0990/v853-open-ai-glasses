# Build & Deployment Scripts

This directory contains the core build and deployment scripts for V853 AI Glasses project.

## Scripts Overview

### build_all.sh
**Main application compilation script**

```bash
# Usage (inside Docker container)
./scripts/build_all.sh           # Build SDK + all applications
./scripts/build_all.sh sdk       # Build SDK adapter only
./scripts/build_all.sh app       # Build applications only
./scripts/build_all.sh clean     # Clean build artifacts
```

**What it builds**:
- SDK adapter layer (`libai_glass_sdk_v853.{a,so}`)
- LVGL display application
- FFmpeg launcher
- GPIO touchpad manager

**Time**: 5-10 minutes

---

### deploy.sh
**Deployment script for transferring binaries to V853 device**

```bash
# SSH deployment
./scripts/deploy.sh 192.168.1.100

# ADB deployment
./scripts/deploy.sh adb
```

**What it deploys**:
- Copies binaries to `/usr/bin/`
- Copies libraries to `/usr/lib/`
- Sets execute permissions
- Verifies deployment

---

### firmware.sh
**Firmware compilation and packaging tool (advanced)**

```bash
# Interactive menu
./scripts/firmware.sh

# Command-line mode
./scripts/firmware.sh status     # Check compilation status
./scripts/firmware.sh kernel     # Compile kernel only
./scripts/firmware.sh pack       # Pack firmware image
./scripts/firmware.sh all        # Full kernel + pack
```

**Use cases**:
- Kernel modifications
- Custom firmware image creation
- Device tree changes

**Warning**: Complex and time-consuming (30-60 minutes). For application development, use official firmware + deploy applications instead.

---

### copy_from_docker.sh
**从 Docker 容器复制编译产物到 output/ 目录**

```bash
# 复制所有文件
./scripts/copy_from_docker.sh

# 只复制应用程序
./scripts/copy_from_docker.sh --app

# 只复制 SDK 库
./scripts/copy_from_docker.sh --sdk
```

**用途**:
- 在容器内编译后，将二进制文件复制到主机
- 自动创建 output/ 目录
- 检查容器是否运行

---

### deploy_adb_udisk.sh
**通过 ADB 部署到 UDISK 分区（推荐）**

```bash
# 部署所有文件
./scripts/deploy_adb_udisk.sh

# 只部署应用程序（跳过库文件）
./scripts/deploy_adb_udisk.sh --app-only
```

**优势**:
- 部署到 UDISK 分区（持久化存储，6.9GB 空间）
- 解决 overlayfs 文件系统不一致问题（串口和 ADB 看到不同内容）
- 自动设置正确的权限
- 提供详细的运行指令

**使用场景**:
- 当设备 SSH 不可用时
- overlayfs 系统导致 SSH 部署失败
- USB 连接比网络更方便

---

## Typical Workflow

### Development Loop (SSH 部署)

```bash
# 1. Enter Docker container (on host)
./start-docker.sh shell

# 2. Make code changes (edit src/)

# 3. Build (inside container)
./scripts/build_all.sh

# 4. Exit container
exit

# 5. Deploy to device (on host)
./start-docker.sh deploy-ssh 192.168.1.100

# 6. Test on device
ssh root@192.168.1.100
/usr/bin/AIGlassesDisplayLVGL
```

### Development Loop (ADB 部署 - 推荐) ⭐

```bash
# 1. Enter Docker container (on host)
./start-docker.sh shell

# 2. Build (inside container)
./scripts/build_all.sh
exit

# 3. Copy from container to host
./scripts/copy_from_docker.sh

# 4. Deploy via ADB
./scripts/deploy_adb_udisk.sh

# 5. Test on device (via serial or ADB shell)
# Serial:
export LD_LIBRARY_PATH=/mnt/UDISK/aiglasses/lib:$LD_LIBRARY_PATH
/mnt/UDISK/aiglasses/bin/AIGlassesDisplayLVGL

# Or via ADB:
adb shell "export LD_LIBRARY_PATH=/mnt/UDISK/aiglasses/lib:\$LD_LIBRARY_PATH; /mnt/UDISK/aiglasses/bin/AIGlassesDisplayLVGL"
```

### Quick Update (只改了一个应用)

```bash
# 1. Rebuild just one component (in container)
./start-docker.sh shell
cd /workspace/src/display_lvgl/build-v853
make
exit

# 2. Copy and deploy
./scripts/copy_from_docker.sh --app
./scripts/deploy_adb_udisk.sh --app-only

# 3. Test
# (在串口或 ADB shell 运行)
```

---

## Script Dependencies

All scripts assume:
- Running inside Docker container (except when called via `start-docker.sh`)
- `V853_SDK_PATH` environment variable set to `/opt/v853_sdk`
- Toolchain in PATH
- CMake 3.10+

---

## Makefile Integration

These scripts are also accessible via Makefile targets:

```bash
make all              # Calls scripts/build_all.sh
make sdk              # Calls scripts/build_all.sh sdk
make app              # Calls scripts/build_all.sh app
make clean            # Calls scripts/build_all.sh clean
make deploy-ssh IP=x  # Calls scripts/deploy.sh
make deploy-adb       # Calls scripts/deploy.sh adb
```

---

## Troubleshooting

### "Command not found"
Make sure you're in Docker container: `./start-docker.sh shell`

### "Permission denied"
Ensure scripts are executable: `chmod +x scripts/*.sh`

### Build fails
Check Docker container is running and SDK is mounted correctly:
```bash
./start-docker.sh status
echo $V853_SDK_PATH
```

---

For detailed usage, run each script with `--help` or see `CLAUDE.md` for comprehensive documentation.
