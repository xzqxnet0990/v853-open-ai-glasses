/**
 * @file settings_widget.h
 * @brief Settings and configuration widget
 *
 * Displays system settings, WiFi configuration, and device info.
 */

#ifndef SETTINGS_WIDGET_H
#define SETTINGS_WIDGET_H

#include <QWidget>
#include <QLabel>
#include <QPushButton>
#include <QSlider>

class SettingsWidget : public QWidget
{
    Q_OBJECT

public:
    explicit SettingsWidget(QWidget *parent = nullptr);
    ~SettingsWidget();

signals:
    void requestBatteryScreen();

protected:
    void paintEvent(QPaintEvent *event) override;

private:
    void setupUI();
    void loadSettings();
    void saveSettings();

    // UI components
    QLabel *m_titleLabel;
    QLabel *m_brightnessLabel;
    QSlider *m_brightnessSlider;
    QLabel *m_volumeLabel;
    QSlider *m_volumeSlider;
    QLabel *m_wifiLabel;
    QLabel *m_versionLabel;
    QPushButton *m_backButton;
};

#endif // SETTINGS_WIDGET_H
