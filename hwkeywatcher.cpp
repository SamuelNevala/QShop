#include <QtCore/QEvent>
#include <QtCore/QDebug>
#include <QtGui/QKeyEvent>
#include "hwkeywatcher.h"

HwKeyWatcher::HwKeyWatcher(QObject *parent)
    : QObject(parent)
    , m_target(NULL)
{
}

QObject* HwKeyWatcher::target() const
{
    return m_target;
}

void HwKeyWatcher::setTarget(QObject* target)
{
    if (target == m_target)
        return;

   /* foreach (QObject *item, target->children()) {
        if (item->metaObject()->className() == QString("QQuickTextInput")) {
            item->installEventFilter(this);
            break;
        }
    }*/

    if (m_target != NULL) {
        m_target->removeEventFilter(this);
        m_target = NULL;
    }

    m_target = target;
    m_target->installEventFilter(this);
    Q_EMIT targetChanged();
}

bool HwKeyWatcher::eventFilter(QObject *obj, QEvent *event)
{
    Q_UNUSED(obj);
    //qDebug()<<event;
    if (event && event->type() == QEvent::KeyRelease) {
        QKeyEvent *keyEvent = static_cast<QKeyEvent *>(event);
        if (keyEvent->key() == Qt::Key_Back) {
            Q_EMIT backClicked();
            return true;
        }
    }
   /* if (event && event->type() == QEvent::InputMethod) {
        QInputMethodEvent *imEvent = static_cast<QInputMethodEvent *>(event);
        qDebug()<<imEvent<<imEvent->commitString();

    }*/

    return QObject::eventFilter(obj, event);
}
