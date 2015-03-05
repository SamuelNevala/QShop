#include <QtCore/QEvent>
#include <QtCore/QDebug>
#include <QtGui/QKeyEvent>
#include <QtGui/QGuiApplication>
#include "voice.h"

Voice::Voice(QObject *parent)
    : QObject(parent)
    , m_continious(false)
{
    qApp->installEventFilter(this);
}

bool Voice::eventFilter(QObject *obj, QEvent *event)
{
    Q_UNUSED(obj);

    if (event && event->type() == QEvent::InputMethod) {
        QInputMethodEvent *imEvent = static_cast<QInputMethodEvent *>(event);
        qDebug()<<imEvent<<imEvent->commitString();

        if (imEvent->commitString().contains("monta", Qt::CaseInsensitive)) {
            m_continious = true;
        }

        if (imEvent->commitString().contains("lopeta", Qt::CaseInsensitive)) {
            m_continious = false;
        }

        if (m_continious && imEvent->commitString().startsWith(" ")) {
            QString copyStr = imEvent->commitString();
            if (copyStr.startsWith(" ")) {
                copyStr = copyStr.remove(0, 1);
            }
            if (!copyStr.isEmpty()) {
                Q_EMIT add(copyStr);
            }
            return true;
        }

        if (imEvent->commitString().contains("lisää", Qt::CaseInsensitive)) {
            QString copyStr = imEvent->commitString();
            copyStr = copyStr.remove("lisää");
            if (copyStr.startsWith(" ")) {
                copyStr = copyStr.remove(0, 1);
            }
            if (!copyStr.isEmpty()) {
                Q_EMIT add(copyStr);
            }
            return true;
        }


        if (imEvent->commitString().contains("tyhjennä", Qt::CaseInsensitive)) {
            Q_EMIT clear();
            return true;
        }

        if (imEvent->commitString().contains("poista", Qt::CaseInsensitive)) {
            Q_EMIT remove();
            return true;
        }

    }

    return QObject::eventFilter(obj, event);
}
