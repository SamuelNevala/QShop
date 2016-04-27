#include "elapsedtimer.h"

ElapsedTimer::ElapsedTimer(QObject *parent) Q_DECL_NOTHROW
    : QObject(parent)
{
}

void ElapsedTimer::start()
{
    m_timer.start();
}

qint64 ElapsedTimer::elapsed() const
{
    return m_timer.elapsed();
}
