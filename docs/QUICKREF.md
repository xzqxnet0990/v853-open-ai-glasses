# V853 AI Glasses - 快速参考卡片

**一页纸搞定所有操作** 📄

## 🚀 一键启动

```bash
./start-docker.sh start    # 启动Docker环境
./start-docker.sh shell    # 进入容器
make all                   # 编译所有组件
```

## 📋 常用命令

### 容器管理
```bash
./start-docker.sh start        # 启动
./start-docker.sh stop         # 停止
./start-docker.sh restart      # 重启
./start-docker.sh shell        # 进入Shell
./start-docker.sh status       # 状态
./start-docker.sh clean        # 删除容器
```

### 编译
```bash
./start-docker.sh build-sdk    # 编译SDK
./start-docker.sh build-app    # 编译应用
./start-docker.sh build-all    # 编译所有
make all                       # (容器内) 编译所有
make sdk                       # (容器内) 只编译SDK
```

### 测试
```bash
./start-docker.sh test-camera  # 测试摄像头
./start-docker.sh test-audio   # 测试音频
./start-docker.sh test-gpio    # 测试GPIO
```

### 部署
```bash
./start-docker.sh deploy-ssh 192.168.1.100  # SSH部署
./start-docker.sh deploy-adb                # ADB部署
./deploy.sh 192.168.1.100                   # (本地) SSH部署
```

### 信息
```bash
./start-docker.sh info         # 环境信息
./start-docker.sh toolchain    # 工具链信息
./start-docker.sh help         # 帮助
```

## 🗂️ 重要目录

| 目录 | 说明 |
|------|------|
| `src/sdk_adapter/` | SDK适配层源码 |
| `src/sdk_adapter/build/` | SDK编译输出 |
| `src/display_qt/` | Qt显示应用 |
| `SDK/tina-v853-open/` | V853 官方SDK |
| `output/` | 固件输出 |

## 📦 编译输出

| 文件 | 位置 |
|------|------|
| SDK库 | `src/sdk_adapter/build/libai_glass_sdk_v853.so` |
| Qt应用 | `src/display_qt/build-v853/AIGlassesDisplay_V853` |
| FFmpeg | `src/ffm_launcher/build-v853/FFlaunch` |
| GPIO管理 | `src/touchpad_manager/build-v853/touchpad_manager` |
| 测试程序 | `src/sdk_adapter/build/examples/` |

## 🔧 故障排查

### 容器启动失败
```bash
docker info                    # 检查Docker
ls SDK/tina-v853-open/        # 检查SDK
./start-docker.sh logs        # 查看日志
```

### 编译失败
```bash
./start-docker.sh shell
echo $PATH                    # 检查工具链PATH
arm-openwrt-linux-gcc --version  # 检查编译器
```

### 部署失败
```bash
ping 192.168.1.100            # 检查网络
ssh root@192.168.1.100        # 检查SSH
adb devices                   # 检查ADB
```

## 📚 文档速查

| 文档 | 用途 |
|------|------|
| `README.md` | 项目概述 |
| `DOCKER_GUIDE.md` | Docker详细指南 |
| `QUICK_START.md` | 快速入门 |
| `USAGE.md` | 完整使用指南 |
| `PROJECT_STATUS.md` | 开发进度 |
| `QUICKREF.md` | 本文档 |

## 💡 提示

- 首次启动需要构建镜像（~5分钟）
- 编译所有组件需要~10分钟
- 固件编译需要~30分钟
- Docker环境会自动配置工具链PATH
- 编译缓存会持久化，提升增量编译速度

## 🔗 在线帮助

```bash
./start-docker.sh help        # 显示完整帮助
./start-docker.sh info        # 查看当前环境信息
```

---

**记住这三个命令，你就可以开始开发了：** 🎯

```bash
./start-docker.sh start       # 启动
./start-docker.sh build-all   # 编译
./start-docker.sh deploy-ssh <IP>  # 部署
```
