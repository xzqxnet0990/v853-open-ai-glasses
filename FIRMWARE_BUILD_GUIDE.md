# V853 AI Glasses 固件编译指南

## 🚀 快速开始

### 一键修复并编译（推荐）

在 **Ubuntu 容器内** 运行：

```bash
cd /home/xzqxnet/v853-open-ai-glasses
./fix_and_build_firmware.sh
```

这个脚本会自动：
- ✅ 检查磁盘空间和内存
- ✅ 修复内核配置（x86_64 → ARM）
- ✅ 禁用有问题的 netfilter 模块
- ✅ 使用安全的低并发编译
- ✅ 保存详细日志
- ✅ 显示镜像文件位置

---

## 📋 已修复的问题

### 问题 1: 内核配置错误
**症状**：`Linux/x86 4.9.191 Kernel Configuration`

**原因**：`.config` 文件使用了 x86_64 架构而不是 ARM

**修复**：
```bash
cd /opt/v853_sdk/kernel/linux-4.9
rm -f .config
make ARCH=arm CROSS_COMPILE=arm-openwrt-linux- sun8iw21p1smp_v853_defconfig
```

### 问题 2: xt_TCPMSS 模块缺失
**症状**：`No rule to make target 'net/netfilter/xt_TCPMSS.c'`

**原因**：内核配置启用了缺失的 netfilter 模块

**修复**：在 `.config` 中禁用：
- `CONFIG_NETFILTER_XT_TARGET_TCPMSS`
- `CONFIG_IP_NF_TARGET_MASQUERADE`

### 问题 3: 内存/资源不足
**症状**：编译中途失败，没有明确错误

**原因**：并发编译占用太多内存

**修复**：使用 `-j2` 或 `-j4` 低并发编译

---

## 🛠️ 分步操作指南

### 方法 A: 使用一键脚本（推荐）

```bash
# 1. 进入容器
./start-docker.sh shell

# 2. 运行修复+编译脚本
cd /workspace
./fix_and_build_firmware.sh

# 脚本会引导你完成所有步骤
```

### 方法 B: 手动操作

```bash
# 1. 进入容器
./start-docker.sh shell

# 2. 配置环境
cd /opt/v853_sdk
source build/envsetup.sh
lunch v853-100ask-tina

# 3. 修复内核配置
cd kernel/linux-4.9
rm -f .config
rm -rf include/config/*
make ARCH=arm CROSS_COMPILE=arm-openwrt-linux- sun8iw21p1smp_v853_defconfig

# 4. 禁用问题模块
sed -i 's/^CONFIG_NETFILTER_XT_TARGET_TCPMSS=.*/# CONFIG_NETFILTER_XT_TARGET_TCPMSS is not set/' .config

# 5. 返回 SDK 根目录编译
cd /opt/v853_sdk
make clean  # 可选
make -j4    # 使用4线程编译
```

---

## 📦 编译产物位置

### 容器内路径
```
/opt/v853_sdk/out/v853/100ask/image/
```

### 常见镜像文件
- `tina_v853-100ask_uart0.img` - 完整固件（推荐烧录）
- `boot.fex` - Boot 分区
- `rootfs.fex` - 根文件系统
- `kernel.fex` - 内核镜像
- `sunxi_mbr.fex` - 分区表

### 复制到 macOS 主机

```bash
# 退出容器
exit

# 复制镜像
./start-docker.sh copy-image

# 镜像会保存到
# output/tina_v853-100ask_uart0.img
```

---

## 🔍 故障排查

### 编译失败：找不到 vmlinux

**原因**：内核配置未正确生成

**解决**：
```bash
cd /opt/v853_sdk/kernel/linux-4.9
make ARCH=arm CROSS_COMPILE=arm-openwrt-linux- sun8iw21p1smp_v853_defconfig
make ARCH=arm CROSS_COMPILE=arm-openwrt-linux- prepare
```

### 编译失败：磁盘空间不足

**检查**：
```bash
df -h /opt/v853_sdk
```

**解决**：清理旧的编译产物
```bash
cd /opt/v853_sdk
make clean
rm -rf out/*/image/*.img
```

### 编译失败：内存不足

**解决**：降低并发数
```bash
make -j2  # 使用2线程
```

或增加交换空间（在 Ubuntu 宿主机）：
```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

---

## 📝 可用的辅助脚本

| 脚本 | 用途 |
|------|------|
| `fix_and_build_firmware.sh` | 一键修复+编译（推荐） |
| `fix_kernel_config.sh` | 只修复内核配置 |
| `build_firmware_safe.sh` | 安全模式编译 |
| `debug_build.sh` | 诊断编译问题 |
| `fix_kernel_build.sh` | 修复 netfilter 模块 |

---

## ⏱️ 编译时间参考

| 配置 | 编译时间 |
|------|---------|
| 8核 + 16GB RAM + `-j8` | 20-30分钟 |
| 4核 + 8GB RAM + `-j4` | 30-45分钟 |
| 2核 + 4GB RAM + `-j2` | 60-90分钟 |

---

## 🎯 烧录固件

### 方法 1: PhoenixSuit (推荐)

1. 下载 PhoenixSuit 工具
2. 打开 `output/tina_v853-100ask_uart0.img`
3. 设备进入 FEL 模式（按住 FEL 按钮上电）
4. 点击"一键烧录"

### 方法 2: LiveSuit (Linux)

```bash
sudo livesuit output/tina_v853-100ask_uart0.img
```

### 方法 3: dd 烧录到 TF 卡

```bash
sudo dd if=output/tina_v853-100ask_uart0.img of=/dev/sdX bs=4M status=progress
sync
```

---

## 📚 相关文档

- [README.md](README.md) - 项目概述
- [QUICK_START.md](docs/QUICK_START.md) - 快速入门
- [DOCKER_GUIDE.md](docs/DOCKER_GUIDE.md) - Docker 使用指南

---

**祝编译顺利！** 🎉
