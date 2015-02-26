#ifndef BACKKEY_H
#define BACKKEY_H

#include <QtCore/QObject>

class BackKey : public QObject
{
    Q_OBJECT
public:
    explicit BackKey(QObject *parent = 0);
    ~BackKey();

Q_SIGNALS:
    void clicked();

protected:
    bool eventFilter(QObject *obj, QEvent *event);
};

#endif // BACKKEY_H
