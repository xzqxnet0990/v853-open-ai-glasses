# V853摄像头实现指南

**日期**: 2026-01-23
**目的**: 解决 `src/sdk_adapter/src/ai_camera_v853.c` 编译错误，提供正确的V853摄像头实现方案

---

## 问题诊断

### 当前编译错误根源

```
src/sdk_adapter/src/ai_camera_v853.c:10:33: error: conflicting types for 'mode_t'
src/sdk_adapter/src/ai_camera_v853.c:11:33: error: conflicting types for 'off_t'
fatal error: asm/cache.h: No such file or directory
```

**根本原因**:
- 当前代码尝试包含**内核头文件**并直接操作硬件
- 用户空间程序不应该包含内核内部头文件（如 `asm/cache.h`）
- V853平台提供了**用户空间API**，不需要直接操作硬件

---

## V853摄像头架构

### 官方推荐的实现方式

基于V853 SDK官方文档和camerademo示例代码：

```
应用层 (ai_camera_v853.c)
    ↓
用户空间V4L2 API (/dev/video0)
    ↓
VIN驱动框架 (vin_v4l2.ko)
    ↓
Sensor驱动 (gc2053_mipi.ko)
    ↓
硬件 (MIPI CSI + ISP)
```

### 关键组件

1. **设备节点**: `/dev/video0`, `/dev/video1` 等
2. **V4L2 API**: 标准Linux视频接口（ioctl）
3. **AWIspApi**: 全志ISP控制接口（可选，用于高级功能）
4. **内存管理**: mmap或ION分配器

---

## 参考代码：camerademo

### 位置

```
SDK/tina-v853-open/openwrt/package/allwinner/vision/camerademo/src/
├── camerademo.c  # 主程序（V4L2操作）
├── camerademo.h  # 头文件和结构体
└── convert.c     # YUV/RGB转换
```

### 核心实现流程

#### 1. 打开摄像头设备

```c
// camerademo.c 示例
int videofd = open("/dev/video0", O_RDWR | O_NONBLOCK, 0);
if (videofd < 0) {
    perror("open /dev/video0");
    return -1;
}
```

#### 2. 查询设备能力

```c
struct v4l2_capability cap;
if (ioctl(videofd, VIDIOC_QUERYCAP, &cap) < 0) {
    perror("VIDIOC_QUERYCAP");
    return -1;
}

// 检查是否支持视频采集
if (!(cap.capabilities & V4L2_CAP_VIDEO_CAPTURE)) {
    fprintf(stderr, "Not a video capture device\n");
    return -1;
}
```

#### 3. 设置图像格式

```c
struct v4l2_format fmt;
memset(&fmt, 0, sizeof(fmt));
fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
fmt.fmt.pix.width = 1920;
fmt.fmt.pix.height = 1080;
fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_NV21;  // YUV420 NV21
fmt.fmt.pix.field = V4L2_FIELD_NONE;

if (ioctl(videofd, VIDIOC_S_FMT, &fmt) < 0) {
    perror("VIDIOC_S_FMT");
    return -1;
}
```

#### 4. 请求缓冲区（mmap方式）

```c
struct v4l2_requestbuffers req;
memset(&req, 0, sizeof(req));
req.count = 4;  // 请求4个缓冲区
req.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
req.memory = V4L2_MEMORY_MMAP;

if (ioctl(videofd, VIDIOC_REQBUFS, &req) < 0) {
    perror("VIDIOC_REQBUFS");
    return -1;
}

// 映射缓冲区到用户空间
struct buffer {
    void *start;
    size_t length;
};
struct buffer *buffers = calloc(req.count, sizeof(*buffers));

for (int i = 0; i < req.count; i++) {
    struct v4l2_buffer buf;
    memset(&buf, 0, sizeof(buf));
    buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    buf.memory = V4L2_MEMORY_MMAP;
    buf.index = i;

    if (ioctl(videofd, VIDIOC_QUERYBUF, &buf) < 0) {
        perror("VIDIOC_QUERYBUF");
        return -1;
    }

    buffers[i].length = buf.length;
    buffers[i].start = mmap(NULL, buf.length,
                           PROT_READ | PROT_WRITE,
                           MAP_SHARED,
                           videofd, buf.m.offset);

    if (buffers[i].start == MAP_FAILED) {
        perror("mmap");
        return -1;
    }
}
```

