#include "weekmodel.h"

WeekModel::WeekModel(QObject *parent) Q_DECL_NOTHROW
    : QAbstractListModel(parent)
    , m_timerId(0)
{
    populateModel();
    m_timerId = startTimer(60000);
}

int WeekModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_week.count();
}

QVariant WeekModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()
      || index.row() < 0
      || index.row() >= rowCount()) {
        return QVariant();
    }

    if (role == Qt::UserRole) {
        return m_week[index.row()].name;
    } else if (role == Qt::UserRole +1) {
        return m_week[index.row()].number;
    } else {
        return QVariant();
    }
}

QHash<int, QByteArray> WeekModel::roleNames() const
{
    return QHash<int, QByteArray> {{ Qt::UserRole, "name" },
                                   { Qt::UserRole + 1, "number" }};
}

void WeekModel::timerEvent(QTimerEvent *event)
{
    Q_UNUSED(event);
    if (QDateTime::currentDateTime().date().day() != m_today.date().day()) {
        populateModel();
    }
}

void WeekModel::populateModel()
{
    if (m_week.count()) {
        beginRemoveRows(QModelIndex(), 0, m_week.count() - 1);
        m_week.clear();
        endRemoveRows();
    }

    beginResetModel();
    QDateTime m_today = QDateTime::currentDateTime();
    for (int days = 0; days <= 6; ++days) {
        m_week.append(Day(m_today.addDays(days).toString("ddd"),
                          m_today.addDays(days).toString("d")));
    }
    endResetModel();
}
