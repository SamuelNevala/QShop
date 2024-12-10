#ifndef WEEKMODEL_H
#define WEEKMODEL_H

#include <QtCore/QAbstractListModel>
#include <QtCore/QDateTime>
#include <QQmlEngine>

struct Day {
    Day() = default;
    Day(QString &&name, QString &&number) : name(name), number(number) {}
    Day(const Day&) = default;
    Day& operator=(const Day&) = default;
    Day(Day&&) noexcept = default;
    Day& operator = (Day&&) noexcept = default;

    QString name;
    QString number;
};

Q_DECLARE_TYPEINFO(Day, Q_MOVABLE_TYPE);

class WeekModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit WeekModel(QObject *parent = 0) Q_DECL_NOTHROW;

    // from QAbstractListModel
    int rowCount(const QModelIndex &parent = QModelIndex()) const Q_DECL_OVERRIDE;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const Q_DECL_OVERRIDE;
    QHash<int, QByteArray> roleNames() const Q_DECL_OVERRIDE;

protected:
    // from QObject
    void timerEvent(QTimerEvent *event) Q_DECL_OVERRIDE;

private:
    void populateModel();

    int m_timerId = 0;
    QVector<Day> m_week;
    QDateTime m_today;
};

#endif // WEEKMODEL_H
