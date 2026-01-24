/**
 * @file settings_widget.cpp
 * @brief Settings widget implementation
 */

#include "settings_widget.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QFont>
#include <QDebug>
#include <QSettings>
#include <QFile>

SettingsWidget::SettingsWidget(QWidget *parent)
    : QWidget(parent)
    , m_titleLabel(nullptr)
    , m_brightnessLabel(nullptr)
    , m_brightnessSlider(nullptr)
    , m_volumeLabel(nullptr)
    , m_volumeSlider(nullptr)
    , m_wifiLabel(nullptr)
    , m_versionLabel(nullptr)
    , m_backButton(nullptr)
{
    setupUI();
    loadSettings();
}

SettingsWidget::~SettingsWidget()
{
    saveSettings();
}

void SettingsWidget::setupUI()
{
    // Main layout
    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(40, 40, 40, 40);
    mainLayout->setSpacing(30);

    // Title
    m_titleLabel = new QLabel("系统设置", this);
    QFont titleFont;
    titleFont.setPointSize(24);
    titleFont.setBold(true);
    m_titleLabel->setFont(titleFont);
    m_titleLabel->setAlignment(Qt::AlignCenter);
    mainLayout->addWidget(m_titleLabel);

    mainLayout->addSpacing(20);

    // Brightness control
    QHBoxLayout *brightnessLayout = new QHBoxLayout();
    m_brightnessLabel = new QLabel("屏幕亮度: 50%", this);
    QFont labelFont;
    labelFont.setPointSize(16);
    m_brightnessLabel->setFont(labelFont);
    brightnessLayout->addWidget(m_brightnessLabel);
    mainLayout->addLayout(brightnessLayout);

    m_brightnessSlider = new QSlider(Qt::Horizontal, this);
    m_brightnessSlider->setMinimum(10);
    m_brightnessSlider->setMaximum(100);
    m_brightnessSlider->setValue(50);
    m_brightnessSlider->setMinimumHeight(40);
    connect(m_brightnessSlider, &QSlider::valueChanged, [this](int value) {
        m_brightnessLabel->setText(QString("屏幕亮度: %1%").arg(value));
        // TODO: Apply brightness to backlight PWM
    });
    mainLayout->addWidget(m_brightnessSlider);

    mainLayout->addSpacing(20);

    // Volume control
    QHBoxLayout *volumeLayout = new QHBoxLayout();
    m_volumeLabel = new QLabel("音量: 50%", this);
    m_volumeLabel->setFont(labelFont);
    volumeLayout->addWidget(m_volumeLabel);
    mainLayout->addLayout(volumeLayout);

    m_volumeSlider = new QSlider(Qt::Horizontal, this);
    m_volumeSlider->setMinimum(0);
    m_volumeSlider->setMaximum(100);
    m_volumeSlider->setValue(50);
    m_volumeSlider->setMinimumHeight(40);
    connect(m_volumeSlider, &QSlider::valueChanged, [this](int value) {
        m_volumeLabel->setText(QString("音量: %1%").arg(value));
        // TODO: Apply volume via AI Glass SDK
    });
    mainLayout->addWidget(m_volumeSlider);

    mainLayout->addSpacing(30);

    // WiFi status
    m_wifiLabel = new QLabel("WiFi: 未连接", this);
    m_wifiLabel->setFont(labelFont);
    m_wifiLabel->setAlignment(Qt::AlignCenter);
    mainLayout->addWidget(m_wifiLabel);
    updateWiFiStatus();

    mainLayout->addSpacing(20);

    // Version info
    m_versionLabel = new QLabel("版本: RV1109 v1.0.0", this);
    QFont versionFont;
    versionFont.setPointSize(14);
    m_versionLabel->setFont(versionFont);
    m_versionLabel->setAlignment(Qt::AlignCenter);
    m_versionLabel->setStyleSheet("color: #999;");
    mainLayout->addWidget(m_versionLabel);

    mainLayout->addStretch();

    // Back button
    m_backButton = new QPushButton("返回", this);
    QFont buttonFont;
    buttonFont.setPointSize(16);
    m_backButton->setFont(buttonFont);
    m_backButton->setMinimumHeight(60);
    connect(m_backButton, &QPushButton::clicked,
            this, &SettingsWidget::requestBatteryScreen);
    mainLayout->addWidget(m_backButton);

    // Set background color
    setAutoFillBackground(true);
    QPalette pal = palette();
    pal.setColor(QPalette::Window, QColor(40, 40, 40));
    pal.setColor(QPalette::WindowText, QColor(255, 255, 255));
    setPalette(pal);
}

void SettingsWidget::loadSettings()
{
    QSettings settings("/etc/aiglasses/settings.conf", QSettings::IniFormat);

    // Load brightness
    int brightness = settings.value("display/brightness", 50).toInt();
    m_brightnessSlider->setValue(brightness);

    // Load volume
    int volume = settings.value("audio/volume", 50).toInt();
    m_volumeSlider->setValue(volume);

    qInfo() << "Settings loaded: brightness=" << brightness << "volume=" << volume;
}

void SettingsWidget::saveSettings()
{
    QSettings settings("/etc/aiglasses/settings.conf", QSettings::IniFormat);

    // Save brightness
    settings.setValue("display/brightness", m_brightnessSlider->value());

    // Save volume
    settings.setValue("audio/volume", m_volumeSlider->value());

    settings.sync();

    qInfo() << "Settings saved";
}

void SettingsWidget::updateWiFiStatus()
{
    // Read WiFi connection status
    QFile wifiFile("/proc/net/wireless");
    if (wifiFile.open(QIODevice::ReadOnly)) {
        QString content = wifiFile.readAll();
        wifiFile.close();

        // Parse wireless interfaces
        QStringList lines = content.split('\n');
        bool connected = false;
        for (const QString &line : lines) {
            if (line.contains("wlan0")) {
                connected = true;
                break;
            }
        }

        if (connected) {
            m_wifiLabel->setText("WiFi: 已连接");
            m_wifiLabel->setStyleSheet("color: #4CAF50;");  // Green
        } else {
            m_wifiLabel->setText("WiFi: 未连接");
            m_wifiLabel->setStyleSheet("color: #999;");  // Gray
        }
    }
}

void SettingsWidget::paintEvent(QPaintEvent *event)
{
    QWidget::paintEvent(event);
}
