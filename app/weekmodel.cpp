#include "weekmodel.h"

#include <chrono>

#include <QtCore/QAbstractListModel>
#include <QtCore/QDate>
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
    populateModel(QDate::currentDate());
    // NOLINTNEXTLINE(misc-include-cleaner): the chrono literal is provided by the direct <chrono> include.
    startTimer(1min);
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
    updateDate(QDate::currentDate());
}

void WeekModel::updateDate(QDate today)
{
    if (today == m_today) {
        return;
    }
    populateModel(today);
}

void WeekModel::populateModel(QDate today)
{
    beginResetModel();
    m_week.clear();
    m_today = today;
    for (qint32 days = 0; days <= kDays; ++days) {
        m_week.append(Day{ .name = m_today.addDays(days).toString(QStringLiteral("ddd")),
                           .number = m_today.addDays(days).toString(QStringLiteral("d")) });
    }
    endResetModel();
}
