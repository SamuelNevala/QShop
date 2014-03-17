#ifndef SORTFILTERMODEL_H
#define SORTFILTERMODEL_H

#include <QtCore/QSortFilterProxyModel>

class SortFilterModel : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(QObject* model READ sourceModel WRITE setModel NOTIFY modelChanged)
    Q_PROPERTY(QString sortRole READ sortRole WRITE setSortRole NOTIFY sortRoleChanged)
    Q_PROPERTY(QString filterRole READ filterRole WRITE setFilterRole NOTIFY filterRoleChanged)

public:
    explicit SortFilterModel(QObject *parent = 0);
    void setModel(QObject* model);

    QString sortRole() const;
    void setSortRole(const QString &role);

    QString filterRole() const;
    void setFilterRole(const QString &role);

    Q_INVOKABLE QVariant get(int row, const QString &role);
    Q_INVOKABLE void set(int row, const QVariant &data, const QString &role);
    Q_INVOKABLE QVariant indexOf(const QString &role, QVariant value);

public Q_SLOTS:
    void manualSort();

Q_SIGNALS:
    void modelChanged();
    void sortRoleChanged();
    void filterRoleChanged();

private:
    QString m_sortRole;
    QString m_filterRole;
};

#endif // SORTFILTERMODEL_H
