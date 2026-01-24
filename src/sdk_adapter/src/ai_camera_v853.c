/**
 * AI Camera Adapter for V853 Platform
 *
 * 这个文件实现了ai_camera.h定义的接口，内部调用V853的V4L2 API
 * 使应用层代码无需修改即可在V853平台运行
 *
 * V853摄像头架构:
 * - 使用标准Linux V4L2接口
 * - 设备节点: /dev/video0
 * - ISP支持: libAWIspApi
 * - 格式支持: NV12, NV21, YUYV, MJPEG
 */

#include "ai_camera.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <linux/videodev2.h>

// V853 camera context
struct ai_core_client_ctx {
    int video_fd;                   // V4L2设备文件描述符
    int width;                      // 图像宽度
    int height;                     // 图像高度
    int format;                     // 像素格式
    int buffer_count;               // Buffer数量
    void *buffers[4];               // mmap的buffer地址
    size_t buffer_lengths[4];       // Buffer大小
    int sequence;                   // 帧序号
};

// V853摄像头初始化
ai_core_client_t* ai_core_init(void) {
    ai_core_client_t *client = calloc(1, sizeof(ai_core_client_t));
    if (!client) {
        fprintf(stderr, "[V853-Camera] Failed to allocate client memory\n");
        return NULL;
    }

    // 1. 打开V4L2设备
    client->video_fd = open("/dev/video0", O_RDWR | O_NONBLOCK);
    if (client->video_fd < 0) {
        fprintf(stderr, "[V853-Camera] Failed to open /dev/video0: %s\n", strerror(errno));
        free(client);
        return NULL;
    }
    printf("[V853-Camera] Opened /dev/video0 successfully\n");

    // 2. 查询设备能力
    struct v4l2_capability cap;
    if (ioctl(client->video_fd, VIDIOC_QUERYCAP, &cap) < 0) {
        fprintf(stderr, "[V853-Camera] VIDIOC_QUERYCAP failed: %s\n", strerror(errno));
        close(client->video_fd);
        free(client);
        return NULL;
    }
    printf("[V853-Camera] Driver: %s, Card: %s\n", cap.driver, cap.card);

    // 3. 设置图像格式 (默认1920x1080 NV12)
    struct v4l2_format fmt;
    memset(&fmt, 0, sizeof(fmt));
    fmt.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    fmt.fmt.pix.width = 1920;
    fmt.fmt.pix.height = 1080;
    fmt.fmt.pix.pixelformat = V4L2_PIX_FMT_NV12;  // V853推荐格式
    fmt.fmt.pix.field = V4L2_FIELD_NONE;

    if (ioctl(client->video_fd, VIDIOC_S_FMT, &fmt) < 0) {
        fprintf(stderr, "[V853-Camera] VIDIOC_S_FMT failed: %s\n", strerror(errno));
        close(client->video_fd);
        free(client);
        return NULL;
    }

    client->width = fmt.fmt.pix.width;
    client->height = fmt.fmt.pix.height;
    client->format = AI_MEDIA_FORMAT_NV12;
    printf("[V853-Camera] Format set: %dx%d NV12\n", client->width, client->height);

    // 4. 请求buffer
    struct v4l2_requestbuffers req;
    memset(&req, 0, sizeof(req));
    req.count = 4;
    req.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    req.memory = V4L2_MEMORY_MMAP;

    if (ioctl(client->video_fd, VIDIOC_REQBUFS, &req) < 0) {
        fprintf(stderr, "[V853-Camera] VIDIOC_REQBUFS failed: %s\n", strerror(errno));
        close(client->video_fd);
        free(client);
        return NULL;
    }
    client->buffer_count = req.count;
    printf("[V853-Camera] Allocated %d buffers\n", client->buffer_count);

    // 5. mmap buffer并入队
    for (int i = 0; i < client->buffer_count; i++) {
        struct v4l2_buffer buf;
        memset(&buf, 0, sizeof(buf));
        buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
        buf.memory = V4L2_MEMORY_MMAP;
        buf.index = i;

        if (ioctl(client->video_fd, VIDIOC_QUERYBUF, &buf) < 0) {
            fprintf(stderr, "[V853-Camera] VIDIOC_QUERYBUF %d failed\n", i);
            goto error_cleanup;
        }

        client->buffer_lengths[i] = buf.length;
        client->buffers[i] = mmap(NULL, buf.length,
                                  PROT_READ | PROT_WRITE,
                                  MAP_SHARED,
                                  client->video_fd,
                                  buf.m.offset);

        if (client->buffers[i] == MAP_FAILED) {
            fprintf(stderr, "[V853-Camera] mmap buffer %d failed\n", i);
            goto error_cleanup;
        }

        // 入队buffer
        if (ioctl(client->video_fd, VIDIOC_QBUF, &buf) < 0) {
            fprintf(stderr, "[V853-Camera] VIDIOC_QBUF %d failed\n", i);
            goto error_cleanup;
        }
    }

    // 6. 开始捕获
    enum v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    if (ioctl(client->video_fd, VIDIOC_STREAMON, &type) < 0) {
        fprintf(stderr, "[V853-Camera] VIDIOC_STREAMON failed: %s\n", strerror(errno));
        goto error_cleanup;
    }

    printf("[V853-Camera] Camera initialized successfully\n");
    return client;

error_cleanup:
    for (int i = 0; i < client->buffer_count; i++) {
        if (client->buffers[i] != NULL && client->buffers[i] != MAP_FAILED) {
            munmap(client->buffers[i], client->buffer_lengths[i]);
        }
    }
    close(client->video_fd);
    free(client);
    return NULL;
}

