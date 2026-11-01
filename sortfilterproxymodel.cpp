#include "sortfilterproxymodel.h"

#include <QtCore/QObject>
#include <QtCore/QSortFilterProxyModel>
#include <QtCore/QString>
#include <QtCore/qnamespace.h>

SortFilterProxyModel::SortFilterProxyModel(QObject *parent) : QSortFilterProxyModel{ parent } { }

void SortFilterProxyModel::classBegin()
{
    setFilterRole(Qt::CheckStateRole);
    setFilterRegularExpression(QStringLiteral("^false$"));
    sort(0);
}

void SortFilterProxyModel::componentComplete() { }
