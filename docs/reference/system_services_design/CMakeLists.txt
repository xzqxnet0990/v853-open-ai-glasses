# System Services CMakeLists.txt - V853 Platform

cmake_minimum_required(VERSION 3.10)
project(v853_system_services)

# 设置C标准
set(CMAKE_C_STANDARD 11)

# 工具链配置
if(NOT CMAKE_TOOLCHAIN_FILE)
    set(CMAKE_TOOLCHAIN_FILE "${CMAKE_SOURCE_DIR}/toolchain-v853.cmake")
endif()

# 编译选项
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -Wall -Wextra")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG} -g -O0")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE} -O2")

# SDK路径
set(SDK_INCLUDE_DIR "${CMAKE_SOURCE_DIR}/../../SDK/ai_glass_sdk/include")
set(SDK_LIB_DIR "${CMAKE_SOURCE_DIR}/../../SDK/ai_glass_sdk/lib")

# 包含SDK头文件
include_directories(${SDK_INCLUDE_DIR})

# 链接SDK库
link_directories(${SDK_LIB_DIR})

# 输出目录
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# 添加子目录（根据实现进度启用）
# add_subdirectory(ai-core)
# add_subdirectory(display_manager)
# add_subdirectory(power_manager)
# add_subdirectory(wifi_manager)
# add_subdirectory(log_daemon)

# 打印配置信息
message(STATUS "=================================")
message(STATUS "V853 System Services Build")
message(STATUS "=================================")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "C Compiler: ${CMAKE_C_COMPILER}")
message(STATUS "SDK Include: ${SDK_INCLUDE_DIR}")
message(STATUS "SDK Library: ${SDK_LIB_DIR}")
message(STATUS "Output Directory: ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
message(STATUS "=================================")

# 安装规则
install(DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/
        DESTINATION /usr/bin
        FILES_MATCHING PATTERN "*"
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                    GROUP_READ GROUP_EXECUTE
                    WORLD_READ WORLD_EXECUTE)

# 安装启动脚本
install(FILES init/S99aiglasses
        DESTINATION /etc/init.d
        PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                    GROUP_READ GROUP_EXECUTE
                    WORLD_READ WORLD_EXECUTE)

# 帮助信息
add_custom_target(help
    COMMAND ${CMAKE_COMMAND} -E echo ""
    COMMAND ${CMAKE_COMMAND} -E echo "V853 System Services Build System"
    COMMAND ${CMAKE_COMMAND} -E echo "================================"
    COMMAND ${CMAKE_COMMAND} -E echo ""
    COMMAND ${CMAKE_COMMAND} -E echo "Available targets:"
    COMMAND ${CMAKE_COMMAND} -E echo "  make              - Build all services"
    COMMAND ${CMAKE_COMMAND} -E echo "  make install      - Install to system"
    COMMAND ${CMAKE_COMMAND} -E echo "  make clean        - Clean build files"
    COMMAND ${CMAKE_COMMAND} -E echo "  make help         - Show this help"
    COMMAND ${CMAKE_COMMAND} -E echo ""
    COMMAND ${CMAKE_COMMAND} -E echo "Services to implement:"
    COMMAND ${CMAKE_COMMAND} -E echo "  - ai-core         (Core hardware service)"
    COMMAND ${CMAKE_COMMAND} -E echo "  - display_manager (Display management)"
    COMMAND ${CMAKE_COMMAND} -E echo "  - power_manager   (Power monitoring)"
    COMMAND ${CMAKE_COMMAND} -E echo "  - wifi_manager    (WiFi management)"
    COMMAND ${CMAKE_COMMAND} -E echo "  - log_daemon      (Log collection)"
    COMMAND ${CMAKE_COMMAND} -E echo ""
)