// 捕获一帧图像
int ai_core_capture(ai_core_client_t *client, ai_core_data_t *data, int timeout_ms) {
    if (!client || !data) {
        return AI_MEDIA_ERROR_INIT;
    }

    // 等待buffer就绪
    fd_set fds;
    struct timeval tv;
    FD_ZERO(&fds);
    FD_SET(client->video_fd, &fds);

    if (timeout_ms > 0) {
        tv.tv_sec = timeout_ms / 1000;
        tv.tv_usec = (timeout_ms % 1000) * 1000;
    } else {
        tv.tv_sec = 5;  // 默认5秒超时
        tv.tv_usec = 0;
    }

    int ret = select(client->video_fd + 1, &fds, NULL, NULL, &tv);
    if (ret < 0) {
        fprintf(stderr, "[V853-Camera] select() failed: %s\n", strerror(errno));
        return AI_MEDIA_ERROR_CAPTURE;
    } else if (ret == 0) {
        fprintf(stderr, "[V853-Camera] Capture timeout\n");
        return AI_MEDIA_ERROR_TIMEOUT;
    }

    // 出队buffer
    struct v4l2_buffer buf;
    memset(&buf, 0, sizeof(buf));
    buf.type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    buf.memory = V4L2_MEMORY_MMAP;

    if (ioctl(client->video_fd, VIDIOC_DQBUF, &buf) < 0) {
        fprintf(stderr, "[V853-Camera] VIDIOC_DQBUF failed: %s\n", strerror(errno));
        return AI_MEDIA_ERROR_CAPTURE;
    }

    // 复制数据到应用层buffer
    data->size = buf.bytesused;
    data->data = malloc(data->size);
    if (!data->data) {
        fprintf(stderr, "[V853-Camera] Failed to allocate data buffer\n");
        ioctl(client->video_fd, VIDIOC_QBUF, &buf);  // 重新入队
        return AI_MEDIA_ERROR_MEMORY;
    }

    memcpy(data->data, client->buffers[buf.index], data->size);
    data->width = client->width;
    data->height = client->height;
    data->format = client->format;
    data->sequence = client->sequence++;

    // 重新入队buffer
    if (ioctl(client->video_fd, VIDIOC_QBUF, &buf) < 0) {
        fprintf(stderr, "[V853-Camera] VIDIOC_QBUF re-queue failed\n");
    }

    return AI_MEDIA_SUCCESS;
}

// 释放数据
void ai_core_free_data(ai_core_data_t *data) {
    if (data && data->data) {
        free(data->data);
        data->data = NULL;
        data->size = 0;
    }
}

// 清理资源
void ai_core_cleanup(ai_core_client_t *client) {
    if (!client) {
        return;
    }

    // 停止捕获
    enum v4l2_buf_type type = V4L2_BUF_TYPE_VIDEO_CAPTURE;
    ioctl(client->video_fd, VIDIOC_STREAMOFF, &type);

    // 释放buffers
    for (int i = 0; i < client->buffer_count; i++) {
        if (client->buffers[i] != NULL && client->buffers[i] != MAP_FAILED) {
            munmap(client->buffers[i], client->buffer_lengths[i]);
        }
    }

    // 关闭设备
    close(client->video_fd);
    free(client);

    printf("[V853-Camera] Camera cleanup completed\n");
}

// 获取错误信息
const char* ai_core_get_error_string(int error_code) {
    switch (error_code) {
        case AI_MEDIA_SUCCESS:      return "Success";
        case AI_MEDIA_ERROR_INIT:   return "Initialization error";
        case AI_MEDIA_ERROR_TIMEOUT: return "Timeout";
        case AI_MEDIA_ERROR_CAPTURE: return "Capture error";
        case AI_MEDIA_ERROR_MEMORY:  return "Memory allocation error";
        default:                     return "Unknown error";
    }
}
