#ifndef WEEKMODEL_H
#define WEEKMODEL_H

#include <QtCore/QAbstractListModel>
#include <QtCore/QDateTime>

struct Day {
    Day() {}
    Day(const QString &name, const QString &number) : name(name), number(number) {}
    QString name;
    QString number;
};

Q_DECLARE_TYPEINFO(Day, Q_MOVABLE_TYPE);

class WeekModel : public QAbstractListModel
{
    Q_OBJECT

public:
    explicit WeekModel(QObject *parent = 0);

    // from QAbstractItemModel
    int rowCount(const QModelIndex &parent = QModelIndex()) const Q_DECL_OVERRIDE;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const Q_DECL_OVERRIDE;
    QHash<int, QByteArray> roleNames() const Q_DECL_OVERRIDE;

protected:
    // from QObject
    void timerEvent(QTimerEvent *event) Q_DECL_OVERRIDE;

private:
    void populateModel();

    int m_timerId;
    QVector<Day> m_week;
    QDateTime m_today;
};

#endif // WEEKMODEL_H
