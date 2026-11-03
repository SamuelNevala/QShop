#include "weekmodel.h"

#include <chrono>

#include <QtCore/QAbstractListModel>
#include <QtCore/QDateTime>
#include <QtCore/QHash>
#include <QtCore/QObject>
#include <QtCore/QtCompilerDetection>
#include <QtCore/QtPreprocessorSupport>
#include <QtCore/QtTypes>
#include <QtCore/QString>
#include <QtCore/qnamespace.h>

using namespace std::chrono_literals;

constexpr qint32 kDays{ 6U };

WeekModel::WeekModel(QObject *parent) Q_DECL_NOTHROW : QAbstractListModel(parent)
{
    populateModel();
    // NOLINTNEXTLINE(misc-include-cleaner): the chrono literal is provided by the direct <chrono> include.
    m_timerId = startTimer(1min);
}

int WeekModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }
    return static_cast<int>(m_week.count());
}

QVariant WeekModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= rowCount()) {
        return { };
    }

    switch (role) {
    case Qt::UserRole: {
        return m_week.at(index.row()).name;
    }
    case Qt::UserRole + 1: {
        return m_week.at(index.row()).number;
    }
    default: {
        return { };
    }
    }
}

QHash<int, QByteArray> WeekModel::roleNames() const
{
    return QHash<int, QByteArray>{ { Qt::UserRole, "name" }, { Qt::UserRole + 1, "number" } };
}

void WeekModel::timerEvent(QTimerEvent *event)
{
    Q_UNUSED(event);
    if (QDateTime::currentDateTime().date().day() == m_today.date().day()) {
        return;
    }
    populateModel();
}

void WeekModel::populateModel()
{
    if (!m_week.isEmpty()) {
        beginRemoveRows(QModelIndex(), 0, static_cast<int>(m_week.count() - 1));
        m_week.clear();
        endRemoveRows();
    }

    beginResetModel();
    m_today = QDateTime::currentDateTime();
    for (qint32 days = 0; days <= kDays; ++days) {
        m_week.append(Day(m_today.addDays(days).toString(QStringLiteral("ddd")),
                          m_today.addDays(days).toString(QStringLiteral("d"))));
    }
    endResetModel();
}
