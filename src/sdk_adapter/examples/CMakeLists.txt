cmake_minimum_required(VERSION 3.10)

# 包含SDK头文件
include_directories(${CMAKE_SOURCE_DIR}/include)

# Camera测试示例
add_executable(camera_test camera_test.c)
target_link_libraries(camera_test ai_glass_sdk_v853)

# Audio测试示例
add_executable(audio_test audio_test.c)
target_link_libraries(audio_test ai_glass_sdk_v853)

# GPIO测试示例 (TODO)
# add_executable(gpio_test gpio_test.c)
# target_link_libraries(gpio_test ai_glass_sdk_v853)

# 安装示例程序
install(TARGETS camera_test audio_test
        RUNTIME DESTINATION bin/examples)
