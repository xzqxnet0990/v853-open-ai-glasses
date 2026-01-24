cmake_minimum_required(VERSION 3.10)
project(AIGlassesDisplay VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Cross-compilation toolchain
if(NOT CMAKE_CROSSCOMPILING)
    message(WARNING "Not cross-compiling. Set CMAKE_TOOLCHAIN_FILE for ARM target.")
endif()

# Qt5 packages
find_package(Qt5 REQUIRED COMPONENTS Core Gui Widgets)

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/include
    ${CMAKE_CURRENT_SOURCE_DIR}/../display
)

# Source files
set(SOURCES
    main.cpp
    mainwindow.cpp
    widgets/battery_widget.cpp
    widgets/camera_widget.cpp
    widgets/settings_widget.cpp
)

set(HEADERS
    mainwindow.h
    widgets/battery_widget.h
    widgets/camera_widget.h
    widgets/settings_widget.h
)

# Qt resources
set(RESOURCES
    resources/resources.qrc
)

# Link against SDK
set(SDK_PATH "${CMAKE_CURRENT_SOURCE_DIR}/../../SDK/ai_glass_sdk")
include_directories(${SDK_PATH}/include)
link_directories(${SDK_PATH}/lib)

# Create executable
add_executable(${PROJECT_NAME} ${SOURCES} ${HEADERS} ${RESOURCES})

# Link libraries
target_link_libraries(${PROJECT_NAME}
    Qt5::Core
    Qt5::Gui
    Qt5::Widgets
    ai_glass_sdk
    pthread
    rt
)

# Install target
install(TARGETS ${PROJECT_NAME} DESTINATION /usr/bin)

# Deployment info
message(STATUS "==========================================")
message(STATUS "AI Glasses Display Qt Application")
message(STATUS "Version: ${PROJECT_VERSION}")
message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Qt version: ${Qt5_VERSION}")
message(STATUS "==========================================")
