# Docker镜像重建指南

**日期**: 2026-01-24
**原因**: 添加Tina SDK/Buildroot编译所需的依赖
**更新内容**: 添加ncurses、gawk等OpenWrt编译依赖

---

## 📦 添加的依赖包

### Tina SDK / Buildroot / OpenWrt 编译依赖

```dockerfile
# Tina SDK / Buildroot / OpenWrt 编译依赖
libncurses5-dev          # ncurses开发库
libncursesw5-dev         # ncurses宽字符支持
gawk                     # GNU awk
gettext                  # 国际化工具
libssl-dev               # OpenSSL开发库
libelf-dev               # ELF库开发文件
xsltproc                 # XSLT处理器
zlib1g-dev               # zlib压缩库
ccache                   # 编译缓存
ecj                      # Eclipse Java编译器
fastjar                  # Java打包工具
java-propose-classpath   # Java classpath工具
swig                     # 接口生成器
time                     # 时间统计工具
```

### Python增强

```dockerfile
python3-dev              # Python开发头文件
python3-distutils        # Python distutils
python3-setuptools       # Python setuptools
```

---

## 🔨 重建镜像

### 方法1: 使用docker-compose（推荐）

```bash
# 停止现有容器
docker-compose down

# 重新构建镜像
docker-compose build --no-cache

# 或者强制重建
docker-compose up -d --build --force-recreate

# 启动新容器
docker-compose up -d
```

### 方法2: 使用start-docker.sh

```bash
# 停止容器
./start-docker.sh stop

# 清理旧容器
./start-docker.sh clean

# 重新构建（如果start-docker.sh支持build命令）
docker build -t aiglasses/v853-dev:latest .

# 启动新容器
./start-docker.sh start
```

### 方法3: 手动Docker命令

```bash
# 停止并删除旧容器
docker stop v853-aiglasses-dev
docker rm v853-aiglasses-dev

# 删除旧镜像（可选）
docker rmi aiglasses/v853-dev:latest

# 重新构建镜像
docker build --no-cache -t aiglasses/v853-dev:latest .

# 启动新容器
docker run -d --name v853-aiglasses-dev \
    -v $(pwd):/workspace \
    -v $(pwd)/SDK/tina-v853-open:/opt/v853_sdk \
    aiglasses/v853-dev:latest
```

---

## ⏱️ 预期时间

- **镜像构建时间**: 约5-10分钟（取决于网络速度）
- **首次构建**: 可能需要下载较多依赖包
- **后续构建**: 如果使用缓存会快很多

---

## ✅ 验证新镜像

重建完成后，进入容器验证依赖已安装：

```bash
# 进入容器
./start-docker.sh shell

# 验证ncurses
dpkg -l | grep libncurses
# 应该看到: libncurses5-dev, libncursesw5-dev

# 验证gawk
which gawk
# 应该输出: /usr/bin/gawk

# 验证所有关键依赖
dpkg -l | grep -E 'libncurses|gawk|gettext|libssl-dev|libelf-dev'
```

---

## 🚀 重建后的下一步

### 1. 验证V853应用编译仍然正常

```bash
cd /workspace
make clean
make all
```

应该能成功编译SDK和应用层。

### 2. 尝试编译Buildroot/Tina SDK

```bash
cd /opt/v853_sdk
source build/envsetup.sh
lunch  # 选择配置

# 检查依赖
make prereq

# 如果通过，开始编译
make
```

---

## 📊 镜像大小对比

### 更新前
- 基础镜像: Ubuntu 20.04 (~72MB)
- 添加依赖后: 约500-800MB

### 更新后
- 新增依赖: 约50-100MB
- 总大小: 约550-900MB

**说明**: Buildroot/OpenWrt编译需要这些依赖，大小增加是正常的。

---

## ⚠️ 注意事项

### 1. 保存当前工作

在重建镜像前，确保：
- ✅ 编译产物已经生成并复制到主机
- ✅ 代码已经提交到git
- ✅ 没有未保存的容器内修改

### 2. Docker缓存

使用`--no-cache`会完全重新构建，时间较长但保证干净。

不使用`--no-cache`会利用缓存，但可能保留旧的layer。

### 3. 磁盘空间

确保有足够的磁盘空间：
- 镜像构建: 约2-3GB临时空间
- 最终镜像: 约1GB
- Docker缓存: 约1-2GB

可以先清理旧镜像：
```bash
docker system prune -a
```

---

## 🐛 常见问题

### 问题1: 构建失败 - 网络超时

**解决**: 使用国内镜像源

在Dockerfile中添加（在apt-get update之前）：
```dockerfile
RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list
```

### 问题2: 磁盘空间不足

**解决**: 清理Docker

```bash
# 清理所有未使用的镜像
docker system prune -a

# 清理构建缓存
docker builder prune -a
```

### 问题3: 依赖包找不到

**解决**: 确保apt-get update执行成功

检查Dockerfile中的RUN命令是否有错误。

---

## 📝 版本记录

| 版本 | 日期 | 更新内容 |
|------|------|---------|
| 1.0.0 | 2026-01-23 | 初始版本 - 基础开发环境 |
| 1.1.0 | 2026-01-24 | 添加Tina SDK/Buildroot编译依赖 |

---

## 🔗 相关文档

- `Dockerfile` - Docker镜像定义
- `docker-compose.yml` - Docker Compose配置
- `start-docker.sh` - Docker管理脚本
- `SUCCESS_V853_MIGRATION.md` - V853迁移成功总结

---

**准备重建镜像！** 🚀

推荐命令:
```bash
docker-compose down
docker-compose build --no-cache
docker-compose up -d
./start-docker.sh shell
```
