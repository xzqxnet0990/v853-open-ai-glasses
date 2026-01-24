/**
 * RV1109 GPIO API Compatibility Layer for V853
 *
 * 提供RV1109 GPIO事件服务API的简化实现
 * 在V853上使用GPIO sysfs接口
 */

#include "ai_gpio.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>

// 声明ai_gpio_v853.c中的内部函数
typedef struct gpio_client_ctx gpio_client_ctx_t;
extern gpio_client_ctx_t* gpio_client_init(int gpio_num);
extern int gpio_register_callback(gpio_client_ctx_t *ctx,
                                  void (*callback)(gpio_event_t, int, void*),
                                  void *user_data);
extern void gpio_client_cleanup(gpio_client_ctx_t *ctx);

// 全局GPIO上下文数组
static gpio_client_ctx_t *g_gpio_contexts[GPIO_EVENT_MAX_GPIO_COUNT] = {NULL};

// ============================================================================
// 服务端API (简化实现 - stub)
// ============================================================================

int ai_gpio_init(gpio_event_service_t *service, int gpio_number,
                const char *gpio_debug_path, int poll_interval_ms,
                int enable_external_events) {
    (void)gpio_debug_path;
    (void)poll_interval_ms;
    (void)enable_external_events;

    if (!service || gpio_number < 0) {
        return -1;
    }

    memset(service, 0, sizeof(*service));
    service->gpio_number = gpio_number;
    service->service_initialized = 1;

    printf("[V853-GPIO-Compat] Service init for GPIO%d (stub)\n", gpio_number);
    return 0;
}

int ai_gpio_start(gpio_event_service_t *service) {
    if (!service || !service->service_initialized) {
        return -1;
    }
    printf("[V853-GPIO-Compat] Service started for GPIO%d\n", service->gpio_number);
    return 0;
}

void ai_gpio_stop(gpio_event_service_t *service) {
    if (service) {
        printf("[V853-GPIO-Compat] Service stopped for GPIO%d\n", service->gpio_number);
    }
}

void ai_gpio_cleanup(gpio_event_service_t *service) {
    if (service) {
        service->service_initialized = 0;
    }
}

void ai_gpio_get_stats(gpio_event_service_t *service,
                      uint64_t *press_count,
                      uint64_t *release_count,
                      int *client_count) {
    (void)service;
    if (press_count) *press_count = 0;
    if (release_count) *release_count = 0;
    if (client_count) *client_count = 0;
}

int ai_gpio_publish_event(gpio_event_service_t *service,
                         gpio_event_t event_type,
                         int gpio_number) {
    (void)service;
    (void)event_type;
    (void)gpio_number;
    return 0;
}

// ============================================================================
// 客户端API (适配到v853_gpio简单接口)
// ============================================================================

int ai_gpio_event_client_create(gpio_event_client_t *client) {
    if (!client) return -1;
    memset(client, 0, sizeof(*client));
    return 0;
}

int ai_gpio_event_client_connect(gpio_event_client_t *client) {
    return ai_gpio_event_client_connect_gpio(client, 1);  // 默认GPIO1
}

int ai_gpio_event_client_connect_gpio(gpio_event_client_t *client, int gpio_number) {
    if (!client || gpio_number < 0 || gpio_number >= GPIO_EVENT_MAX_GPIO_COUNT) {
        return -1;
    }

    // 映射逻辑GPIO到物理GPIO (V853特定)
    int physical_gpio = 233;  // 默认PH9，可根据需要修改

    gpio_client_ctx_t *ctx = gpio_client_init(physical_gpio);
    if (!ctx) {
        fprintf(stderr, "[V853-GPIO-Compat] Failed to init GPIO%d (phys:%d)\n",
                gpio_number, physical_gpio);
        return -1;
    }

    g_gpio_contexts[gpio_number] = ctx;
    client->is_connected = 1;

    printf("[V853-GPIO-Compat] Client connected to GPIO%d (phys:%d)\n",
           gpio_number, physical_gpio);
    return 0;
}

// 回调适配器
static void gpio_callback_adapter(gpio_event_t event_type, int gpio_num, void *user_data) {
    gpio_event_client_t *client = (gpio_event_client_t *)user_data;
    if (client && client->event_callback) {
        client->event_callback(event_type, gpio_num, client->user_data);
    }
}

