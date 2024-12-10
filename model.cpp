#include "model.h"
#include "undoremove.h"

#include <QtCore/QDataStream>
#include <QtCore/QFile>
#include <QtCore/QStandardPaths>
#include <QtCore/QDir>

#include <QSqlError>
#include <QSqlQuery>
#include <QDebug>

inline bool operator==(const Item& left, const Item& right)
{
    return left.name == right.name && left.checked == right.checked;
}

Model::Model(QObject *parent) Q_DECL_NOTHROW
    : QAbstractListModel(parent)
{
    load();
    connect(&m_stack, &QUndoStack::canUndoChanged, this, &Model::canUndoChanged);
}

QVariant Model::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()
      || index.row() < 0
      || index.row() >= rowCount()) {
        return QVariant();
    }

    switch (role) {
    case Qt::DisplayRole:
        return m_items[index.row()].name;
    case Qt::CheckStateRole:
        return m_items[index.row()].checked;
    case Qt::EditRole:
        return m_items[index.row()].name.isEmpty();
    default:
        return QVariant();
    }
}

bool Model::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (!index.isValid()
      || index.row() < 0
      || index.row() >= rowCount()
      || role != Qt::CheckStateRole) {
        return false;
    }

    const bool checked = value.toBool();
    if (m_items[index.row()].checked == checked) {
        return false;
    }

    m_items[index.row()].checked = checked;
    Q_EMIT dataChanged(index, index, { Qt::CheckStateRole });
    return true;
}

QHash<int, QByteArray> Model::roleNames() const
{
    return QHash<int, QByteArray> {{ Qt::DisplayRole, "name" },
                                   { Qt::CheckStateRole, "checked" },
                                   { Qt::EditRole, "editor" }};
}

int Model::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_items.count();
}

void Model::insert(int index, Item &&item)
{
    const int bound = qBound(0, index, m_items.count());
    beginInsertRows(QModelIndex(), bound, bound);
    m_items.insert(bound, 1, item);
    endInsertRows();
    Q_EMIT countChanged();
    save();
}

void Model::insert(int index, const QString &name)
{
    insert(index, Item(name));
}

void Model::remove(int index)
{
    if (index < 0 || index >= m_items.count()) {
        return;
    }

    beginRemoveRows(QModelIndex(), index, index);
    Item item = m_items.takeAt(index);
    if (!item.name.isEmpty()) {
        m_stack.clear();
        m_stack.push(new UndoRemove(*this, std::move(item), index));
    }
    endRemoveRows();
    Q_EMIT countChanged();
    save();
}

QString Model::editItem(int index)
{
    if (index < 0 || index >= m_items.count()) {
        return QString();
    }

    beginRemoveRows(QModelIndex(), index, index);
    const Item item = m_items.takeAt(index);
    endRemoveRows();
    moveEditor(index, true);
    Q_EMIT countChanged();
    save();
    return item.name;
}

void Model::removeAll()
{
    beginRemoveRows(QModelIndex(), 0, m_items.count() - 1);
    m_items.clear();
    endRemoveRows();
    Q_EMIT countChanged();
    save();
}

void Model::removeChecked()
{
    const auto begin = m_items.cbegin();
    const auto end = m_items.cend();
    const auto first = std::find_if(begin, end, [] (const Item& value) { return value.checked; });

    if (first == end) {
        return;
    }

    const auto position = std::distance(begin, first);
    beginRemoveRows(QModelIndex(), position, m_items.count() - 1);
    m_items.removeIf([](const Item &value) { return value.checked; });
    endRemoveRows();
    Q_EMIT countChanged();
    save();
}

void Model::setChecked(int index, bool checked)
{
    if (!setData(this->index(index, 0), checked, Qt::CheckStateRole)) {
        return;
    }

    move(index, checked ? checkedIndex(index) - 1 : 0);
    save();
}

void Model::toggleChecked(int index)
{
    setChecked(index, !m_items[index].checked);
}

void Model::reset()
{
    while (m_items.last().checked) {
        setChecked(m_items.count() - 1, false);
    }
}

