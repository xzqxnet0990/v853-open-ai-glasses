cmake_minimum_required(VERSION 3.10)
project(ai_glass_sdk_v853)

# V853交叉编译工具链配置
# 优先使用环境变量 (Docker 容器内)，否则使用相对路径 (主机)
if(DEFINED ENV{V853_SDK_PATH})
    set(V853_SDK_PATH "$ENV{V853_SDK_PATH}" CACHE PATH "V853 SDK Path" FORCE)
    message(STATUS "使用环境变量 V853_SDK_PATH: ${V853_SDK_PATH}")
else()
    set(V853_SDK_PATH "${CMAKE_SOURCE_DIR}/../../SDK/tina-v853-open" CACHE PATH "V853 SDK Path")
    message(STATUS "使用相对路径 V853_SDK_PATH: ${V853_SDK_PATH}")
endif()

set(V853_TOOLCHAIN_PATH "${V853_SDK_PATH}/prebuilt/rootfsbuilt/arm/toolchain-sunxi-musl-gcc-830/toolchain/bin"
    CACHE PATH "V853 Toolchain Path")

# 设置编译选项
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -O2")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -Wall -O2")

# 包含目录
include_directories(
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/../../SDK/ai_glass_sdk/include
)

# SDK适配层源文件
set(SDK_ADAPTER_SOURCES
    src/ai_camera_v853.c
    src/ai_gpio_v853.c
    src/ai_gpio_v853_compat.c
    src/ai_audio_v853.c
    src/ai_log_v853.c
)

# 编译静态库
add_library(ai_glass_sdk_v853 STATIC ${SDK_ADAPTER_SOURCES})

# 编译动态库
add_library(ai_glass_sdk_v853_shared SHARED ${SDK_ADAPTER_SOURCES})
set_target_properties(ai_glass_sdk_v853_shared PROPERTIES OUTPUT_NAME ai_glass_sdk_v853)

# 链接pthread
target_link_libraries(ai_glass_sdk_v853 pthread)
target_link_libraries(ai_glass_sdk_v853_shared pthread)

# 安装规则
install(TARGETS ai_glass_sdk_v853 ai_glass_sdk_v853_shared
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib)

install(DIRECTORY include/ DESTINATION include/ai_glass_sdk
        FILES_MATCHING PATTERN "*.h")

# 示例程序 (暂时禁用)
# add_subdirectory(examples)