int ai_gpio_event_client_subscribe(gpio_event_client_t *client,
                                   gpio_event_callback_t event_callback,
                                   void *user_data) {
    if (!client || !client->is_connected || !event_callback) {
        return -1;
    }

    client->event_callback = event_callback;
    client->user_data = user_data;

    // 注册到底层GPIO (假设GPIO1)
    if (g_gpio_contexts[1]) {
        if (gpio_register_callback(g_gpio_contexts[1], gpio_callback_adapter, client) < 0) {
            return -1;
        }
    }

    client->is_listening = 1;
    return 0;
}

void ai_gpio_event_client_unsubscribe(gpio_event_client_t *client) {
    if (client) {
        client->is_listening = 0;
    }
}

void ai_gpio_event_client_disconnect(gpio_event_client_t *client) {
    if (client && client->is_connected) {
        // 清理底层GPIO
        for (int i = 0; i < GPIO_EVENT_MAX_GPIO_COUNT; i++) {
            if (g_gpio_contexts[i]) {
                gpio_client_cleanup(g_gpio_contexts[i]);
                g_gpio_contexts[i] = NULL;
            }
        }
        client->is_connected = 0;
    }
}

void ai_gpio_event_client_destroy(gpio_event_client_t *client) {
    if (client) {
        memset(client, 0, sizeof(*client));
    }
}

int ai_gpio_event_client_is_service_alive(gpio_event_client_t *client) {
    return (client && client->is_connected) ? 1 : 0;
}

// ============================================================================
// GPIO Hub API (stub实现)
// ============================================================================

int ai_gpio_hub_client_create(gpio_event_hub_client_t *client) {
    if (!client) return -1;
    memset(client, 0, sizeof(*client));
    return 0;
}

int ai_gpio_hub_client_connect(gpio_event_hub_client_t *client) {
    (void)client;
    return -1;  // Not implemented
}

int ai_gpio_hub_client_subscribe_gpios(gpio_event_hub_client_t *client,
                                      const int *gpio_list, int gpio_count,
                                      gpio_event_callback_t callback, void *user_data) {
    (void)client; (void)gpio_list; (void)gpio_count; (void)callback; (void)user_data;
    return -1;
}

int ai_gpio_hub_client_subscribe_all(gpio_event_hub_client_t *client,
                                     gpio_event_callback_t callback, void *user_data) {
    (void)client; (void)callback; (void)user_data;
    return -1;
}

int ai_gpio_hub_client_get_gpio_state(gpio_event_hub_client_t *client, int gpio_number) {
    (void)client; (void)gpio_number;
    return -1;
}

int ai_gpio_hub_client_get_active_gpios(gpio_event_hub_client_t *client,
                                       int *gpio_list, int max_count) {
    (void)client; (void)gpio_list; (void)max_count;
    return 0;
}

void ai_gpio_hub_client_unsubscribe(gpio_event_hub_client_t *client) {
    (void)client;
}

void ai_gpio_hub_client_disconnect(gpio_event_hub_client_t *client) {
    (void)client;
}

void ai_gpio_hub_client_destroy(gpio_event_hub_client_t *client) {
    if (client) memset(client, 0, sizeof(*client));
}

int ai_gpio_hub_client_is_service_alive(gpio_event_hub_client_t *client) {
    (void)client;
    return 0;
}

// ============================================================================
// 辅助函数
// ============================================================================

uint64_t ai_gpio_get_timestamp_us(void) {
    struct timeval tv;
    gettimeofday(&tv, NULL);
    return (uint64_t)tv.tv_sec * 1000000 + tv.tv_usec;
}

uint64_t ai_gpio_get_timestamp_sec(void) {
    return (uint64_t)time(NULL);
}

const char* ai_gpio_event_type_to_string(gpio_event_t event_type) {
    switch (event_type) {
        case GPIO_EVENT_PRESS:   return "PRESS";
        case GPIO_EVENT_RELEASE: return "RELEASE";
        case GPIO_EVENT_ERROR:   return "ERROR";
        default:                 return "UNKNOWN";
    }
}

void ai_gpio_get_shm_name(int gpio_number, char *buffer, size_t buffer_size) {
    snprintf(buffer, buffer_size, GPIO_EVENT_SHM_NAME_FMT, gpio_number);
}

void ai_gpio_get_socket_path(int gpio_number, char *buffer, size_t buffer_size) {
    snprintf(buffer, buffer_size, GPIO_EVENT_SOCKET_PATH_FMT, gpio_number);
}
