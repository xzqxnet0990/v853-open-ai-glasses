/**
 * AI Audio Adapter for V853 Platform
 *
 * V853音频架构:
 * - 使用ALSA (Advanced Linux Sound Architecture)
 * - 设备: hw:0,0 (默认声卡)
 * - 支持PCM格式: S16_LE, S24_LE, S32_LE
 * - 采样率: 8000-192000 Hz
 *
 * 实现策略:
 * - 使用tinyalsa库 (轻量级ALSA封装)
 * - PCM文件直接播放
 * - TTS功能通过外部服务实现
 */

#include "ai_audio.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/stat.h>

// V853平台使用tinyalsa
// 如果没有tinyalsa，使用ALSA原生接口
#ifdef USE_TINYALSA
#include <tinyalsa/asoundlib.h>
#else
// 简化的ALSA结构体定义
typedef struct pcm pcm_t;
#endif

// Audio client context
struct ai_audio {
    char socket_path[256];
    int sample_rate;
    int channels;
    int bit_width;
    int volume;
    pcm_t *pcm;
};

// 默认音频参数
#define DEFAULT_SAMPLE_RATE  16000
#define DEFAULT_CHANNELS     1
#define DEFAULT_BIT_WIDTH    16
#define DEFAULT_VOLUME       70

// V853 ALSA设备
#define ALSA_CARD            0
#define ALSA_DEVICE          0

// 创建默认参数
ai_audio_params_t ai_audio_create_default_params(const char *file_path) {
    ai_audio_params_t params;
    params.file_path = file_path;
    params.volume = -1;        // 使用默认音量
    params.force = 0;          // 排队播放
    params.sample_rate = -1;   // 使用默认采样率
    params.channels = -1;      // 使用默认声道数
    params.bit_width = -1;     // 使用默认位宽
    return params;
}

// 创建默认TTS参数
ai_audio_tts_params_t ai_audio_create_default_tts_params(const char *text) {
    ai_audio_tts_params_t params;
    params.text = text;
    params.volume = -1;
    params.force = 0;
    params.use_cache = 1;
    return params;
}

// 初始化音频客户端
ai_audio_t* ai_audio_init(const char *socket_path) {
    ai_audio_t *client = calloc(1, sizeof(ai_audio_t));
    if (!client) {
        fprintf(stderr, "[V853-Audio] Failed to allocate memory\n");
        return NULL;
    }

    // 保存socket路径 (用于TTS服务通信)
    if (socket_path) {
        snprintf(client->socket_path, sizeof(client->socket_path), "%s", socket_path);
    } else {
        snprintf(client->socket_path, sizeof(client->socket_path), "/tmp/ai-audio-service");
    }

    // 初始化默认参数
    client->sample_rate = DEFAULT_SAMPLE_RATE;
    client->channels = DEFAULT_CHANNELS;
    client->bit_width = DEFAULT_BIT_WIDTH;
    client->volume = DEFAULT_VOLUME;
    client->pcm = NULL;

    printf("[V853-Audio] Audio client initialized\n");
    printf("[V853-Audio] Socket: %s\n", client->socket_path);
    printf("[V853-Audio] Default: %dHz, %dch, %dbit\n",
           client->sample_rate, client->channels, client->bit_width);

    return client;
}

#ifdef USE_TINYALSA
// 使用tinyalsa打开PCM设备
static pcm_t* open_pcm_device(int sample_rate, int channels, int bit_width) {
    struct pcm_config config;
    memset(&config, 0, sizeof(config));

    config.channels = channels;
    config.rate = sample_rate;
    config.period_size = 1024;
    config.period_count = 4;
    config.format = (bit_width == 16) ? PCM_FORMAT_S16_LE :
                    (bit_width == 24) ? PCM_FORMAT_S24_LE : PCM_FORMAT_S32_LE;

    pcm_t *pcm = pcm_open(ALSA_CARD, ALSA_DEVICE, PCM_OUT, &config);
    if (!pcm || !pcm_is_ready(pcm)) {
        fprintf(stderr, "[V853-Audio] Failed to open PCM device: %s\n",
                pcm ? pcm_get_error(pcm) : "unknown error");
        if (pcm) {
            pcm_close(pcm);
        }
        return NULL;
    }

    printf("[V853-Audio] PCM device opened: card=%d device=%d\n", ALSA_CARD, ALSA_DEVICE);
    return pcm;
}
#else
// 占位实现 (需要实际的ALSA库)
static pcm_t* open_pcm_device(int sample_rate, int channels, int bit_width) {
    fprintf(stderr, "[V853-Audio] WARNING: ALSA not available, using stub\n");
    return NULL;
}
#endif

