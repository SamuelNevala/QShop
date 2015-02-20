#include "weekmodel.h"
#include <QtCore/QDateTime>

WeekModel::WeekModel(QObject *parent)
    : QAbstractListModel(parent)
    , m_timerId(0)
{
    m_roleNames.insert(Qt::UserRole, "dayName");
    m_roleNames.insert(Qt::UserRole + 1, "dayNumber");
    populateModel();
    m_timerId = startTimer(60000);
}

int WeekModel::rowCount(const QModelIndex & parent) const
{
    Q_UNUSED(parent);
    return m_data.count();
}

QVariant WeekModel::data(const QModelIndex & index, int role) const
{
    if (!index.isValid()) return QVariant();

    if (role == Qt::UserRole)
        return m_data[index.row()].first;
    else if (role == Qt::UserRole +1)
        return m_data[index.row()].second;
    else
        return QVariant();
}

QHash<int, QByteArray> WeekModel::roleNames() const
{
    return m_roleNames;
}

int WeekModel::count() const
{
    return m_data.count();
}

void WeekModel::timerEvent(QTimerEvent *event)
{
    Q_UNUSED(event);
    if (QDateTime::currentDateTime().date().day() != m_today.date().day())
        populateModel();
}

void WeekModel::populateModel()
{
    if (m_data.count() != 0) {
    beginRemoveRows(QModelIndex(), 0, m_data.count() - 1);
    m_data.clear();
    endRemoveRows();
    }

    beginResetModel();
    QDateTime m_today = QDateTime::currentDateTime();
    for (int days = 0; days <= 6; ++days) {
        QPair<QString, QString> item;
        item.first = m_today.addDays(days).toString("ddd");
        item.second = m_today.addDays(days).toString("d");
        m_data.append(item);
    }
    endResetModel();
    Q_EMIT dataChanged(index(0), index(m_data.count()));
    Q_EMIT countChanged();
}
