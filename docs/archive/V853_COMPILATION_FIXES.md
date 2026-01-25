# V853 编译错误修复方案

**日期**: 2026-01-23
**问题**: src/sdk_adapter/src/*.c 文件无法编译
**根本原因**: 接口定义(头文件)与实现文件不匹配

---

## 问题诊断

### 发现的接口不匹配

| 文件 | 头文件定义 | 实现文件提供 | 状态 |
|------|-----------|------------|------|
| `ai_camera_v853.c` | `ai_camera.h` 定义 `ai_core_*` 接口 | ✅ 实现了 `ai_core_*` 接口 | **匹配** |
| `ai_gpio_v853.c` | `ai_gpio.h` 定义复杂的事件服务接口 | ❌ 实现了简单的 `gpio_client_*` 接口 | **不匹配** |
| `ai_audio_v853.c` | `ai_audio.h` (未查看) | 未知 | **待验证** |
| `ai_log_v853.c` | `ai_log.h` (未查看) | 未知 | **待验证** |

###根本问题

**SDK/ai_glass_sdk/include/** 下的头文件定义了完整的IPC服务架构（来自RV1109平台），但 **src/sdk_adapter/src/** 下的实现文件是V853的简化实现。

---

## 解决方案

### 方案A：创建简化的RV1109兼容层（推荐）

在V853实现文件中添加兼容层，让RV1109接口调用V853的简单实现。

**优点**：
- 应用层代码无需修改
- 保持向后兼容
- 编译可快速通过

**实现**：在每个 `*_v853.c` 文件末尾添加适配器函数

### 方案B：修改头文件为V853简化接口

修改 `SDK/ai_glass_sdk/include/` 下的头文件，使其匹配V853的简单实现。

**优点**：
- 接口清晰简单
- 无需兼容层开销

**缺点**：
- 破坏RV1109兼容性
- 应用层代码需要修改

---

## 推荐实现：方案A（添加兼容层）

### 1. ai_gpio_v853.c 修复

在文件末尾添加RV1109兼容层：

```c
// ============================================================================
// RV1109 Compatibility Layer - GPIO Event Service API
// ============================================================================

/**
 * V853平台上的简化实现：
 * - 不实现完整的IPC事件服务
 * - 直接使用GPIO sysfs接口
 * - 回调在本地线程中触发
 */

// 全局GPIO客户端实例（简化实现）
static gpio_client_ctx_t *g_gpio_clients[GPIO_EVENT_MAX_GPIO_COUNT] = {NULL};

// 服务端API实现（V853上简化为存根）
int ai_gpio_init(
    gpio_event_service_t *service,
    int gpio_number,
    const char *gpio_debug_path,
    int poll_interval_ms,
    int enable_external_events
) {
    (void)gpio_debug_path;
    (void)poll_interval_ms;
    (void)enable_external_events;

    if (!service || gpio_number < 0 || gpio_number >= GPIO_EVENT_MAX_GPIO_COUNT) {
        return -1;
    }

    memset(service, 0, sizeof(*service));
    service->gpio_number = gpio_number;
    service->service_initialized = 1;

    printf("[V853-GPIO-Compat] Service init for GPIO%d (simplified mode)\n", gpio_number);
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
        printf("[V853-GPIO-Compat] Service cleanup for GPIO%d\n", service->gpio_number);
    }
}

// 客户端API实现（适配到V853的简单接口）

// 内部回调适配器
static void gpio_callback_adapter(gpio_event_t event_type, int gpio_num, void *user_data) {
    gpio_event_client_t *client = (gpio_event_client_t *)user_data;
    if (client && client->event_callback) {
        client->event_callback(event_type, gpio_num, client->user_data);
    }
}

int ai_gpio_event_client_create(gpio_event_client_t *client) {
    if (!client) {
        return -1;
    }

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

    // 转换GPIO逻辑编号到物理编号（V853特定）
    // 例如: GPIO1 -> PH9 = 7*32+9 = 233
    int physical_gpio = 0;
    switch (gpio_number) {
        case 0: physical_gpio = 224; break;  // PH0
        case 1: physical_gpio = 233; break;  // PH9 (示例)
        default: physical_gpio = 233; break;
    }

    // 初始化底层GPIO
    gpio_client_ctx_t *gpio_ctx = gpio_client_init(physical_gpio);
    if (!gpio_ctx) {
        fprintf(stderr, "[V853-GPIO-Compat] Failed to init GPIO%d (phys:%d)\n",
                gpio_number, physical_gpio);
        return -1;
    }

    g_gpio_clients[gpio_number] = gpio_ctx;
    client->is_connected = 1;

    printf("[V853-GPIO-Compat] Client connected to GPIO%d (phys:%d)\n",
           gpio_number, physical_gpio);
    return 0;
}

int ai_gpio_event_client_subscribe(
    gpio_event_client_t *client,
    gpio_event_callback_t event_callback,
    void *user_data
) {
    if (!client || !client->is_connected || !event_callback) {
        return -1;
    }

    client->event_callback = event_callback;
    client->user_data = user_data;

    // 注册底层回调（需要获取GPIO编号）
    // 简化：假设连接了GPIO1
    if (g_gpio_clients[1]) {
        if (gpio_register_callback(g_gpio_clients[1], gpio_callback_adapter, client) < 0) {
            return -1;
        }
    }

    client->is_listening = 1;
    printf("[V853-GPIO-Compat] Client subscribed\n");
    return 0;
}

