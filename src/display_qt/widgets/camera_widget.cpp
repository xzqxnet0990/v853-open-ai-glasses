/**
 * @file camera_widget.cpp
 * @brief Camera preview widget implementation
 */

#include "camera_widget.h"
#include <QVBoxLayout>
#include <QPainter>
#include <QFont>
#include <QDebug>
#include <QDateTime>

// AI Glass SDK
extern "C" {
#include "ai_camera.h"
#include "ai_log.h"
}

CameraWidget::CameraWidget(QWidget *parent)
    : QWidget(parent)
    , m_titleLabel(nullptr)
    , m_previewLabel(nullptr)
    , m_infoLabel(nullptr)
    , m_settingsButton(nullptr)
    , m_isRunning(false)
    , m_frameCount(0)
    , m_lastUpdateTime(0)
{
    setupUI();
}

CameraWidget::~CameraWidget()
{
    if (m_isRunning) {
        stopPreview();
    }
}

void CameraWidget::setupUI()
{
    // Main layout
    QVBoxLayout *mainLayout = new QVBoxLayout(this);
    mainLayout->setContentsMargins(20, 20, 20, 20);
    mainLayout->setSpacing(20);

    // Title
    m_titleLabel = new QLabel("相机预览", this);
    QFont titleFont;
    titleFont.setPointSize(24);
    titleFont.setBold(true);
    m_titleLabel->setFont(titleFont);
    m_titleLabel->setAlignment(Qt::AlignCenter);
    mainLayout->addWidget(m_titleLabel);

    // Preview label (displays camera frames)
    m_previewLabel = new QLabel(this);
    m_previewLabel->setAlignment(Qt::AlignCenter);
    m_previewLabel->setMinimumSize(640, 480);
    m_previewLabel->setScaledContents(true);
    m_previewLabel->setStyleSheet("QLabel { background-color: black; border: 2px solid gray; }");
    mainLayout->addWidget(m_previewLabel, 1);

    // Info label (FPS, resolution, etc.)
    m_infoLabel = new QLabel("等待启动...", this);
    QFont infoFont;
    infoFont.setPointSize(14);
    m_infoLabel->setFont(infoFont);
    m_infoLabel->setAlignment(Qt::AlignCenter);
    mainLayout->addWidget(m_infoLabel);

    // Settings button
    m_settingsButton = new QPushButton("设置", this);
    QFont buttonFont;
    buttonFont.setPointSize(16);
    m_settingsButton->setFont(buttonFont);
    m_settingsButton->setMinimumHeight(60);
    connect(m_settingsButton, &QPushButton::clicked,
            this, &CameraWidget::requestSettingsScreen);
    mainLayout->addWidget(m_settingsButton);

    // Set background color
    setAutoFillBackground(true);
    QPalette pal = palette();
    pal.setColor(QPalette::Window, QColor(40, 40, 40));
    pal.setColor(QPalette::WindowText, QColor(255, 255, 255));
    setPalette(pal);
}

void CameraWidget::startPreview()
{
    if (m_isRunning) {
        qWarning() << "Camera already running";
        return;
    }

    qInfo() << "Starting camera preview";

    // Start camera capture via SDK
    int ret = ai_camera_start_capture(cameraCallback, this);
    if (ret != 0) {
        qCritical() << "Failed to start camera capture:" << ret;
        m_infoLabel->setText("相机启动失败");
        return;
    }

    m_isRunning = true;
    m_frameCount = 0;
    m_lastUpdateTime = QDateTime::currentMSecsSinceEpoch();
    m_infoLabel->setText("相机运行中...");

    qInfo() << "Camera preview started successfully";
}

void CameraWidget::stopPreview()
{
    if (!m_isRunning) {
        return;
    }

    qInfo() << "Stopping camera preview";

    // Stop camera capture
    ai_camera_stop_capture();

    m_isRunning = false;
    m_previewLabel->clear();
    m_infoLabel->setText("相机已停止");

    qInfo() << "Camera preview stopped";
}

void CameraWidget::updateFrame()
{
    if (!m_isRunning) {
        return;
    }

    // Lock and update frame
    QMutexLocker locker(&m_frameMutex);
    if (!m_currentFrame.isNull()) {
        m_previewLabel->setPixmap(QPixmap::fromImage(m_currentFrame));
    }

    // Calculate FPS
    m_frameCount++;
    qint64 now = QDateTime::currentMSecsSinceEpoch();
    qint64 elapsed = now - m_lastUpdateTime;
    if (elapsed >= 1000) {  // Update every second
        float fps = m_frameCount * 1000.0f / elapsed;
        m_infoLabel->setText(QString("FPS: %1 | 分辨率: %2x%3")
                            .arg(fps, 0, 'f', 1)
                            .arg(m_currentFrame.width())
                            .arg(m_currentFrame.height()));
        m_frameCount = 0;
        m_lastUpdateTime = now;
    }
}

void CameraWidget::cameraCallback(const void *data, int width, int height, int format, void *userdata)
{
    CameraWidget *widget = static_cast<CameraWidget*>(userdata);
    if (!widget) {
        return;
    }

    // Convert camera data to QImage
    // Assuming JPEG format from SDK
    QImage image;
    if (format == 0) {  // JPEG
        image.loadFromData(static_cast<const uchar*>(data), width);  // width is actually data size for JPEG
    } else {
        // Handle other formats (NV12, etc.)
        qWarning() << "Unsupported camera format:" << format;
        return;
    }

    // Store frame
    QMutexLocker locker(&widget->m_frameMutex);
    widget->m_currentFrame = image;
}

void CameraWidget::paintEvent(QPaintEvent *event)
{
    QWidget::paintEvent(event);
}
