#ifndef HWKEYWATCHER_H
#define HWKEYWATCHER_H

#include <QObject>

class HwKeyWatcher : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QObject* target READ target WRITE setTarget NOTIFY targetChanged)

public:
    explicit HwKeyWatcher(QObject *parent = 0);

    QObject* target() const;
    void setTarget(QObject* target);

Q_SIGNALS:
    void menuClicked();
    void backClicked();
    void targetChanged();

protected:
    bool eventFilter(QObject *obj, QEvent *event);

private:
    QObject* m_target;
};

#endif // HWKEYWATCHER_H