void Model::move(int source, int destination)
{
    if (source == destination || source < 0 || destination < 0) {
        return;
    }
    beginMoveRows(QModelIndex(), source, source, QModelIndex(), destination + (destination > source ? 1 : 0));
    Item &&moved = m_items.takeAt(source);
    m_items.insert(destination, 1, moved);
    endMoveRows();
    save();
}

void Model::addEditor()
{
    if (editorIndex() != -1) {
        return;
    }

    beginInsertRows(QModelIndex(), 0, 0);
    m_items.insert(0, 1, Item());
    endInsertRows();
    Q_EMIT countChanged();
    Q_EMIT editorIndexChanged();
}

void Model::removeEditor()
{
    remove(editorIndex());
}

void Model::moveEditor(int destination, bool force)
{
    const int source = editorIndex();
    if (source == -1) {
        return;
    }

    destination = qBound(0, destination, m_items.count() - 1);
    doMove(source, destination + (!force && source >= destination && source != 1 ? 1 : 0));
    Q_EMIT editorIndexChanged();
}

void Model::undo()
{
    m_stack.undo();
}

void Model::clearUndoStack()
{
    m_stack.clear();
}

int Model::editorIndex() const
{
    return m_items.indexOf(Item());
}

bool Model::canUndo() const {
    return m_stack.canUndo();
}


void Model::append(Item &&item)
{
    beginInsertRows(QModelIndex(), m_items.count(), m_items.count());
    m_items.append(item);
    endInsertRows();
    Q_EMIT countChanged();
}

int Model::checkedIndex(int index) const
{
    const auto begin = m_items.cbegin();
    const auto end = m_items.cend();
    const auto checked = std::find_if(begin + index + 1, end, [](const Item &value) { return value.checked; });
    return checked == end ? m_items.count() : std::distance(begin, checked);
}

void Model::doMove(int source, int destination)
{
    if (!beginMoveRows(QModelIndex(), source, source, QModelIndex(), destination + (destination > source ? 1 : 0))) {
        return;
    }

    m_items.insert(destination, 1, m_items.takeAt(source));
    endMoveRows();
    save();
}

void Model::doSetChecked(int index, bool checked)
{
    if (!setData(this->index(index, 0), checked, Qt::CheckStateRole)) {
        return;
    }

    doMove(index, checked ? checkedIndex(index) - 1 : 0);
    save();
}

void Model::save()
{
    auto database = QSqlDatabase::database();
    if (!database.transaction()) {
        qDebug() << "Failed to start transaction while saving error:" << database.lastError();
        return;
    }

    QSqlQuery clear(database);
    if (!clear.exec(QStringLiteral("DELETE FROM shop_list"))) {
        qDebug() << "Error clearing items while saving error:" << clear.lastError();
        database.rollback();
        return;
    }

    QSqlQuery insert(database);
    insert.prepare(QStringLiteral("INSERT INTO shop_list (id, name, checked) VALUES (?, ?, ?)"));

    QSqlError error;
    for (const auto &item : m_items) {
        if (!item.name.isEmpty()) {
            insert.addBindValue(item.uuid);
            insert.addBindValue(item.name);
            insert.addBindValue(item.checked);

            if (!insert.exec()) {
                error = insert.lastError();
                qDebug() << "Error inserting item while saving error:" << insert.lastError();
                return;
            }
        }
    }

    if (error.isValid()) {
        database.rollback();
        return;
    }

    if (!database.commit()) {
        qDebug() << "Failed to commit transaction while saving error:" << database.lastError();
        database.rollback();
    }
}

void Model::load()
{
    m_items.clear();
    QSqlQuery query(QStringLiteral("SELECT name, checked, id FROM shop_list"), QSqlDatabase::database());
    while (query.next()) {
        qDebug() << "from model id:" << query.value("id") << " name:" <<query.value("name") << " ch:" << query.value("checked");
        append(Item(query.value(QStringLiteral("name")).toString(), query.value(QStringLiteral("checked")).toBool()));
    }
}