#### 5. 入队缓冲区

```c
for (int i = 0; i < req.count; i++) {
    struct v4l2_buffer buf;
    memset(&buf, 0, sizeof(buf));
    buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    buf.memory = V4L2_MEMORY_MMAP;
    buf.index = i;

    if (ioctl(videofd, VIDIOC_QBUF, &buf) < 0) {
        perror("VIDIOC_QBUF");
        return -1;
    }
}
```

#### 6. 开始采集

```c
enum v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
if (ioctl(videofd, VIDIOC_STREAMON, &type) < 0) {
    perror("VIDIOC_STREAMON");
    return -1;
}
```

#### 7. 读取帧数据

```c
// 使用select等待数据就绪
fd_set fds;
struct timeval tv;
FD_ZERO(&fds);
FD_SET(videofd, &fds);
tv.tv_sec = 2;
tv.tv_usec = 0;

int ret = select(videofd + 1, &fds, NULL, NULL, &tv);
if (ret > 0) {
    // 出队一个缓冲区（获取图像）
    struct v4l2_buffer buf;
    memset(&buf, 0, sizeof(buf));
    buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    buf.memory = V4L2_MEMORY_MMAP;

    if (ioctl(videofd, VIDIOC_DQBUF, &buf) < 0) {
        perror("VIDIOC_DQBUF");
        return -1;
    }

    // 处理图像数据
    void *frame_data = buffers[buf.index].start;
    size_t frame_size = buf.bytesused;

    // TODO: 处理图像数据（保存、编码、显示等）
    process_frame(frame_data, frame_size);

    // 重新入队缓冲区
    if (ioctl(videofd, VIDIOC_QBUF, &buf) < 0) {
        perror("VIDIOC_QBUF");
        return -1;
    }
}
```

#### 8. 停止采集并清理

```c
// 停止采集
enum v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
ioctl(videofd, VIDIOC_STREAMOFF, &type);

// 释放mmap内存
for (int i = 0; i < req.count; i++) {
    munmap(buffers[i].start, buffers[i].length);
}
free(buffers);

// 关闭设备
close(videofd);
```

---

## 建议的实现方案

### 方案1：最小可编译版本（推荐用于快速验证）

创建一个基础的、可以编译通过的实现：

**特点**：
- 仅实现基本的V4L2初始化和清理
- 图像采集返回模拟数据或空数据
- 目标：让编译系统通过，验证其他组件

**实现步骤**：
1. 移除所有内核头文件引用
2. 使用标准V4L2用户空间API
3. 实现基本的init/deinit/capture接口
4. 图像数据可以先返回dummy数据

### 方案2：参考camerademo的完整实现

直接参考camerademo实现完整的摄像头功能：

**特点**：
- 完整的V4L2操作流程
- 支持多种分辨率和格式
- 支持MMAP和USERPTR两种内存模式
- 支持ISP控制（如果需要）

**实现步骤**：
1. 复制camerademo的核心V4L2代码
2. 适配到ai_camera_v853.c的接口
3. 实现RV1109兼容层的API映射

---

## 修改ai_camera_v853.c的具体步骤

### 步骤1：修改头文件

**错误的包含方式**（当前）：
```c
#include <linux/videodev2.h>  // 可能导致冲突
#include <asm/cache.h>         // ❌ 内核头文件
#include "v853_hardware_direct.h"  // ❌ 不存在
```

**正确的包含方式**：
```c
// 标准库
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/select.h>
#include <sys/time.h>

// V4L2 API（用户空间）
#include <linux/videodev2.h>

// 项目头文件
#include "ai_camera.h"
#include "ai_log.h"
```

### 步骤2：定义内部结构体

