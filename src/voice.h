#ifndef VOICECOMMANDS_H
#define VOICECOMMANDS_H

#include <QtCore/QObject>
#include <QtCore/QStringList>

class Voice : public QObject
{
    Q_OBJECT
     Q_PROPERTY(bool continuous READ continuous NOTIFY continuousChanged)

public:
    explicit Voice(QObject *parent = 0);
    bool continuous() const;

Q_SIGNALS:
    void add(QString text);
    void clear();
    void remove();
    void continuousChanged();

protected:
    bool eventFilter(QObject *obj, QEvent *event);

private:
    bool m_continuous;

    QStringList m_add;
    QStringList m_clean;
    QStringList m_end;
    QStringList m_remove;
    QStringList m_start;
};

#endif // VOICECOMMANDS_H
