/**
 * @file mainwindow.h
 * @brief Main window for AI Glasses display application
 *
 * Manages the main UI layout and coordinates between different
 * widget components (battery, camera, settings).
 */

#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QStackedWidget>
#include <QTimer>
#include "widgets/battery_widget.h"
#include "widgets/camera_widget.h"
#include "widgets/settings_widget.h"

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

    // Screen navigation
    enum Screen {
        SCREEN_BATTERY = 0,
        SCREEN_CAMERA = 1,
        SCREEN_SETTINGS = 2
    };

public slots:
    void switchToScreen(Screen screen);
    void switchToBatteryScreen();
    void switchToCameraScreen();
    void switchToSettingsScreen();

protected:
    void keyPressEvent(QKeyEvent *event) override;
    void closeEvent(QCloseEvent *event) override;

private:
    void setupUI();
    void setupConnections();
    void initializeSDK();
    void cleanupSDK();

    // UI components
    QStackedWidget *m_stackedWidget;
    BatteryWidget *m_batteryWidget;
    CameraWidget *m_cameraWidget;
    SettingsWidget *m_settingsWidget;

    // State management
    Screen m_currentScreen;
    QTimer *m_updateTimer;
};

#endif // MAINWINDOW_H
