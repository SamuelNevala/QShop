#include "qmlelapsedtimer.h"

QmlElapsedTimer::QmlElapsedTimer(QObject *parent)
    : QObject(parent)
{
}

void QmlElapsedTimer::start()
{
    m_timer.start();
}

qint64 QmlElapsedTimer::elapsed() const
{
    return m_timer.elapsed();
}
