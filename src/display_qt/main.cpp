/**
 * @file main.cpp
 * @brief AI Glasses Display Application - Qt Entry Point
 *
 * This is the main entry point for the RV1109-based AI Glasses display
 * application using Qt5 framework and MIPI DSI display.
 *
 * Platform: RV1109 (Rockchip dual-core Cortex-A7)
 * Display: MIPI DSI 1280x720 @ 60Hz
 * UI Framework: Qt 5.15
 *
 * Copyright (c) 2026 AI Glasses Project
 */

#include <QApplication>
#include <QScreen>
#include <QDebug>
#include <signal.h>
#include "mainwindow.h"

// Signal handler for graceful shutdown
void signalHandler(int signal) {
    qInfo() << "Received signal" << signal << "- shutting down gracefully";
    QApplication::quit();
}

int main(int argc, char *argv[])
{
    // Install signal handlers
    signal(SIGINT, signalHandler);
    signal(SIGTERM, signalHandler);

    // Create Qt application
    QApplication app(argc, argv);

    // Set application metadata
    app.setApplicationName("AI Glasses Display");
    app.setApplicationVersion("1.0.0");
    app.setOrganizationName("AI Glasses Project");

    // Get screen information
    QScreen *screen = QApplication::primaryScreen();
    QRect screenGeometry = screen->geometry();

    qInfo() << "===========================================";
    qInfo() << "AI Glasses Display - Qt Application";
    qInfo() << "Platform: RV1109 (Cortex-A7 Dual-Core)";
    qInfo() << "Display: MIPI DSI";
    qInfo() << "Resolution:" << screenGeometry.width() << "x" << screenGeometry.height();
    qInfo() << "Qt version:" << qVersion();
    qInfo() << "===========================================";

    // Create and show main window
    MainWindow mainWindow;

    // Set window properties
    mainWindow.setWindowTitle("AI Glasses");

    // Fullscreen mode for embedded device
    if (argc > 1 && QString(argv[1]) == "--windowed") {
        mainWindow.resize(1280, 720);
        mainWindow.show();
    } else {
        mainWindow.showFullScreen();
    }

    qInfo() << "Application started successfully";

    // Run event loop
    int ret = app.exec();

    qInfo() << "Application exiting with code:" << ret;
    return ret;
}
