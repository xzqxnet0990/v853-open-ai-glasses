/**
 * @file camera_widget.h
 * @brief Camera preview display widget
 *
 * Displays real-time camera feed from RV1109 ISP via AI Glass SDK.
 */

#ifndef CAMERA_WIDGET_H
#define CAMERA_WIDGET_H

#include <QWidget>
#include <QLabel>
#include <QPushButton>
#include <QImage>
#include <QMutex>

class CameraWidget : public QWidget
{
    Q_OBJECT

public:
    explicit CameraWidget(QWidget *parent = nullptr);
    ~CameraWidget();

    // Camera control
    void startPreview();
    void stopPreview();
    void updateFrame();

signals:
    void requestSettingsScreen();

protected:
    void paintEvent(QPaintEvent *event) override;

private:
    void setupUI();
    static void cameraCallback(const void *data, int width, int height, int format, void *userdata);

    // UI components
    QLabel *m_titleLabel;
    QLabel *m_previewLabel;
    QLabel *m_infoLabel;
    QPushButton *m_settingsButton;

    // Camera state
    bool m_isRunning;
    QImage m_currentFrame;
    QMutex m_frameMutex;

    // Statistics
    int m_frameCount;
    qint64 m_lastUpdateTime;
};

#endif // CAMERA_WIDGET_H