void ai_gpio_event_client_unsubscribe(gpio_event_client_t *client) {
    if (client) {
        client->is_listening = 0;
        printf("[V853-GPIO-Compat] Client unsubscribed\n");
    }
}

void ai_gpio_event_client_disconnect(gpio_event_client_t *client) {
    if (client) {
        // 清理底层GPIO（简化版本）
        for (int i = 0; i < GPIO_EVENT_MAX_GPIO_COUNT; i++) {
            if (g_gpio_clients[i]) {
                gpio_client_cleanup(g_gpio_clients[i]);
                g_gpio_clients[i] = NULL;
            }
        }
        client->is_connected = 0;
        printf("[V853-GPIO-Compat] Client disconnected\n");
    }
}

void ai_gpio_event_client_destroy(gpio_event_client_t *client) {
    if (client) {
        memset(client, 0, sizeof(*client));
        printf("[V853-GPIO-Compat] Client destroyed\n");
    }
}

int ai_gpio_event_client_is_service_alive(gpio_event_client_t *client) {
    return (client && client->is_connected) ? 1 : 0;
}

// 辅助函数实现
#include <sys/time.h>

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
```

---

### 2. ai_gpio_v853.c 修改GPIO事件结构体

在文件顶部添加事件结构体适配：

```c
// 修改原来的 gpio_monitor_thread 中的回调触发部分
// 原代码：
if (ctx->callback) {
    gpio_event_t event;  // ❌ 错误：gpio_event_t 是枚举，不是结构体
    event.type = value ? GPIO_EVENT_PRESS : GPIO_EVENT_RELEASE;
    // ...
    ctx->callback(&event, ctx->user_data);
}

// 修改后：
if (ctx->callback) {
    gpio_event_t event_type = value ? GPIO_EVENT_PRESS : GPIO_EVENT_RELEASE;
    ctx->callback(event_type, ctx->gpio_num, ctx->user_data);
}
```

**同时修改回调函数类型定义**（在文件开头）：

```c
// 内部使用的回调类型（与ai_gpio.h匹配）
typedef void (*gpio_event_callback_t)(gpio_event_t event_type, int gpio_number, void *user_data);
```

---

### 3. ai_log_v853.c 修复

查看ai_log.h看需要哪些接口，然后在ai_log_v853.c中实现。

预计需要添加：
```c
#include "ai_log.h"

// 实现日志函数
void ai_log_write(int level, const char *tag, const char *fmt, ...) {
    va_list args;
    va_start(args, fmt);

    const char *level_str = "INFO";
    switch (level) {
        case AI_LOG_DEBUG:   level_str = "DEBUG"; break;
        case AI_LOG_INFO:    level_str = "INFO"; break;
        case AI_LOG_WARN:    level_str = "WARN"; break;
        case AI_LOG_ERROR:   level_str = "ERROR"; break;
    }

    printf("[%s][%s] ", level_str, tag);
    vprintf(fmt, args);
    printf("\n");

    va_end(args);
}
```

---

### 4. ai_audio_v853.c 修复

同样需要查看ai_audio.h的接口定义，然后实现或添加适配层。

---

## 立即可执行的修复步骤

### 步骤1：检查所有头文件

```bash
cd SDK/ai_glass_sdk/include
ls -la *.h
```

查看：
- ai_camera.h  ✅ 已查看（接口匹配）
- ai_gpio.h    ✅ 已查看（接口不匹配）
- ai_audio.h   ⚠️ 需要查看
- ai_log.h     ⚠️ 需要查看
- ai_ipc.h     ⚠️ GPIO依赖

### 步骤2：修复ai_gpio_v853.c

1. 修改回调触发代码（第140-154行）
2. 添加文件末尾的兼容层代码（约200行）

### 步骤3：验证其他文件

检查ai_audio_v853.c和ai_log_v853.c是否也需要类似修复

### 步骤4：编译测试

```bash
./start-docker.sh shell
cd /workspace
make sdk
```

---

## 预期结果

修复后编译应该：
- ✅ 无类型冲突错误
- ✅ 无未定义函数错误
- ✅ 生成 libai_glass_sdk_v853.a 和 .so
- ⚠️ 可能有警告（unused parameters），可忽略

---

## 下一步行动

**选择一种方式**：

### 选项A：我立即修复所有文件（自动化）
1. 检查ai_audio.h和ai_log.h
2. 修复ai_gpio_v853.c
3. 修复ai_audio_v853.c
4. 修复ai_log_v853.c
5. 验证编译

### 选项B：逐个文件修复（手动控制）
1. 先只修复ai_gpio_v853.c
2. 验证编译该文件
3. 然后处理下一个文件

### 选项C：创建最小stub实现
1. 所有未实现的函数返回错误或dummy值
2. 添加TODO注释
3. 目标：先让编译通过

---

**建议**：选择选项C（最小stub），因为：
- 最快速度让编译通过
- 可以验证其他组件（display_qt等）
- 后续逐步完善功能实现
