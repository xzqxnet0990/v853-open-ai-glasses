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

## Typical Workflow

### Development Loop

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
