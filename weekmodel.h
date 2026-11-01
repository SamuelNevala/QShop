#ifndef WEEKMODEL_H
#define WEEKMODEL_H

#include <utility>

#include <QtCore/QAbstractListModel>
#include <QtCore/QDateTime>
#include <QtCore/QHash>
#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QtCompilerDetection>
#include <QtCore/QTypeInfo>
#include <QtCore/qtmetamacros.h>
#include <QtCore/qnamespace.h>
#include <QtQml/QQmlEngine>
#include <QtQmlIntegration/qqmlintegration.h>

struct Day
{
    Day() = default;
    Day(QString &&name, QString &&number) : name(std::move(name)), number(std::move(number)) { }
    Day(const Day &) = default;
    Day &operator=(const Day &) = default;
    Day(Day &&) noexcept = default;
    Day &operator=(Day &&) noexcept = default;
    ~Day() = default;

    QString name;
    QString number;
};

Q_DECLARE_TYPEINFO(Day, Q_MOVABLE_TYPE);

class WeekModel : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit WeekModel(QObject *parent = nullptr) Q_DECL_NOTHROW;

    // from QAbstractListModel
    [[nodiscard]] int rowCount(const QModelIndex &parent = QModelIndex()) const Q_DECL_OVERRIDE;
    [[nodiscard]] QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const
            Q_DECL_OVERRIDE;
    [[nodiscard]] QHash<int, QByteArray> roleNames() const Q_DECL_OVERRIDE;

protected:
    // from QObject
    void timerEvent(QTimerEvent *event) Q_DECL_OVERRIDE;

private:
    void populateModel();

    int m_timerId = 0;
    QList<Day> m_week;
    QDateTime m_today{ QDateTime::currentDateTime() };
};

#endif // WEEKMODEL_H
