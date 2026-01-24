#ifndef ai_audio_H
#define ai_audio_H

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @file ai_audio.h
 * @brief AI Media Service 音频播放客户端API
 * @version 1.0
 * @date 2025-10-10
 */

// =============================================================================
// 音频参数结构
// =============================================================================

/**
 * @brief 音频播放参数
 */
typedef struct {
    const char *file_path;    // PCM文件路径（必填）
    int volume;               // 音量 (0-100)，-1表示使用默认值
    int force;                // 强制播放标志 (0=排队, 1=打断当前播放)
    int sample_rate;          // 采样率 (8000-96000)，-1表示使用默认值
    int channels;             // 声道数 (1-8)，-1表示使用默认值
    int bit_width;            // 位宽 (8/16/24/32)，-1表示使用默认值
} ai_audio_params_t;

/**
 * @brief 音频客户端句柄（不透明类型）
 */
typedef struct ai_audio ai_audio_t;

// =============================================================================
// 错误码定义
// =============================================================================

#define AI_AUDIO_SUCCESS           0    // 成功
#define AI_AUDIO_ERROR_INIT       -1    // 初始化失败
#define AI_AUDIO_ERROR_CONNECT    -2    // 连接失败
#define AI_AUDIO_ERROR_SEND       -3    // 发送失败
#define AI_AUDIO_ERROR_PARAM      -4    // 参数错误
#define AI_AUDIO_ERROR_RESPONSE   -5    // 服务端响应错误

// =============================================================================
// 核心API
// =============================================================================

/**
 * @brief 初始化音频客户端
 * @param socket_path Unix Socket路径，NULL表示使用默认路径
 * @return 客户端句柄，失败返回NULL
 */
ai_audio_t* ai_audio_init(const char *socket_path);

/**
 * @brief 播放音频文件
 * @param client 客户端句柄
 * @param params 播放参数
 * @return 0成功，负数表示错误码
 */
int ai_audio_play(ai_audio_t *client, const ai_audio_params_t *params);

/**
 * @brief 停止当前播放
 * @param client 客户端句柄
 * @return 0成功，负数表示错误码
 */
int ai_audio_stop(ai_audio_t *client);

/**
 * @brief 清理音频客户端
 * @param client 客户端句柄
 */
void ai_audio_cleanup(ai_audio_t *client);

/**
 * @brief 获取错误信息字符串
 * @param error_code 错误码
 * @return 错误信息字符串
 */
const char* ai_audio_get_error_string(int error_code);

// =============================================================================
// 辅助函数
// =============================================================================

/**
 * @brief 创建默认播放参数
 * @param file_path PCM文件路径
 * @return 参数结构体
 */
ai_audio_params_t ai_audio_create_default_params(const char *file_path);

/**
 * @brief 简化的播放函数（使用默认参数）
 * @param client 客户端句柄
 * @param file_path PCM文件路径
 * @return 0成功，负数表示错误码
 */
int ai_audio_play_simple(ai_audio_t *client, const char *file_path);

// =============================================================================
// TTS API (文本转语音播放)
// =============================================================================

/**
 * @brief TTS播放参数
 */
typedef struct {
    const char *text;         // 待播报的文本（必填）
    int volume;               // 音量 (0-100)，-1表示使用默认值
    int force;                // 强制播放标志 (0=排队, 1=打断当前播放)
    int use_cache;            // 是否使用缓存 (0=不缓存, 1=使用缓存)
} ai_audio_tts_params_t;

/**
 * @brief 播放TTS文本
 * @param client 客户端句柄
 * @param params TTS播放参数
 * @return 0成功，负数表示错误码
 *
 * 工作流程：
 * 1. 客户端通过Unix Socket发送TTS命令到服务端
 * 2. 服务端计算文本MD5并检查缓存
 * 3. 如果缓存未命中，调用云端TTS API生成音频
 * 4. 服务端将生成的PCM文件加入播放队列
 * 5. 播放完成后返回结果
 */
int ai_audio_play_tts(ai_audio_t *client, const ai_audio_tts_params_t *params);

/**
 * @brief 简化的TTS播放函数（使用默认参数）
 * @param client 客户端句柄
 * @param text 待播报的文本
 * @return 0成功，负数表示错误码
 *
 * 默认参数：音量=默认，排队播放，使用缓存
 */
int ai_audio_play_tts_simple(ai_audio_t *client, const char *text);

/**
 * @brief 创建默认TTS参数
 * @param text 待播报的文本
 * @return 参数结构体
 */
ai_audio_tts_params_t ai_audio_create_default_tts_params(const char *text);

#ifdef __cplusplus
}
#endif

#endif // ai_audio_H