```c
// 摄像头上下文结构体
typedef struct {
    int video_fd;                    // /dev/videoX 文件描述符
    int is_streaming;                // 是否正在采集
    int buffer_count;                // 缓冲区数量
    struct {
        void *start;
        size_t length;
    } *buffers;                      // mmap缓冲区数组

    // 配置参数
    int width;
    int height;
    uint32_t pixel_format;           // V4L2_PIX_FMT_NV21 等
    int fps;

    // 回调
    ai_camera_callback_t callback;
    void *user_data;
} camera_context_t;
```

### 步骤3：实现初始化函数

```c
int ai_camera_init(void) {
    // 检查设备节点是否存在
    if (access("/dev/video0", F_OK) != 0) {
        AI_LOG_ERROR("Camera device /dev/video0 not found");
        return -1;
    }

    AI_LOG_INFO("V853 camera initialized");
    return 0;
}
```

### 步骤4：实现打开函数

```c
ai_camera_handle_t ai_camera_open(int camera_id) {
    char dev_path[32];
    snprintf(dev_path, sizeof(dev_path), "/dev/video%d", camera_id);

    int fd = open(dev_path, O_RDWR | O_NONBLOCK, 0);
    if (fd < 0) {
        AI_LOG_ERROR("Failed to open %s: %s", dev_path, strerror(errno));
        return NULL;
    }

    // 分配上下文
    camera_context_t *ctx = calloc(1, sizeof(camera_context_t));
    if (!ctx) {
        close(fd);
        return NULL;
    }

    ctx->video_fd = fd;
    ctx->is_streaming = 0;

    // 设置默认参数
    ctx->width = 1920;
    ctx->height = 1080;
    ctx->pixel_format = V4L2_PIX_FMT_NV21;
    ctx->fps = 30;

    AI_LOG_INFO("Camera %d opened", camera_id);
    return (ai_camera_handle_t)ctx;
}
```

### 步骤5：实现配置函数

```c
int ai_camera_set_format(ai_camera_handle_t handle,
                        int width, int height,
                        ai_camera_format_t format) {
    camera_context_t *ctx = (camera_context_t *)handle;
    if (!ctx) return -1;

    // 映射格式
    uint32_t v4l2_fmt;
    switch (format) {
        case AI_CAMERA_FORMAT_NV21:
            v4l2_fmt = V4L2_PIX_FMT_NV21;
            break;
        case AI_CAMERA_FORMAT_NV12:
            v4l2_fmt = V4L2_PIX_FMT_NV12;
            break;
        case AI_CAMERA_FORMAT_YUYV:
            v4l2_fmt = V4L2_PIX_FMT_YUYV;
            break;
        default:
            return -1;
    }

    // 设置V4L2格式
    struct v4l2_format fmt;
    memset(&fmt, 0, sizeof(fmt));
    fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    fmt.fmt.pix.width = width;
    fmt.fmt.pix.height = height;
    fmt.fmt.pix.pixelformat = v4l2_fmt;
    fmt.fmt.pix.field = V4L2_FIELD_NONE;

    if (ioctl(ctx->video_fd, VIDIOC_S_FMT, &fmt) < 0) {
        AI_LOG_ERROR("VIDIOC_S_FMT failed: %s", strerror(errno));
        return -1;
    }

    // 保存实际设置的参数（驱动可能调整）
    ctx->width = fmt.fmt.pix.width;
    ctx->height = fmt.fmt.pix.height;
    ctx->pixel_format = fmt.fmt.pix.pixelformat;

    AI_LOG_INFO("Camera format set: %dx%d, fmt=0x%x",
                ctx->width, ctx->height, ctx->pixel_format);
    return 0;
}
```

### 步骤6：实现采集函数（简化版）

