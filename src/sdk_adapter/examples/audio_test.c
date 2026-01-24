/**
 * V853 Audio Test Example
 *
 * 测试音频播放功能
 */

#include "ai_audio.h"
#include "ai_log.h"
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    printf("=== V853 Audio Test ===\n\n");

    // 初始化日志系统
    ai_log_init(AI_LOG_DEBUG, NULL);

    // 初始化音频客户端
    printf("[1] 初始化音频客户端...\n");
    ai_audio_t *audio = ai_audio_init(NULL);
    if (!audio) {
        fprintf(stderr, "错误: 音频初始化失败!\n");
        return -1;
    }
    printf("    音频客户端初始化成功\n\n");

    // 测试1: 播放PCM文件 (如果有测试文件)
    if (argc > 1) {
        printf("[2] 播放PCM文件: %s\n", argv[1]);

        ai_audio_params_t params = ai_audio_create_default_params(argv[1]);
        params.volume = 80;
        params.sample_rate = 16000;
        params.channels = 1;
        params.bit_width = 16;

        int ret = ai_audio_play(audio, &params);
        if (ret == AI_AUDIO_SUCCESS) {
            printf("    播放成功\n");
        } else {
            printf("    播放失败: %s\n", ai_audio_get_error_string(ret));
        }
    } else {
        printf("[2] 未提供测试文件，跳过播放测试\n");
        printf("    用法: %s <pcm_file>\n", argv[0]);
    }

    printf("\n[3] 清理资源...\n");
    ai_audio_cleanup(audio);
    ai_log_cleanup();
    printf("    清理完成\n");

    printf("\n=== 测试完成 ===\n");
    return 0;
}
