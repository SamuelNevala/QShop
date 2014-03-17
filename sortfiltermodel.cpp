#include "sortfiltermodel.h"
#include <QtCore/QDebug>

SortFilterModel::SortFilterModel(QObject *parent)
    : QSortFilterProxyModel(parent)
{
    connect(this, SIGNAL(sourceModelChanged()), SIGNAL(modelChanged()));
    connect(this, SIGNAL(sortRoleChanged()), SLOT(manualSort()));
}

void SortFilterModel::setModel(QObject *model)
{
    QAbstractItemModel* tmpModel = qobject_cast<QAbstractItemModel*>(model);
    if (tmpModel == NULL) return;
    setSourceModel(tmpModel);
    setSortRole(m_sortRole);
    setFilterRole(m_filterRole);
}

QString SortFilterModel::sortRole() const
{
    return m_sortRole;
}

void SortFilterModel::setSortRole(const QString &role)
{
    m_sortRole = role;
    QSortFilterProxyModel::setSortRole(roleNames().key(role.toLatin1()));
    Q_EMIT sortRoleChanged();
}

QString SortFilterModel::filterRole() const
{
    return m_filterRole;
}

void SortFilterModel::setFilterRole(const QString &role)
{
    m_filterRole = role;
    QSortFilterProxyModel::setFilterRole(roleNames().key(role.toLatin1()));
    Q_EMIT filterRoleChanged();
}

QVariant SortFilterModel::get(int row, const QString &role)
{
    return data(index(row, 0), roleNames().key(role.toLatin1()));
}

void SortFilterModel::set(int row, const QVariant &data, const QString &role)
{
    setData(index(row, 0), data, roleNames().key(role.toLatin1()));
}

QVariant SortFilterModel::indexOf(const QString &role, QVariant value)
{
    QModelIndexList result = match(index(0, 0), roleNames().key(role.toLatin1()), value);
    return result.empty() ? 0 : result.at(0).row();
}

void SortFilterModel::manualSort()
{
    sort(0, sortOrder());
}
