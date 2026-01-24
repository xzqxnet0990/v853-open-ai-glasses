/**
 * V853 Camera Test Example
 *
 * 演示如何使用ai_camera.h接口在V853平台捕获图像
 *
 * 编译:
 *   cd build && cmake .. && make
 *
 * 运行:
 *   ./camera_test
 */

#include "ai_camera.h"
#include "ai_log.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <signal.h>

static int running = 1;

void signal_handler(int sig) {
    printf("\n捕获到信号 %d, 退出程序...\n", sig);
    running = 0;
}

int main(int argc, char *argv[]) {
    printf("=== V853 Camera Test ===\n");
    printf("按Ctrl+C退出程序\n\n");

    // 注册信号处理
    signal(SIGINT, signal_handler);
    signal(SIGTERM, signal_handler);

    // 1. 初始化摄像头
    printf("[1] 初始化摄像头...\n");
    ai_core_client_t *camera = ai_core_init();
    if (!camera) {
        fprintf(stderr, "错误: 摄像头初始化失败!\n");
        return -1;
    }
    printf("    摄像头初始化成功\n\n");

    // 2. 捕获图像
    int frame_count = 0;
    printf("[2] 开始捕获图像...\n");

    while (running) {
        ai_core_data_t data;

        // 捕获一帧 (2秒超时)
        int ret = ai_core_capture(camera, &data, 2000);
        if (ret != AI_MEDIA_SUCCESS) {
            fprintf(stderr, "捕获失败: %s\n", ai_core_get_error_string(ret));
            continue;
        }

        frame_count++;
        printf("    Frame #%d: %dx%d, size=%zu bytes, format=%s\n",
               data.sequence,
               data.width,
               data.height,
               data.size,
               data.format == AI_MEDIA_FORMAT_NV12 ? "NV12" : "JPEG");

        // 这里可以处理图像数据
        // 例如: 保存为文件、显示、发送到服务器等

        // 释放数据
        ai_core_free_data(&data);

        // 每秒捕获1帧
        sleep(1);

        if (frame_count >= 10) {
            printf("\n已捕获10帧,退出测试\n");
            break;
        }
    }

    // 3. 清理资源
    printf("\n[3] 清理资源...\n");
    ai_core_cleanup(camera);
    printf("    清理完成\n");

    printf("\n=== 测试完成 ===\n");
    printf("总共捕获 %d 帧图像\n", frame_count);

    return 0;
}
