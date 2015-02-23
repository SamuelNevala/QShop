#ifndef QMLELAPSEDTIMER_H
#define QMLELAPSEDTIMER_H

#include <QtCore/QObject>
#include <QtCore/QElapsedTimer>

class QmlElapsedTimer : public QObject
{
    Q_OBJECT
public:
    explicit QmlElapsedTimer(QObject *parent = 0);

    Q_INVOKABLE void start();
    Q_INVOKABLE qint64 elapsed() const;

private:
    QElapsedTimer m_timer;
};

#endif // QMLELAPSEDTIMER_H
