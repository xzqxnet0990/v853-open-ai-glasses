/**
 * AI Log Adapter for V853 Platform
 *
 * 提供统一的日志接口，适配V853平台
 * - 支持多级别日志 (DEBUG, INFO, WARN, ERROR)
 * - 支持文件输出和控制台输出
 * - 包含时间戳和模块标识
 */

#include "ai_log.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <time.h>
#include <sys/time.h>
#include <pthread.h>

// 日志级别定义（内部使用）
#define AI_LOG_DEBUG  0
#define AI_LOG_INFO   1
#define AI_LOG_WARN   2
#define AI_LOG_ERROR  3

// 日志级别字符串
static const char *level_strings[] = {
    "DEBUG", "INFO", "WARN", "ERROR"
};

// 日志级别颜色 (ANSI终端)
static const char *level_colors[] = {
    "\033[36m",  // DEBUG - 青色
    "\033[32m",  // INFO  - 绿色
    "\033[33m",  // WARN  - 黄色
    "\033[31m"   // ERROR - 红色
};
static const char *color_reset = "\033[0m";

// 全局日志配置
static struct {
    int level;           // 当前日志级别
    int use_color;       // 是否使用颜色
    FILE *file;          // 日志文件句柄
    pthread_mutex_t lock;// 线程锁
} log_config = {
    .level = AI_LOG_DEBUG,
    .use_color = 1,
    .file = NULL,
};

// 初始化日志系统
void ai_log_init(int level, const char *log_file) {
    pthread_mutex_init(&log_config.lock, NULL);
    log_config.level = level;

    // 如果指定了日志文件
    if (log_file) {
        log_config.file = fopen(log_file, "a");
        if (!log_config.file) {
            fprintf(stderr, "[V853-Log] Failed to open log file: %s\n", log_file);
        } else {
            printf("[V853-Log] Logging to file: %s\n", log_file);
        }
    }

    // 检查是否支持彩色输出 (检查TERM环境变量)
    const char *term = getenv("TERM");
    log_config.use_color = (term && strstr(term, "color"));

    printf("[V853-Log] Log system initialized (level=%d, color=%d)\n",
           log_config.level, log_config.use_color);
}

// 设置日志级别
void ai_log_set_level(int level) {
    pthread_mutex_lock(&log_config.lock);
    log_config.level = level;
    pthread_mutex_unlock(&log_config.lock);
}

// 获取当前时间戳字符串
static void get_timestamp(char *buffer, size_t size) {
    struct timeval tv;
    gettimeofday(&tv, NULL);

    struct tm *tm_info = localtime(&tv.tv_sec);
    int ms = tv.tv_usec / 1000;

    snprintf(buffer, size, "%02d:%02d:%02d.%03d",
             tm_info->tm_hour, tm_info->tm_min, tm_info->tm_sec, ms);
}

// 核心日志函数
void ai_log_print(int level, const char *module, const char *format, ...) {
    // 检查日志级别
    if (level < log_config.level) {
        return;
    }

    pthread_mutex_lock(&log_config.lock);

    // 获取时间戳
    char timestamp[32];
    get_timestamp(timestamp, sizeof(timestamp));

    // 构建日志前缀
    char prefix[256];
    if (log_config.use_color) {
        snprintf(prefix, sizeof(prefix), "%s[%s] [%s] [%s]%s ",
                 level_colors[level], timestamp, level_strings[level],
                 module, color_reset);
    } else {
        snprintf(prefix, sizeof(prefix), "[%s] [%s] [%s] ",
                 timestamp, level_strings[level], module);
    }

    // 构建完整日志消息
    va_list args;
    char message[1024];

    va_start(args, format);
    vsnprintf(message, sizeof(message), format, args);
    va_end(args);

    // 输出到控制台
    fprintf(stderr, "%s%s\n", prefix, message);

    // 输出到文件 (不包含颜色)
    if (log_config.file) {
        fprintf(log_config.file, "[%s] [%s] [%s] %s\n",
                timestamp, level_strings[level], module, message);
        fflush(log_config.file);
    }

    pthread_mutex_unlock(&log_config.lock);
}

// 清理日志系统
void ai_log_cleanup(void) {
    pthread_mutex_lock(&log_config.lock);

    if (log_config.file) {
        fclose(log_config.file);
        log_config.file = NULL;
    }

    pthread_mutex_unlock(&log_config.lock);
    pthread_mutex_destroy(&log_config.lock);

    printf("[V853-Log] Log system cleaned up\n");
}

// ============================================================================
// Simple Log API Compatibility Layer (for ai_log.h)
// ============================================================================

/**
 * V853 implementation of simple log functions defined in ai_log.h
 */

void log_info(const char *fmt, ...) {
    char timestamp[64];
    struct timeval tv;
    struct tm *tm_info;
    char time_str[64];

    gettimeofday(&tv, NULL);
    tm_info = localtime(&tv.tv_sec);
    strftime(time_str, sizeof(time_str), "%Y-%m-%d %H:%M:%S", tm_info);
    snprintf(timestamp, sizeof(timestamp), "[%s.%03ld]", time_str, tv.tv_usec / 1000);

    printf("%s [INFO] ", timestamp);

    va_list args;
    va_start(args, fmt);
    vprintf(fmt, args);
    va_end(args);

    fflush(stdout);
}

void log_error(const char *fmt, ...) {
    char timestamp[64];
    struct timeval tv;
    struct tm *tm_info;
    char time_str[64];

    gettimeofday(&tv, NULL);
    tm_info = localtime(&tv.tv_sec);
    strftime(time_str, sizeof(time_str), "%Y-%m-%d %H:%M:%S", tm_info);
    snprintf(timestamp, sizeof(timestamp), "[%s.%03ld]", time_str, tv.tv_usec / 1000);

    fprintf(stderr, "%s [ERROR] ", timestamp);

    va_list args;
    va_start(args, fmt);
    vfprintf(stderr, fmt, args);
    va_end(args);

    fflush(stderr);
}

void log_debug(const char *fmt, ...) {
    char timestamp[64];
    struct timeval tv;
    struct tm *tm_info;
    char time_str[64];

    gettimeofday(&tv, NULL);
    tm_info = localtime(&tv.tv_sec);
    strftime(time_str, sizeof(time_str), "%Y-%m-%d %H:%M:%S", tm_info);
    snprintf(timestamp, sizeof(timestamp), "[%s.%03ld]", time_str, tv.tv_usec / 1000);

    printf("%s [DEBUG] ", timestamp);

    va_list args;
    va_start(args, fmt);
    vprintf(fmt, args);
    va_end(args);

    fflush(stdout);
}

void log_warn(const char *fmt, ...) {
    char timestamp[64];
    struct timeval tv;
    struct tm *tm_info;
    char time_str[64];

    gettimeofday(&tv, NULL);
    tm_info = localtime(&tv.tv_sec);
    strftime(time_str, sizeof(time_str), "%Y-%m-%d %H:%M:%S", tm_info);
    snprintf(timestamp, sizeof(timestamp), "[%s.%03ld]", time_str, tv.tv_usec / 1000);

    fprintf(stderr, "%s [WARN] ", timestamp);

    va_list args;
    va_start(args, fmt);
    vfprintf(stderr, fmt, args);
    va_end(args);

    fflush(stderr);
}
