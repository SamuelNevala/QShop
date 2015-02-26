#include <QtCore/QEvent>
#include <QtCore/QDebug>
#include <QtGui/QKeyEvent>
#include <QtGui/QGuiApplication>
#include "eventfilter.h"

EventFilter::EventFilter(QObject *parent)
    : QObject(parent)
    , m_more(true)
{
    qApp->installEventFilter(this);
}

bool EventFilter::eventFilter(QObject *obj, QEvent *event)
{
    Q_UNUSED(obj);
    //qDebug()<<event;

    if (event && event->type() == QEvent::InputMethod) {
        QInputMethodEvent *imEvent = static_cast<QInputMethodEvent *>(event);
        qDebug()<<imEvent<<imEvent->commitString();

        if (imEvent->commitString().contains("monta", Qt::CaseInsensitive)) {
            m_more = true;
        }

        if (imEvent->commitString().contains("lopeta", Qt::CaseInsensitive)) {
            m_more = false;
        }

        if (m_more && imEvent->commitString().startsWith(" ")) {
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