// 播放PCM文件
int ai_audio_play(ai_audio_t *client, const ai_audio_params_t *params) {
    if (!client || !params || !params->file_path) {
        return AI_AUDIO_ERROR_PARAM;
    }

    // 应用参数
    int sample_rate = (params->sample_rate > 0) ? params->sample_rate : client->sample_rate;
    int channels = (params->channels > 0) ? params->channels : client->channels;
    int bit_width = (params->bit_width > 0) ? params->bit_width : client->bit_width;
    int volume = (params->volume >= 0) ? params->volume : client->volume;

    printf("[V853-Audio] Playing: %s\n", params->file_path);
    printf("[V853-Audio] Format: %dHz, %dch, %dbit, vol=%d\n",
           sample_rate, channels, bit_width, volume);

    // 打开PCM文件
    int fd = open(params->file_path, O_RDONLY);
    if (fd < 0) {
        fprintf(stderr, "[V853-Audio] Failed to open file: %s (%s)\n",
                params->file_path, strerror(errno));
        return AI_AUDIO_ERROR_PARAM;
    }

    // 获取文件大小
    struct stat st;
    fstat(fd, &st);
    size_t file_size = st.st_size;
    printf("[V853-Audio] File size: %zu bytes\n", file_size);

#ifdef USE_TINYALSA
    // 打开PCM设备
    pcm_t *pcm = open_pcm_device(sample_rate, channels, bit_width);
    if (!pcm) {
        close(fd);
        return AI_AUDIO_ERROR_INIT;
    }

    // 读取并播放数据
    size_t buffer_size = 4096;
    char *buffer = malloc(buffer_size);
    if (!buffer) {
        close(fd);
        pcm_close(pcm);
        return AI_AUDIO_ERROR_INIT;
    }

    size_t total_written = 0;
    ssize_t bytes_read;

    while ((bytes_read = read(fd, buffer, buffer_size)) > 0) {
        int ret = pcm_write(pcm, buffer, bytes_read);
        if (ret < 0) {
            fprintf(stderr, "[V853-Audio] PCM write error: %s\n", pcm_get_error(pcm));
            break;
        }
        total_written += bytes_read;
    }

    printf("[V853-Audio] Played %zu/%zu bytes\n", total_written, file_size);

    // 清理
    free(buffer);
    pcm_close(pcm);
#else
    // 模拟播放 (没有实际ALSA库)
    printf("[V853-Audio] STUB: Simulating playback...\n");
    usleep(file_size * 1000000 / (sample_rate * channels * (bit_width / 8)));
#endif

    close(fd);
    printf("[V853-Audio] Playback completed\n");
    return AI_AUDIO_SUCCESS;
}

// 简化播放
int ai_audio_play_simple(ai_audio_t *client, const char *file_path) {
    ai_audio_params_t params = ai_audio_create_default_params(file_path);
    return ai_audio_play(client, &params);
}

// 停止播放
int ai_audio_stop(ai_audio_t *client) {
    if (!client) {
        return AI_AUDIO_ERROR_PARAM;
    }

    printf("[V853-Audio] Stopping playback\n");

#ifdef USE_TINYALSA
    if (client->pcm) {
        pcm_close(client->pcm);
        client->pcm = NULL;
    }
#endif

    return AI_AUDIO_SUCCESS;
}

// TTS播放 (通过Unix Socket与TTS服务通信)
int ai_audio_play_tts(ai_audio_t *client, const ai_audio_tts_params_t *params) {
    if (!client || !params || !params->text) {
        return AI_AUDIO_ERROR_PARAM;
    }

    printf("[V853-Audio] TTS: \"%s\"\n", params->text);
    printf("[V853-Audio] Volume=%d, Force=%d, Cache=%d\n",
           params->volume, params->force, params->use_cache);

    // TODO: 实现与TTS服务的Unix Socket通信
    // 1. 连接到socket_path
    // 2. 发送TTS请求 (JSON格式)
    // 3. 等待服务端返回PCM文件路径
    // 4. 调用ai_audio_play播放

    fprintf(stderr, "[V853-Audio] TTS service not implemented yet\n");
    return AI_AUDIO_ERROR_INIT;
}

// 简化TTS播放
int ai_audio_play_tts_simple(ai_audio_t *client, const char *text) {
    ai_audio_tts_params_t params = ai_audio_create_default_tts_params(text);
    return ai_audio_play_tts(client, &params);
}

// 清理客户端
void ai_audio_cleanup(ai_audio_t *client) {
    if (!client) {
        return;
    }

    ai_audio_stop(client);
    free(client);

    printf("[V853-Audio] Audio client cleaned up\n");
}

// 获取错误字符串
const char* ai_audio_get_error_string(int error_code) {
    switch (error_code) {
        case AI_AUDIO_SUCCESS:        return "Success";
        case AI_AUDIO_ERROR_INIT:     return "Initialization error";
        case AI_AUDIO_ERROR_CONNECT:  return "Connection error";
        case AI_AUDIO_ERROR_SEND:     return "Send error";
        case AI_AUDIO_ERROR_PARAM:    return "Invalid parameter";
        case AI_AUDIO_ERROR_RESPONSE: return "Server response error";
        default:                      return "Unknown error";
    }
}
