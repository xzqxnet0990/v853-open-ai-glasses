/**
 * @file battery_widget.cpp
 * @brief Battery status widget implementation
 */

#include "battery_widget.h"
#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QPainter>
#include <QFont>
#include <QDebug>
#include <QFile>

BatteryWidget::BatteryWidget(QWidget *parent)
    : QWidget(parent)
    , m_titleLabel(nullptr)
    , m_batteryLevelLabel(nullptr)
    , m_voltageLabel(nullptr)
    , m_powerSourceLabel(nullptr)
    , m_batteryBar(nullptr)
    , m_cameraButton(nullptr)
    , m_batteryLevel(0)
    , m_voltage(0.0f)
    , m_isCharging(false)
    , m_externalPower(false)
{
    setupUI();
    updateStatus();
}

BatteryWidget::~BatteryWidget()
{
}

void BatteryWidget::setupUI()
{
    // Main layout
    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(40, 40, 40, 40);
    mainLayout->setSpacing(30);

    // Title
    m_titleLabel = new QLabel("电池状态", this);
    QFont titleFont;
    titleFont.setPointSize(24);
    titleFont.setBold(true);
    m_titleLabel->setFont(titleFont);
    m_titleLabel->setAlignment(Qt::AlignCenter);
    mainLayout->addWidget(m_titleLabel);

    mainLayout->addStretch();

    // Battery level
    m_batteryLevelLabel = new QLabel("电量: ---%", this);
    QFont infoFont;
    infoFont.setPointSize(18);
    m_batteryLevelLabel->setFont(infoFont);
    m_batteryLevelLabel->setAlignment(Qt::AlignCenter);
    mainLayout->addWidget(m_batteryLevelLabel);

    // Battery progress bar
    m_batteryBar = new QProgressBar(this);
    m_batteryBar->setMinimum(0);
    m_batteryBar->setMaximum(100);
    m_batteryBar->setValue(0);
    m_batteryBar->setTextVisible(false);
    m_batteryBar->setMinimumHeight(40);
    mainLayout->addWidget(m_batteryBar);

    // Voltage
    m_voltageLabel = new QLabel("电压: -.--V", this);
    m_voltageLabel->setFont(infoFont);
    m_voltageLabel->setAlignment(Qt::AlignCenter);
    mainLayout->addWidget(m_voltageLabel);

    // Power source
    m_powerSourceLabel = new QLabel("电源: 未知", this);
    m_powerSourceLabel->setFont(infoFont);
    m_powerSourceLabel->setAlignment(Qt::AlignCenter);
    mainLayout->addWidget(m_powerSourceLabel);

    mainLayout->addStretch();

    // Camera button
    m_cameraButton = new QPushButton("启动相机", this);
    QFont buttonFont;
    buttonFont.setPointSize(16);
    m_cameraButton->setFont(buttonFont);
    m_cameraButton->setMinimumHeight(60);
    connect(m_cameraButton, &QPushButton::clicked,
            this, &BatteryWidget::requestCameraScreen);
    mainLayout->addWidget(m_cameraButton);

    // Set background color
    setAutoFillBackground(true);
    QPalette pal = palette();
    pal.setColor(QPalette::Window, QColor(40, 40, 40));
    pal.setColor(QPalette::WindowText, QColor(255, 255, 255));
    setPalette(pal);
}

void BatteryWidget::updateStatus()
{
    updateBatteryInfo();
    updatePowerSource();
}

void BatteryWidget::updateBatteryInfo()
{
    // Read battery capacity from sysfs
    QFile capacityFile("/sys/class/power_supply/rk817-battery/capacity");
    if (capacityFile.open(QIODevice::ReadOnly)) {
        QString capacityStr = capacityFile.readAll().trimmed();
        m_batteryLevel = capacityStr.toInt();
        capacityFile.close();
    }

    // Read battery voltage
    QFile voltageFile("/sys/class/power_supply/rk817-battery/voltage_now");
    if (voltageFile.open(QIODevice::ReadOnly)) {
        QString voltageStr = voltageFile.readAll().trimmed();
        m_voltage = voltageStr.toFloat() / 1000000.0f;  // Convert µV to V
        voltageFile.close();
    }

    // Read charging status
    QFile statusFile("/sys/class/power_supply/rk817-battery/status");
    if (statusFile.open(QIODevice::ReadOnly)) {
        QString statusStr = statusFile.readAll().trimmed();
        m_isCharging = (statusStr == "Charging");
        statusFile.close();
    }

    // Update UI
    QString levelText = QString("电量: %1%").arg(m_batteryLevel);
    if (m_isCharging) {
        levelText += " (充电中)";
    }
    m_batteryLevelLabel->setText(levelText);
    m_batteryBar->setValue(m_batteryLevel);

    // Set progress bar color based on level
    QString barStyle;
    if (m_batteryLevel > 60) {
        barStyle = "QProgressBar::chunk { background-color: #4CAF50; }";  // Green
    } else if (m_batteryLevel > 20) {
        barStyle = "QProgressBar::chunk { background-color: #FFC107; }";  // Yellow
    } else {
        barStyle = "QProgressBar::chunk { background-color: #F44336; }";  // Red
    }
    m_batteryBar->setStyleSheet(barStyle);

    m_voltageLabel->setText(QString("电压: %1V").arg(m_voltage, 0, 'f', 2));
}

void BatteryWidget::updatePowerSource()
{
    // Read power source from aiglasses-power supply
    QFile onlineFile("/sys/class/power_supply/aiglasses-power/online");
    if (onlineFile.open(QIODevice::ReadOnly)) {
        QString onlineStr = onlineFile.readAll().trimmed();
        m_externalPower = (onlineStr == "1");
        onlineFile.close();
    }

    // Update UI
    QString sourceText;
    if (m_externalPower) {
        sourceText = "电源: 外部 12V";
        m_powerSourceLabel->setStyleSheet("color: #4CAF50;");  // Green
    } else {
        sourceText = "电源: 电池 3.7V";
        m_powerSourceLabel->setStyleSheet("color: #FFC107;");  // Yellow
    }
    m_powerSourceLabel->setText(sourceText);
}

void BatteryWidget::paintEvent(QPaintEvent *event)
{
    QWidget::paintEvent(event);
}
