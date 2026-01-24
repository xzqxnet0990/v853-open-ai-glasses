/**
 * AI GPIO Adapter for V853 Platform
 *
 * V853 GPIO架构:
 * - 使用标准Linux GPIO sysfs接口
 * - GPIO编号: PH0-PH15, PA0-PA31等
 * - 中断支持: 通过epoll监听GPIO value变化
 *
 * GPIO编号计算:
 * V853: GPIO_NUM = (Bank * 32) + Pin
 * 例如: PH9 = (7 * 32) + 9 = 233
 * Bank编号: PA=0, PB=1, PC=2, PD=3, PE=4, PF=5, PG=6, PH=7
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <poll.h>
#include <pthread.h>
#include "ai_gpio.h"

#define GPIO_SYSFS_BASE "/sys/class/gpio"
#define MAX_GPIO_NUM 512

// GPIO客户端上下文
typedef struct gpio_client_ctx {
    int gpio_num;                   // GPIO编号
    gpio_event_callback_t callback; // 事件回调
    void *user_data;                // 用户数据
    pthread_t thread;               // 监听线程
    int running;                    // 运行标志
    int value_fd;                   // GPIO value文件描述符
} gpio_client_ctx_t;

// 导出GPIO
static int gpio_export(int gpio_num) {
    char path[256];
    snprintf(path, sizeof(path), "%s/gpio%d", GPIO_SYSFS_BASE, gpio_num);

    // 检查是否已导出
    if (access(path, F_OK) == 0) {
        printf("[V853-GPIO] GPIO%d already exported\n", gpio_num);
        return 0;
    }

    // 导出GPIO
    int fd = open(GPIO_SYSFS_BASE "/export", O_WRONLY);
    if (fd < 0) {
        fprintf(stderr, "[V853-GPIO] Failed to open export: %s\n", strerror(errno));
        return -1;
    }

    char buf[16];
    snprintf(buf, sizeof(buf), "%d", gpio_num);
    if (write(fd, buf, strlen(buf)) < 0) {
        fprintf(stderr, "[V853-GPIO] Failed to export GPIO%d: %s\n", gpio_num, strerror(errno));
        close(fd);
        return -1;
    }

    close(fd);
    usleep(100000);  // 等待sysfs节点创建
    printf("[V853-GPIO] GPIO%d exported successfully\n", gpio_num);
    return 0;
}

// 设置GPIO方向
static int gpio_set_direction(int gpio_num, const char *direction) {
    char path[256];
    snprintf(path, sizeof(path), "%s/gpio%d/direction", GPIO_SYSFS_BASE, gpio_num);

    int fd = open(path, O_WRONLY);
    if (fd < 0) {
        fprintf(stderr, "[V853-GPIO] Failed to open direction: %s\n", strerror(errno));
        return -1;
    }

    if (write(fd, direction, strlen(direction)) < 0) {
        fprintf(stderr, "[V853-GPIO] Failed to set direction: %s\n", strerror(errno));
        close(fd);
        return -1;
    }

    close(fd);
    printf("[V853-GPIO] GPIO%d direction set to %s\n", gpio_num, direction);
    return 0;
}

// 设置边沿触发
static int gpio_set_edge(int gpio_num, const char *edge) {
    char path[256];
    snprintf(path, sizeof(path), "%s/gpio%d/edge", GPIO_SYSFS_BASE, gpio_num);

    int fd = open(path, O_WRONLY);
    if (fd < 0) {
        fprintf(stderr, "[V853-GPIO] Failed to open edge: %s\n", strerror(errno));
        return -1;
    }

    if (write(fd, edge, strlen(edge)) < 0) {
        fprintf(stderr, "[V853-GPIO] Failed to set edge: %s\n", strerror(errno));
        close(fd);
        return -1;
    }

    close(fd);
    printf("[V853-GPIO] GPIO%d edge set to %s\n", gpio_num, edge);
    return 0;
}

// GPIO监听线程
static void* gpio_monitor_thread(void *arg) {
    gpio_client_ctx_t *ctx = (gpio_client_ctx_t *)arg;
    struct pollfd pfd;
    char buf[2];

    pfd.fd = ctx->value_fd;
    pfd.events = POLLPRI | POLLERR;

    // 初始读取清除边沿状态
    lseek(ctx->value_fd, 0, SEEK_SET);
    read(ctx->value_fd, buf, sizeof(buf));

    printf("[V853-GPIO] Monitoring GPIO%d started\n", ctx->gpio_num);

    while (ctx->running) {
        int ret = poll(&pfd, 1, 1000);  // 1秒超时
        if (ret < 0) {
            fprintf(stderr, "[V853-GPIO] poll() error: %s\n", strerror(errno));
            break;
        } else if (ret == 0) {
            continue;  // 超时继续
        }

        if (pfd.revents & POLLPRI) {
            // 读取GPIO值
            lseek(ctx->value_fd, 0, SEEK_SET);
            if (read(ctx->value_fd, buf, sizeof(buf)) > 0) {
                int value = (buf[0] == '1') ? 1 : 0;

                // 触发回调
                if (ctx->callback) {
                    gpio_event_t event_type = value ? GPIO_EVENT_PRESS : GPIO_EVENT_RELEASE;
                    ctx->callback(event_type, ctx->gpio_num, ctx->user_data);
                }
            }
        }
    }

    printf("[V853-GPIO] Monitoring GPIO%d stopped\n", ctx->gpio_num);
    return NULL;
}

// 初始化GPIO客户端
gpio_client_ctx_t* gpio_client_init(int gpio_num) {
    gpio_client_ctx_t *ctx = calloc(1, sizeof(gpio_client_ctx_t));
    if (!ctx) {
        fprintf(stderr, "[V853-GPIO] Failed to allocate context\n");
        return NULL;
    }

    ctx->gpio_num = gpio_num;
    ctx->running = 0;

    // 导出GPIO
    if (gpio_export(gpio_num) < 0) {
        free(ctx);
        return NULL;
    }

    // 设置为输入模式
    if (gpio_set_direction(gpio_num, "in") < 0) {
        free(ctx);
        return NULL;
    }

    // 设置边沿触发 (双边沿)
    if (gpio_set_edge(gpio_num, "both") < 0) {
        free(ctx);
        return NULL;
    }

    // 打开value文件
    char path[256];
    snprintf(path, sizeof(path), "%s/gpio%d/value", GPIO_SYSFS_BASE, gpio_num);
    ctx->value_fd = open(path, O_RDONLY);
    if (ctx->value_fd < 0) {
        fprintf(stderr, "[V853-GPIO] Failed to open value: %s\n", strerror(errno));
        free(ctx);
        return NULL;
    }

    printf("[V853-GPIO] GPIO%d initialized successfully\n", gpio_num);
    return ctx;
}

// 注册回调并启动监听
int gpio_register_callback(gpio_client_ctx_t *ctx, gpio_event_callback_t callback, void *user_data) {
    if (!ctx || !callback) {
        return -1;
    }

    ctx->callback = callback;
    ctx->user_data = user_data;
    ctx->running = 1;

    // 启动监听线程
    if (pthread_create(&ctx->thread, NULL, gpio_monitor_thread, ctx) != 0) {
        fprintf(stderr, "[V853-GPIO] Failed to create monitor thread\n");
        ctx->running = 0;
        return -1;
    }

    return 0;
}

// 清理GPIO客户端
void gpio_client_cleanup(gpio_client_ctx_t *ctx) {
    if (!ctx) {
        return;
    }

    // 停止监听线程
    if (ctx->running) {
        ctx->running = 0;
        pthread_join(ctx->thread, NULL);
    }

    // 关闭文件描述符
    if (ctx->value_fd >= 0) {
        close(ctx->value_fd);
    }

    // 取消导出GPIO (可选)
    // 注意: 如果其他进程也在使用,不要取消导出

    free(ctx);
    printf("[V853-GPIO] GPIO cleanup completed\n");
}

// 读取GPIO值
int gpio_read_value(gpio_client_ctx_t *ctx) {
    if (!ctx || ctx->value_fd < 0) {
        return -1;
    }

    char buf[2];
    lseek(ctx->value_fd, 0, SEEK_SET);
    if (read(ctx->value_fd, buf, sizeof(buf)) > 0) {
        return (buf[0] == '1') ? 1 : 0;
    }

    return -1;
}
