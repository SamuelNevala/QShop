#include <QtCore/QEvent>
#include <QtCore/QDebug>
#include <QtGui/QKeyEvent>
#include <QtGui/QGuiApplication>
#include "voice.h"

Voice::Voice(QObject *parent) Q_DECL_NOTHROW
    : QObject(parent)
    , m_continuous(false)
{
    qApp->installEventFilter(this);
    m_add << "lisää" << "lisa" << "lisaa";
    m_clean << "tyhjennä" << "tyhjenna";
    m_end << "lopeta";
    m_remove << "poista";
    m_start << "monta" << "honda";

}

bool Voice::continuous() const
{
    return m_continuous;
}

bool Voice::eventFilter(QObject *obj, QEvent *event)
{
    Q_UNUSED(obj);

    if (event && event->type() == QEvent::InputMethod) {
        QInputMethodEvent *imEvent = static_cast<QInputMethodEvent *>(event);

        QString commitString = imEvent->commitString();
        commitString = commitString.trimmed();

        if (m_start.contains(commitString, Qt::CaseInsensitive)) {
            event->accept();
            m_continuous = true;
            Q_EMIT continuousChanged();
            return true;
        }

        if (m_end.contains(commitString, Qt::CaseInsensitive)) {
            event->accept();
            m_continuous = false;
            Q_EMIT continuousChanged();
            return true;
        }

        if (m_clean.contains(commitString, Qt::CaseInsensitive)) {
            event->accept();
            Q_EMIT clear();
            return true;
        }

        if (m_remove.contains(commitString, Qt::CaseInsensitive)) {
            event->accept();
            Q_EMIT remove();
            return true;
        }

        QString start = commitString.split(" ")[0];
        if (m_add.contains(start, Qt::CaseInsensitive)) {
            event->accept();
            commitString = commitString.remove(start);
            commitString = commitString.trimmed();
            if (!commitString.isEmpty()) {
                Q_EMIT add(commitString);
            }
            return true;
        }

        if (m_continuous && !commitString.isEmpty()) {
            event->accept();
            Q_EMIT add(commitString);
            return true;
        }
    }

    return QObject::eventFilter(obj, event);
}
