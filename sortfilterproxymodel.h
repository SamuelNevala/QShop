#ifndef SORTFILTERPROXYMODEL_H
#define SORTFILTERPROXYMODEL_H

#include <QQmlEngine>
#include <QSortFilterProxyModel>

class SortFilterProxyModel : public QSortFilterProxyModel, public QQmlParserStatus
{
    Q_OBJECT
    QML_ELEMENT
    Q_INTERFACES(QQmlParserStatus)
public:
    explicit SortFilterProxyModel(QObject *parent = nullptr);

    // // from QQmlParserStatus
    void classBegin() Q_DECL_OVERRIDE;
    void componentComplete() Q_DECL_OVERRIDE;

};

#endif // SORTFILTERPROXYMODEL_H
