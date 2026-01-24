cmake_minimum_required(VERSION 3.10)
project(AIGlassesDisplayLVGL VERSION 1.0.0 LANGUAGES C)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Cross-compilation check
if(NOT CMAKE_CROSSCOMPILING)
    message(WARNING "Not cross-compiling. Set CMAKE_TOOLCHAIN_FILE for ARM target.")
endif()

# ============================================================================
# V853 SDK Path Detection
# ============================================================================
if(DEFINED ENV{V853_SDK_PATH})
    set(V853_SDK_PATH "$ENV{V853_SDK_PATH}" CACHE PATH "V853 SDK Path" FORCE)
    message(STATUS "使用环境变量 V853_SDK_PATH: ${V853_SDK_PATH}")
elseif(EXISTS "/opt/v853_sdk")
    set(V853_SDK_PATH "/opt/v853_sdk" CACHE PATH "V853 SDK Path")
    message(STATUS "使用Docker路径: ${V853_SDK_PATH}")
else()
    set(V853_SDK_PATH "${CMAKE_SOURCE_DIR}/../../SDK/tina-v853-open" CACHE PATH "V853 SDK Path")
    message(STATUS "使用相对路径: ${V853_SDK_PATH}")
endif()

# ============================================================================
# LVGL Configuration
# ============================================================================
set(LVGL_ROOT "${V853_SDK_PATH}/platform/thirdparty/gui/lvgl-8")
set(LVGL_DIR "${LVGL_ROOT}/lvgl")
set(LVGL_SRC_DIR "${LVGL_DIR}/src")
set(LVGL_DRIVERS_DIR "${LVGL_ROOT}/lv_drivers")

if(NOT EXISTS "${LVGL_SRC_DIR}")
    message(FATAL_ERROR "LVGL source not found: ${LVGL_SRC_DIR}")
endif()

if(NOT EXISTS "${LVGL_DIR}/lvgl.h")
    message(FATAL_ERROR "LVGL main header not found: ${LVGL_DIR}/lvgl.h")
endif()

message(STATUS "LVGL根目录: ${LVGL_DIR}")
message(STATUS "LVGL源码目录: ${LVGL_SRC_DIR}")
message(STATUS "LVGL驱动目录: ${LVGL_DRIVERS_DIR}")

# ============================================================================
# AI Glass SDK Configuration
# ============================================================================
# Use SDK adapter build output (V853 version)
set(SDK_ADAPTER_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../sdk_adapter/build")
set(SDK_INCLUDE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../SDK/ai_glass_sdk/include")

# Check if SDK adapter library exists
if(NOT EXISTS "${SDK_ADAPTER_PATH}/libai_glass_sdk_v853.a")
    message(WARNING "SDK adapter library not found at: ${SDK_ADAPTER_PATH}/libai_glass_sdk_v853.a")
    message(WARNING "Please build SDK adapter first: cd /workspace && ./build_all.sh sdk")
endif()

include_directories(${SDK_INCLUDE_PATH})
link_directories(${SDK_ADAPTER_PATH})

message(STATUS "SDK adapter path: ${SDK_ADAPTER_PATH}")
message(STATUS "SDK include path: ${SDK_INCLUDE_PATH}")

# ============================================================================
# Include Directories
# ============================================================================
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${LVGL_DIR}              # For #include "lvgl.h"
    ${LVGL_SRC_DIR}          # For LVGL internal includes
    ${LVGL_DRIVERS_DIR}
)

# ============================================================================
# Collect LVGL Source Files
# ============================================================================
file(GLOB_RECURSE LVGL_SOURCES
    "${LVGL_SRC_DIR}/core/*.c"
    "${LVGL_SRC_DIR}/draw/*.c"
    "${LVGL_SRC_DIR}/font/*.c"
    "${LVGL_SRC_DIR}/gpu/*.c"
    "${LVGL_SRC_DIR}/hal/*.c"
    "${LVGL_SRC_DIR}/misc/*.c"
    "${LVGL_SRC_DIR}/widgets/*.c"
    "${LVGL_SRC_DIR}/extra/*.c"
)

# ============================================================================
# Application Source Files
# ============================================================================
set(APP_SOURCES
    main.c
    drivers/lv_port_disp.c
    drivers/lv_port_indev.c
    ui/ui_init.c
    ui/ui_battery.c
    ui/ui_camera.c
    ui/ui_settings.c
)

# ============================================================================
# Create Executable
# ============================================================================
add_executable(${PROJECT_NAME}
    ${APP_SOURCES}
    ${LVGL_SOURCES}
)

# ============================================================================
# Compiler Options
# ============================================================================
target_compile_options(${PROJECT_NAME} PRIVATE
    -Wall
    -Wextra
    -Wno-unused-parameter
    -O2
    -DLV_CONF_INCLUDE_SIMPLE
)

# ============================================================================
# Link Libraries
# ============================================================================
target_link_libraries(${PROJECT_NAME}
    ai_glass_sdk_v853    # V853 SDK adapter library
    pthread
    rt
    m
)

# ============================================================================
# Install Target
# ============================================================================
install(TARGETS ${PROJECT_NAME} DESTINATION /usr/bin)

# ============================================================================
# Build Information
# ============================================================================
message(STATUS "==========================================")
message(STATUS "AI Glasses LVGL Display Application")
message(STATUS "Version: ${PROJECT_VERSION}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Target: ${CMAKE_SYSTEM_PROCESSOR}")
message(STATUS "LVGL path: ${LVGL_DIR}")
message(STATUS "SDK adapter: ${SDK_ADAPTER_PATH}")
message(STATUS "==========================================")