```c
int ai_camera_start_capture(ai_camera_handle_t handle,
                           ai_camera_callback_t callback,
                           void *user_data) {
    camera_context_t *ctx = (camera_context_t *)handle;
    if (!ctx || ctx->is_streaming) return -1;

    ctx->callback = callback;
    ctx->user_data = user_data;

    // 1. 请求缓冲区
    struct v4l2_requestbuffers req;
    memset(&req, 0, sizeof(req));
    req.count = 4;
    req.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    req.memory = V4L2_MEMORY_MMAP;

    if (ioctl(ctx->video_fd, VIDIOC_REQBUFS, &req) < 0) {
        AI_LOG_ERROR("VIDIOC_REQBUFS failed");
        return -1;
    }

    // 2. 映射缓冲区（省略，参考上面完整代码）
    // 3. 入队缓冲区
    // 4. 开始流
    enum v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    if (ioctl(ctx->video_fd, VIDIOC_STREAMON, &type) < 0) {
        AI_LOG_ERROR("VIDIOC_STREAMON failed");
        return -1;
    }

    ctx->is_streaming = 1;
    AI_LOG_INFO("Camera capture started");
    return 0;
}
```

---

## 编译配置调整

### CMakeLists.txt 调整

确保链接所需的库：

```cmake
# V853摄像头需要的库
find_package(Threads REQUIRED)

target_link_libraries(ai_glass_sdk_v853
    PUBLIC
        ${CMAKE_THREAD_LIBS_INIT}
        rt  # 实时库（用于共享内存）
)
```

### 移除不必要的依赖

```cmake
# 不需要链接内核模块
# 不需要特殊的硬件库
# V4L2是标准内核接口，无需额外链接
```

---

## 测试验证

### 1. 编译测试

```bash
cd src/sdk_adapter
rm -rf build
mkdir build && cd build
cmake .. -DCMAKE_TOOLCHAIN_FILE=../toolchain-v853.cmake
make
```

**预期结果**：
- ✅ 无类型冲突错误
- ✅ 无缺失头文件错误
- ✅ 生成 libai_glass_sdk_v853.a 和 .so

### 2. 设备上测试

```bash
# 上传到V853设备
adb push libai_glass_sdk_v853.so /usr/lib/
adb push camera_test /tmp/

# 在设备上运行
adb shell
/tmp/camera_test
```

**预期输出**：
```
[INFO] V853 camera initialized
[INFO] Camera 0 opened
[INFO] Camera format set: 1920x1080, fmt=0x15
[INFO] Camera capture started
```

---

## 下一步计划

### 立即执行（修复编译）

1. ✅ 创建 `ai_camera_v853.c` 的最小可编译版本
2. ✅ 移除内核头文件依赖
3. ✅ 使用标准V4L2 API
4. ✅ 验证编译通过

### 后续完善（功能实现）

1. 实现完整的buffer管理（mmap）
2. 实现采集线程和回调机制
3. 添加ISP控制接口（如需要）
4. 性能优化（零拷贝、多缓冲）

---

## 参考资料

### 官方文档

- 全志Tina SDK开发手册：https://tina.100ask.net/
- Camera开发指南：SDK/docs/Camera_开发指南.pdf
- V853数据手册：SDK/docs/V853_Datasheet.pdf

### 示例代码位置

```
SDK/tina-v853-open/openwrt/package/allwinner/vision/
├── camerademo/        # V4L2摄像头示例（最重要）
├── libAWIspApi/       # ISP控制库
└── sample_virvi/      # 更多摄像头示例
```

### V4L2 API文档

- Linux V4L2 Documentation: https://www.kernel.org/doc/html/latest/userspace-api/media/v4l/v4l2.html
- V4L2 Examples: https://linuxtv.org/downloads/v4l-dvb-apis/

---

## 总结

**关键要点**：

1. ❌ **不要**直接操作V853硬件寄存器
2. ❌ **不要**包含内核内部头文件
3. ✅ **使用**标准V4L2用户空间API
4. ✅ **参考** SDK提供的camerademo示例
5. ✅ **通过** `/dev/video0` 设备节点访问摄像头

**实现路径**：

```
应用程序 (display_qt, etc.)
    ↓
AI Glass SDK (ai_camera.h)
    ↓
SDK适配层 (ai_camera_v853.c)
    ↓ [使用V4L2 API]
/dev/video0 设备节点
    ↓ [内核空间]
VIN驱动 (vin_v4l2.ko)
    ↓
GC2053驱动 (gc2053_mipi.ko)
    ↓
硬件 (MIPI CSI)
```

这种分层设计确保了：
- 用户空间代码可移植性
- 符合Linux标准接口
- 便于调试和维护
