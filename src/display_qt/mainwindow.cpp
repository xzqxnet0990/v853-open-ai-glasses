/**
 * @file mainwindow.cpp
 * @brief Main window implementation
 */

#include "mainwindow.h"
#include <QKeyEvent>
#include <QCloseEvent>
#include <QDebug>
#include <QVBoxLayout>

// AI Glass SDK
extern "C" {
#include "ai_gpio.h"
#include "ai_camera.h"
#include "ai_audio.h"
#include "ai_log.h"
}

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , m_stackedWidget(nullptr)
    , m_batteryWidget(nullptr)
    , m_cameraWidget(nullptr)
    , m_settingsWidget(nullptr)
    , m_currentScreen(SCREEN_BATTERY)
    , m_updateTimer(nullptr)
{
    qInfo() << "Initializing MainWindow";

    // Initialize SDK
    initializeSDK();

    // Setup UI
    setupUI();

    // Setup signal/slot connections
    setupConnections();

    // Start with battery screen
    switchToScreen(SCREEN_BATTERY);

    qInfo() << "MainWindow initialized successfully";
}

MainWindow::~MainWindow()
{
    qInfo() << "Destroying MainWindow";

    // Cleanup SDK
    cleanupSDK();

    // Qt will automatically delete child widgets
}

void MainWindow::setupUI()
{
    // Create central stacked widget
    m_stackedWidget = new QStackedWidget(this);
    setCentralWidget(m_stackedWidget);

    // Create screen widgets
    m_batteryWidget = new BatteryWidget(this);
    m_cameraWidget = new CameraWidget(this);
    m_settingsWidget = new SettingsWidget(this);

    // Add to stack
    m_stackedWidget->addWidget(m_batteryWidget);   // Index 0
    m_stackedWidget->addWidget(m_cameraWidget);    // Index 1
    m_stackedWidget->addWidget(m_settingsWidget);  // Index 2

    // Setup update timer (50Hz refresh)
    m_updateTimer = new QTimer(this);
    m_updateTimer->setInterval(20);  // 20ms = 50Hz
    connect(m_updateTimer, &QTimer::timeout, [this]() {
        // Update current screen
        switch (m_currentScreen) {
            case SCREEN_BATTERY:
                m_batteryWidget->updateStatus();
                break;
            case SCREEN_CAMERA:
                m_cameraWidget->updateFrame();
                break;
            case SCREEN_SETTINGS:
                // Settings screen is static
                break;
        }
    });
    m_updateTimer->start();
}

void MainWindow::setupConnections()
{
    // Connect battery widget signals
    connect(m_batteryWidget, &BatteryWidget::requestCameraScreen,
            this, &MainWindow::switchToCameraScreen);

    // Connect camera widget signals
    connect(m_cameraWidget, &CameraWidget::requestSettingsScreen,
            this, &MainWindow::switchToSettingsScreen);

    // Connect settings widget signals
    connect(m_settingsWidget, &SettingsWidget::requestBatteryScreen,
            this, &MainWindow::switchToBatteryScreen);
}

void MainWindow::initializeSDK()
{
    qInfo() << "Initializing AI Glass SDK";

    // Initialize GPIO (button events)
    int ret = ai_gpio_init();
    if (ret != 0) {
        qWarning() << "Failed to initialize GPIO:" << ret;
    }

    // Initialize camera
    ret = ai_camera_init();
    if (ret != 0) {
        qWarning() << "Failed to initialize camera:" << ret;
    }

    // Initialize audio
    ret = ai_audio_init();
    if (ret != 0) {
        qWarning() << "Failed to initialize audio:" << ret;
    }

    qInfo() << "SDK initialization complete";
}

void MainWindow::cleanupSDK()
{
    qInfo() << "Cleaning up AI Glass SDK";

    // Cleanup in reverse order
    ai_audio_deinit();
    ai_camera_deinit();
    ai_gpio_deinit();

    qInfo() << "SDK cleanup complete";
}

void MainWindow::switchToScreen(Screen screen)
{
    qInfo() << "Switching to screen:" << screen;

    // Stop current screen
    switch (m_currentScreen) {
        case SCREEN_CAMERA:
            m_cameraWidget->stopPreview();
            break;
        default:
            break;
    }

    // Switch screen
    m_currentScreen = screen;
    m_stackedWidget->setCurrentIndex(static_cast<int>(screen));

    // Start new screen
    switch (m_currentScreen) {
        case SCREEN_CAMERA:
            m_cameraWidget->startPreview();
            break;
        default:
            break;
    }
}

void MainWindow::switchToBatteryScreen()
{
    switchToScreen(SCREEN_BATTERY);
}

void MainWindow::switchToCameraScreen()
{
    switchToScreen(SCREEN_CAMERA);
}

void MainWindow::switchToSettingsScreen()
{
    switchToScreen(SCREEN_SETTINGS);
}

void MainWindow::keyPressEvent(QKeyEvent *event)
{
    // Handle keyboard input for testing
    switch (event->key()) {
        case Qt::Key_1:
            switchToBatteryScreen();
            break;
        case Qt::Key_2:
            switchToCameraScreen();
            break;
        case Qt::Key_3:
            switchToSettingsScreen();
            break;
        case Qt::Key_Q:
        case Qt::Key_Escape:
            close();
            break;
        default:
            QMainWindow::keyPressEvent(event);
    }
}

void MainWindow::closeEvent(QCloseEvent *event)
{
    qInfo() << "Close event received";
    event->accept();
}
