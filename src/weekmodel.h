#ifndef WEEKMODEL_H
#define WEEKMODEL_H

#include <QtCore/QAbstractListModel>
#include <QtCore/QList>
#include <QtCore/QPair>
#include <QtCore/QString>
#include <QtCore/QDateTime>

class WeekModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    WeekModel(QObject *parent = 0);

    // from QAbstractItemModel
    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
    QHash<int, QByteArray> roleNames() const;

    int count() const;

Q_SIGNALS:
    void countChanged();

protected:
    void timerEvent(QTimerEvent *event);

private:
    void populateModel();

    int m_timerId;
    QList<QPair<QString, QString> > m_data;
    QDateTime m_today;
};

#endif // WEEKMODEL_H
