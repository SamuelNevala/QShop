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

QString WeekModel::localeName() const
{
    return m_locale.name();
}

void WeekModel::setLocaleName(const QString &name)
{
    const QLocale locale(name);
    if (m_locale == locale) {
        return;
    }
    m_locale = locale;
    populateModel(m_today);
    Q_EMIT localeNameChanged();
}

void WeekModel::populateModel(QDate today)
{
    beginResetModel();
    m_week.clear();
    m_today = today;
    for (qint32 days = 0; days <= kDays; ++days) {
        const auto date = m_today.addDays(days);
        m_week.append(Day{ .name = m_locale.dayName(date.dayOfWeek(), QLocale::ShortFormat),
                           .number = date.toString(QStringLiteral("d")) });
    }
    endResetModel();
}
