#ifndef VOICECOMMANDS_H
#define VOICECOMMANDS_H

#include <QtCore/QObject>

class Voice : public QObject
{
    Q_OBJECT

public:
    explicit Voice(QObject *parent = 0);

Q_SIGNALS:
    void add(QString text);
    void clear();
    void remove();

protected:
    bool eventFilter(QObject *obj, QEvent *event);

private:
    bool m_continious;
};

#endif // VOICECOMMANDS_H
