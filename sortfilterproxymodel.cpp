#include "sortfilterproxymodel.h"

SortFilterProxyModel::SortFilterProxyModel(QObject *parent)
    : QSortFilterProxyModel{parent}
{
}

void SortFilterProxyModel::classBegin()
{
    setFilterRole(Qt::CheckStateRole);
    setFilterRegularExpression("^false$");
    sort(0);
}

void SortFilterProxyModel::componentComplete()
{
}
