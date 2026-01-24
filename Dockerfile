# V853 AI Glasses Development Environment
# 基于Ubuntu 20.04，包含V853编译工具链和依赖
# 强制使用 x86_64 架构 (V853 工具链是 x86_64 版本)
FROM --platform=linux/amd64 ubuntu:20.04

LABEL maintainer="AI Glasses Team"
LABEL description="V853 AI Glasses Development Environment"
LABEL version="1.0.0"

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TZ=Asia/Shanghai

# 安装基础工具
RUN apt-get update && apt-get install -y \
    # 基础工具
    build-essential \
    cmake \
    git \
    wget \
    curl \
    vim \
    nano \
    tree \
    htop \
    # 编译依赖
    gcc \
    g++ \
    make \
    autoconf \
    automake \
    libtool \
    pkg-config \
    # Python相关
    python3 \
    python3-pip \
    # 网络工具
    net-tools \
    iputils-ping \
    # 压缩工具
    zip \
    unzip \
    bzip2 \
    xz-utils \
    # 版本控制
    subversion \
    # 其他工具
    locales \
    tzdata \
    sudo \
    file \
    rsync \
    bc \
    cpio \
    # Qt5依赖
    libqt5core5a \
    libqt5gui5 \
    libqt5widgets5 \
    # 音频库
    libasound2-dev \
    # 图形库
    libv4l-dev \
    && rm -rf /var/lib/apt/lists/*

# 配置locale
RUN locale-gen en_US.UTF-8

# 配置时区
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 创建工作目录
RUN mkdir -p /workspace /opt/v853_sdk

# 设置工作目录
WORKDIR /workspace

# 设置启动命令
CMD ["bash", "-l"]
