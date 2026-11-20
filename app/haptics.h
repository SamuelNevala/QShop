#ifndef HAPTICS_H
#define HAPTICS_H

#include <QtCore/QObject>
#include <QtQmlIntegration/qqmlintegration.h>

class Haptics : public QObject
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

public:
    enum Feedback { Confirm, ToggleOn, ToggleOff, DragStart, GestureEnd, SegmentTick, Reject };
    Q_ENUM(Feedback)

    explicit Haptics(QObject *parent = nullptr) : QObject(parent) { }

    // Asynchronous on Android; no-op on desktop. The system controls the effect.
    Q_INVOKABLE void play(Feedback feedback);

Q_SIGNALS:
    // Observes requests, not whether the device actually vibrates.
    void requested(Feedback feedback);
};

#endif // HAPTICS_H
