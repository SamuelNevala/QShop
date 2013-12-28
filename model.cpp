#include "model.h"
#include <QDebug>
#include <QtCore/QDataStream>
#include <QtCore/QFile>

Model::Model(QObject *parent)
    : QAbstractListModel(parent)
{
    m_roleNames.insert(Qt::UserRole, "item");
    m_roleNames.insert(Qt::CheckStateRole, "selected");
    load();
}

int Model::rowCount(const QModelIndex & parent) const
{
    Q_UNUSED(parent);
    return m_items.count();
}

QVariant Model::data(const QModelIndex & index, int role) const
{
    if (!index.isValid()) return QVariant();
    if (role == Qt::UserRole)
        return m_items[index.row()];
    else
        return m_selection[index.row()];
}

QHash<int, QByteArray> Model::roleNames() const
{
    return m_roleNames;
}

int Model::count() const
{
    return m_items.count();
}

void Model::append(QString item)
{
    beginInsertRows(QModelIndex(), m_items.count(), m_items.count());
    m_items.append(item);
    m_selection.append(false);
    endInsertRows();
    Q_EMIT countChanged();
    save();
}

void Model::insert(int index, QString item)
{
    int boundIndex = qBound(0, index, m_items.count());
    beginInsertRows(QModelIndex(), boundIndex, boundIndex);
    m_items.insert(boundIndex, item);
    m_selection.insert(boundIndex, false);
    endInsertRows();
    Q_EMIT countChanged();
    save();
}

void Model::remove(int index)
{
    beginRemoveRows(QModelIndex(), index, index);
    m_items.removeAt(index);
    m_selection.removeAt(index);
    endRemoveRows();
    Q_EMIT countChanged();
    save();
}

void Model::removeAll()
{
    beginRemoveRows(QModelIndex(), 0, m_items.count() - 1);
    m_items.clear();
    m_selection.clear();
    endRemoveRows();
    Q_EMIT countChanged();
    save();
}

void Model::reset()
{
    beginResetModel();
    for (int index = 0; index < m_selection.count(); ++index)
        m_selection[index] = false;
    endResetModel();
}

void Model::move(int source, int destination)
{
    if (source == destination) return;
    int selection = m_selection.indexOf(true);

    //qDebug()<<"wer"<<destination<<" "<<selection;
    m_selection[source] = destination >= selection;
    Q_EMIT dataChanged(index(source,0), index(source,0), QVector<int>() << Qt::CheckStateRole);

    beginMoveRows(QModelIndex(), source, source, QModelIndex(), destination + (destination > source ? 1 : 0));
    m_items.move(source, destination);
    m_selection.move(source, destination);
    endMoveRows();
    save();
}

void Model::setSelected(int index, bool selected)
{
    if (m_selection[index] == selected)
        return;

    m_selection[index] = selected;
    if (m_selection[index])
        moveToEnd(index);
    else
        moveToStart(index);
    save();
}

void Model::toggleSelected(int index)
{
    m_selection[index] = !m_selection[index];
    if (m_selection[index])
        moveToEnd(index);
    else
        moveToStart(index);
    save();
}

void Model::moveToEnd(int from)
{
    int to = m_selection.count(true) == 1 ? m_selection.count() - 1 : m_selection.indexOf(true, from+1) - 1;
    if (from != to) {
        beginMoveRows(QModelIndex(), from, from, QModelIndex(), to+1);
        m_items.move(from, to);
        m_selection.move(from, to);
        endMoveRows();
    }
}

void Model::moveToStart(int from)
{
    if (from == 0) return;
    beginMoveRows(QModelIndex(), from, from, QModelIndex(), 0);
    m_items.move(from, 0);
    m_selection.move(from, 0);
    endMoveRows();
}

void Model::save()
{
    QFile file("store.dat");
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate | QIODevice::Text))
        return;

    QDataStream out(&file);
    out << m_items.count();
    for (int index = 0; index < m_items.count(); ++index) {
        out << m_items[index] << m_selection[index];
    }
    file.close();
}

void Model::load()
{
    m_items.clear();
    m_selection.clear();
    int count = 0;
    QFile file("store.dat");
    file.open(QIODevice::ReadOnly | QIODevice::Text);
    QDataStream in(&file);
    in >> count;
    for (int index = 0; index < count; ++index) {
        QString item; bool selected;
        in >> item >> selected;
        m_items.append(item);
        m_selection.append(selected);
    }
    file.close();
}
