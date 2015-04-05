#include <QtCore/QEvent>
#include <QtCore/QDebug>
#include <QtGui/QKeyEvent>
#include <QtGui/QGuiApplication>
#include "voice.h"

Voice::Voice(QObject *parent)
    : QObject(parent)
    , m_continuous(false)
    , m_add("lisää lisa lisaa")
    , m_clean("tyhjennä tyhjenna")
    , m_end("lopeta")
    , m_remove("poista")
    , m_start("monta honda")
{
    qApp->installEventFilter(this);
}

bool Voice::continuous() const
{
    return m_continuous;
}

bool Voice::eventFilter(QObject *obj, QEvent *event)
{
    //Q_UNUSED(obj);

    if (event && event->type() == QEvent::InputMethod) {
        QInputMethodEvent *imEvent = static_cast<QInputMethodEvent *>(event);

        qDebug()<<"---- "<<imEvent<<" -----";
        QString commitString = imEvent->commitString();
        commitString = commitString.trimmed();
        m_history.append(commitString);

        if (m_history.length() > 3) {
            m_history.pop_front();
        }

        // Do not block pre-editing.
        if (!imEvent->preeditString().isEmpty()
            || imEvent->preeditString().isEmpty() && imEvent->commitString().isEmpty()) {
            return false;
        }

        // Attemp to remove duplicate entries
        if ((m_history.length() == 3
            && m_history[0] == m_history[2]
            && m_history[1] == "")
            || commitString.isEmpty()) {
            return true;
        }

        if (m_start.contains(commitString, Qt::CaseInsensitive)) {
            m_continuous = true;
            Q_EMIT continuousChanged();
            return true;
        }

        if (m_end.contains(commitString, Qt::CaseInsensitive)) {
            m_continuous = false;
            Q_EMIT continuousChanged();
            return true;
        }

        if (m_clean.contains(commitString, Qt::CaseInsensitive)) {
            Q_EMIT clear();
            return true;
        }

        if (m_remove.contains(commitString, Qt::CaseInsensitive)) {
            Q_EMIT remove();
            return true;
        }

        QString start = commitString.split(" ")[0];
        if (m_add.contains(start, Qt::CaseInsensitive)) {
            commitString = commitString.remove(start);
            commitString = commitString.trimmed();
            qDebug()<<"add "<<commitString;
            if (!commitString.isEmpty()) {
                qDebug()<<"emit "<<commitString;
                Q_EMIT add(commitString);
            }
            return true;
        }

        if (m_continuous && !commitString.isEmpty()) {
            qDebug()<<"cemit "<<commitString;
            Q_EMIT add(commitString);
            return true;
        }
    }

    return QObject::eventFilter(obj, event);
}
