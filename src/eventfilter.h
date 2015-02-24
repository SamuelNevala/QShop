#ifndef EVENTFILTER_H
#define EVENTFILTER_H

#include <QtCore/QObject>

class EventFilter : public QObject
{
    Q_OBJECT

public:
    explicit EventFilter(QObject *parent = 0);

Q_SIGNALS:
    void backClicked();
    void add(QString text);
    void clear();
    void remove();

protected:
    bool eventFilter(QObject *obj, QEvent *event);

private:
    bool m_more;
};

#endif // EVENTFILTER_H
