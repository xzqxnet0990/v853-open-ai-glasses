# ✅ 应用层编译完成

## 📦 编译产物

### SDK 适配层
- `src/sdk_adapter/build/libai_glass_sdk_v853.a` - 静态库
- `src/sdk_adapter/build/libai_glass_sdk_v853.so` - 动态库

### 应用程序
- `src/display_lvgl/build-v853/AIGlassesDisplayLVGL` - LVGL 显示应用
- `src/ffm_launcher/build-v853/FFlaunch` - FFmpeg 启动器
- `src/touchpad_manager/build-v853/touchpad_manager` - GPIO 触摸板管理器

### 测试程序
- `src/sdk_adapter/build/examples/camera_test` - 摄像头测试
- `src/sdk_adapter/build/examples/audio_test` - 音频测试

---

## 🚀 部署到设备

### 方法 1: SSH 部署（推荐）

```bash
# 在 macOS 主机运行
./start-docker.sh deploy-ssh <设备IP>

# 例如
./start-docker.sh deploy-ssh 192.168.1.100
```

### 方法 2: 手动部署

```bash
# 从容器复制文件到主机
docker cp v853_ai_glasses_dev:/workspace/src/display_lvgl/build-v853/AIGlassesDisplayLVGL ./output/
docker cp v853_ai_glasses_dev:/workspace/src/sdk_adapter/build/libai_glass_sdk_v853.so ./output/

# 使用 scp 复制到设备
scp output/* root@192.168.1.100:/usr/bin/
```

### 方法 3: ADB 部署

```bash
./start-docker.sh deploy-adb
```

---

## 📁 设备上的部署位置

### 建议的目录结构

```
/usr/bin/
├── AIGlassesDisplayLVGL     # 主应用
├── FFlaunch                 # FFmpeg 启动器
└── touchpad_manager         # GPIO 管理器

/usr/lib/
└── libai_glass_sdk_v853.so  # SDK 库

/usr/bin/examples/           # 测试程序
├── camera_test
└── audio_test
```

---

## 🧪 在设备上测试

### 1. 测试 SDK 库

```bash
# SSH 登录设备
ssh root@192.168.1.100

# 测试摄像头
/usr/bin/examples/camera_test

# 测试音频
/usr/bin/examples/audio_test /tmp/test.pcm
```

### 2. 运行主应用

```bash
# 前台运行
/usr/bin/AIGlassesDisplayLVGL

# 后台运行
nohup /usr/bin/AIGlassesDisplayLVGL &

# 查看日志
tail -f /var/log/aiglasses.log
```

---

## ⚙️ 设备环境配置

### 设置库路径

```bash
# 临时设置
export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH

# 永久设置
echo 'export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH' >> /etc/profile
source /etc/profile
```

### 设置权限

```bash
chmod +x /usr/bin/AIGlassesDisplayLVGL
chmod +x /usr/bin/FFlaunch
chmod +x /usr/bin/touchpad_manager
```

---

## 🔄 开发迭代流程

```
修改代码 → 编译 → 部署 → 测试
   ↓          ↓        ↓        ↓
 vim      build_all  deploy    ssh
```

### 快速迭代命令

```bash
# 在容器内编译
cd /workspace && ./build_all.sh

# 退出容器
exit

# 部署到设备
./start-docker.sh deploy-ssh 192.168.1.100

# SSH 测试
ssh root@192.168.1.100 '/usr/bin/AIGlassesDisplayLVGL'
```

---

## 📝 部署脚本说明

查看 `deploy.sh` 了解部署细节：

```bash
cat deploy.sh
```

主要功能：
- 自动检测部署方式（SSH 或 ADB）
- 复制所有编译产物
- 设置正确的权限
- 验证部署结果

---

## 🐛 常见问题

### Q: 运行时提示找不到 .so 文件

**A:** 设置 `LD_LIBRARY_PATH`：
```bash
export LD_LIBRARY_PATH=/usr/lib:$LD_LIBRARY_PATH
```

### Q: 提示 Permission denied

**A:** 添加执行权限：
```bash
chmod +x /usr/bin/AIGlassesDisplayLVGL
```

### Q: 摄像头/音频无法打开

**A:** 检查设备节点：
```bash
ls -l /dev/video*
ls -l /dev/snd/*
```

### Q: 显示屏没有输出

**A:** 检查显示驱动：
```bash
cat /sys/class/graphics/fb0/modes
fbset -fb /dev/fb0 -i
```

---

## 🎯 下一步

1. ✅ 应用层编译完成
2. ⏭️ 部署到设备测试
3. ⏭️ 验证基础功能（摄像头、音频、GPIO）
4. ⏭️ 迭代开发

---

**现在可以部署了！** 🎉
