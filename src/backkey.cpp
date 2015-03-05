#include "backkey.h"
#include <QtGui/QKeyEvent>
#include <QtGui/QGuiApplication>

BackKey::BackKey(QObject *parent)
    : QObject(parent)
{
    qApp->installEventFilter(this);
}

BackKey::~BackKey()
{

}

bool BackKey::eventFilter(QObject *obj, QEvent *event)
{
    Q_UNUSED(obj);
    if (event && event->type() == QEvent::KeyRelease) {
        QKeyEvent *keyEvent = static_cast<QKeyEvent *>(event);
        if (keyEvent->key() == Qt::Key_Back) {
            Q_EMIT clicked();
            return true;
        }
    }
    return QObject::eventFilter(obj, event);
}
