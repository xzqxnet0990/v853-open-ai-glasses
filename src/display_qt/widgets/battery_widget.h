/**
 * @file battery_widget.h
 * @brief Battery status display widget
 *
 * Displays battery level, charging status, and power source
 * (12V external or 3.7V battery).
 */

#ifndef BATTERY_WIDGET_H
#define BATTERY_WIDGET_H

#include <QWidget>
#include <QLabel>
#include <QProgressBar>
#include <QPushButton>

class BatteryWidget : public QWidget
{
    Q_OBJECT

public:
    explicit BatteryWidget(QWidget *parent = nullptr);
    ~BatteryWidget();

    // Update battery status
    void updateStatus();

signals:
    void requestCameraScreen();

protected:
    void paintEvent(QPaintEvent *event) override;

private:
    void setupUI();
    void updateBatteryInfo();
    void updatePowerSource();

    // UI components
    QLabel *m_titleLabel;
    QLabel *m_batteryLevelLabel;
    QLabel *m_voltageLabel;
    QLabel *m_powerSourceLabel;
    QProgressBar *m_batteryBar;
    QPushButton *m_cameraButton;

    // Battery state
    int m_batteryLevel;       // 0-100%
    float m_voltage;          // V
    bool m_isCharging;
    bool m_externalPower;     // true if 12V external, false if battery
};

#endif // BATTERY_WIDGET_H
