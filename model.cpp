#include "model.h"
#include "undoremove.h"

#include <QtCore/QDataStream>
#include <QtCore/QFile>
#include <QtCore/QStandardPaths>
#include <QtCore/QDir>

#include <QSqlError>
#include <QSqlQuery>
#include <QDebug>

#include <algorithm>

static const QString kChecked = QStringLiteral("checked");
static const QString kEditor = QStringLiteral("editor");
static const QString kId = QStringLiteral("id");
static const QString kName = QStringLiteral("name");

inline bool operator==(const Item& left, const Item& right)
{
    return left.name == right.name && left.checked == right.checked;
}

Model::Model(QObject *parent) Q_DECL_NOTHROW
    : QAbstractListModel(parent)
{
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
    case Qt::UserRole + 1:
        return m_items[index.row()].uuid.toString(QUuid::WithoutBraces);
    default:
        return QVariant();
    }
}

bool Model::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (!index.isValid()
      || index.row() < 0
      || index.row() >= rowCount()
      || role != Qt::CheckStateRole
      || m_read_only) {
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
    return QHash<int, QByteArray> {{ Qt::DisplayRole, kName.toUtf8() },
                                   { Qt::CheckStateRole, kChecked.toUtf8() },
                                   { Qt::EditRole, kEditor.toUtf8() },
                                   { Qt::UserRole + 1, kId.toUtf8() } };
}

int Model::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_items.count();
}

void Model::classBegin()
{

}

void Model::componentComplete()
{
    dropRemovedTables();
    if (m_active_list_id.isNull()) {
        load();
    }
}

void Model::insert(qsizetype index, Item &&item)
{
    if (m_read_only) {
        return;
    }
    const int clamped = std::clamp(index, qsizetype(0), m_items.size());

    // Renaming list reuse the uuid.
    const auto editor = editorIndex();
    if (m_active_list_id.isNull() && editor != -1 && !m_items.at(editor).uuid.isNull()) {
        item.uuid = m_items[editor].uuid;
        m_items[editor].uuid = QUuid();
    }

    beginInsertRows(QModelIndex(), clamped, clamped);
    createList(item);
    m_items.insert(clamped, 1, std::move(item));
    endInsertRows();
    Q_EMIT countChanged();
    save();
}

void Model::insert(qsizetype index, const QString &name)
{
    insert(index, Item(name));
}

void Model::remove(qsizetype index)
{
    if (m_read_only || index < 0 || index >= m_items.size()) {
        return;
    }

    beginRemoveRows(QModelIndex(), index, index);
    Item &&item = m_items.takeAt(index);
    if (!item.name.isEmpty()) {
        m_stack.clear();
        auto remove = new UndoRemove(*this);
        remove->append(std::move(item), index);
        m_stack.push(remove);
    }
    endRemoveRows();
    Q_EMIT countChanged();
    save();
}

QString Model::editItem(qsizetype index)
{
    if (m_read_only || index < 0 || index >= m_items.size() - 1) {
        return QString();
    }

    beginRemoveRows(QModelIndex(), index, index);
    Item &&item = m_items.takeAt(index);
    endRemoveRows();
    // Store uuid to input.
    m_items[editorIndex()].uuid = item.uuid;
    moveEditor(index, Force::YES);
    Q_EMIT countChanged();
    save();
    return item.name;
}

void Model::removeAll()
{
    removeAll(Save::YES);
}

void Model::removeChecked()
{
    if (m_read_only) {
        return;
    }

    const auto begin = m_items.cbegin();
    const auto end = m_items.cend();
    const auto first = std::find_if(begin, end, [] (const Item& value) { return value.checked; });

    if (first == end) {
        return;
    }

    auto position = std::distance(begin, first);
    beginRemoveRows(QModelIndex(), position, m_items.size() - 1);
    m_stack.clear();
    auto remove = new UndoRemove(*this);
    m_items.removeIf([&remove, &position](const Item &value) {
        if (value.checked) {
            remove->append(value, position++);
            return true;
        } else {
            return false;
        }
    });
    m_stack.push(remove);
    endRemoveRows();
    Q_EMIT countChanged();
    save();
}

void Model::setChecked(qsizetype index, bool checked)
{
    if (!setData(this->index(index, 0), checked, Qt::CheckStateRole)) {
        return;
    }

    move(index, checked ? checkedIndex(index) - 1 : 0);
    save();
}

void Model::toggleChecked(qsizetype index)
{
    setChecked(index, !m_items[index].checked);
}

void Model::reset()
{
    if (m_read_only) {
        return;
    }

    while (m_items.last().checked) {
        setChecked(m_items.size() - 1, false);
    }
}

void Model::move(qsizetype source, qsizetype destination)
{
    move(source, destination, Save::YES);
}

void Model::addEditor()
{
    if (m_read_only) {
        return;
    }

    // Editor is added already.
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

void Model::moveEditor(qsizetype destination, Force force)
{
    if (m_read_only) {
        return;
    }

    const auto source = editorIndex();
    // No editor to move.
    if (source == -1) {
        return;
    }

    destination = std::clamp(destination, qsizetype(0), m_items.size() - 1);
    move(source, destination + (force == Force::NO && source >= destination && source != 1 ? 1 : 0), Save::NO);
    Q_EMIT editorIndexChanged();
}

void Model::undo()
{
    if (m_read_only) {
        return;
    }

    m_stack.undo();
}

void Model::clearUndoStack()
{
    if (m_read_only) {
        return;
    }

    m_stack.clear();
}

void Model::reload()
{
    load();
}

qsizetype Model::editorIndex() const
{
    return m_items.indexOf(Item());
}

bool Model::canUndo() const {
    return m_read_only ? false : m_stack.canUndo();
}

QString Model::activeList() const
{
    return m_active_list_id.isNull() ? kListsTable : m_active_list_id.toString(QUuid::WithoutBraces);
}

void Model::setActiveList(const QString &id) {
    if (id.isEmpty()) {
        return;
    }

    const QUuid uuid = id == kListsTable ? QUuid() : id == kDefaultTable ? resolve(id) : QUuid::fromString(id);
    setActiveListId(uuid);
}

bool Model::readOnly() const
{
    return m_read_only;
}

void Model::setReadOnly(bool value)
{
    if (m_read_only == value) {
        return;
    }
    m_read_only = value;
    Q_EMIT readOnlyChanged();
}

void Model::append(Item &&item)
{
    beginInsertRows(QModelIndex(), m_items.size(), m_items.size());
    m_items.append(std::move(item));
    endInsertRows();
    Q_EMIT countChanged();
}

qsizetype Model::checkedIndex(qsizetype index) const
{
    const auto begin = m_items.cbegin();
    const auto end = m_items.cend();
    const auto checked = std::find_if(begin + index + 1, end, [](const Item &value) { return value.checked; });
    return checked == end ? m_items.size() : std::distance(begin, checked);
}

void Model::move(qsizetype source, qsizetype destination, Save changes)
{
    if (m_read_only || !beginMoveRows(QModelIndex(), source, source, QModelIndex(), destination + (destination > source ? 1 : 0))) {
        return;
    }

    m_items.insert(destination, 1, m_items.takeAt(source));
    endMoveRows();
    if (changes == Save::NO) {
        return;
    }
    save();
}

void Model::removeAll(Save changes)
{
    if (m_items.isEmpty()) {
        return;
    }

    const auto editor = editorIndex() != -1;
    // Only editor present don't delete.
    if (editor && m_items.size() == 1) {
        return;
    }

    if (editor) {
        moveEditor(0, Force::YES);
    }
    auto position = editor ? 1 : 0;
    beginRemoveRows(QModelIndex(), position, m_items.size() - 1);
    m_stack.clear();
    auto remove = new UndoRemove(*this);
    m_items.removeIf([&remove, &position](const Item &value) {
        if (!value.name.isEmpty()) {
            remove->append(value, position++);
            return true;
        } else {
            return false;
        }
    });

    endRemoveRows();
    Q_EMIT countChanged();
    if (changes == Save::NO) {
        delete remove;
        return;
    }
    save();
    m_stack.push(remove);
}


void Model::save()
{
    if (m_read_only) {
        return;
    }

    auto database = QSqlDatabase::database();
    if (!database.transaction()) {
        qWarning() << "Failed to start transaction while saving. Error:" << database.lastError();
        return;
    }

    const auto table = activeList();
    QSqlQuery query(database);
    if (!query.exec(kDeleteFrom.arg(table))) {
        qWarning() << "Failed to clear items from " << resolve(m_active_list_id) << "(" << m_active_list_id << "). Error:" << query.lastError();
        database.rollback();
        return;
    }


    query.prepare(kInsertTo.arg(table));
    QSqlError error;
    for (const auto &item : m_items) {
        if (!item.name.isEmpty()) {
            query.addBindValue(item.uuid);
            query.addBindValue(item.name);
            query.addBindValue(item.checked);

            if (!query.exec()) {
                error = query.lastError();
                qWarning() << "Failed to insert item to " << resolve(m_active_list_id) << "(" << m_active_list_id << ") while saving. Error:" << error;
                break;
            }
        }
    }

    if (error.isValid()) {
        database.rollback();
        return;
    }

    if (!database.commit()) {
        qWarning() << "Failed to commit transaction while saving error:" << database.lastError();
        database.rollback();
    }
}

void Model::load()
{
    removeAll(Save::NO);
    const auto table = activeList();
    QSqlQuery query(kSelectFrom.arg(table), QSqlDatabase::database());
    qDebug() << "Load from " << resolve(m_active_list_id) << "(" << m_active_list_id << ")";
    while (query.next()) {
        qDebug() << " id:" << query.value(kId) << " name:" <<query.value(kName) << " checked:" << query.value(kChecked);
        append(Item(query.value(kName).toString(), query.value(kChecked).toBool(), query.value(kId).toUuid()));
    }
    if (m_read_only && table == kListsTable) {
        Item lists;
        lists.name = kListsTable;
        append(std::move(lists));
    }
}

QUuid Model::resolve(const QString &name)
{
    QSqlQuery query(kSelectFrom.arg(kListsTable), QSqlDatabase::database());
    while (query.next()) {
        if (query.value(kName).toString() == name) {
            return query.value(kId).toUuid();
        }
    }
    return QUuid();
}

QString Model::resolve(const QUuid &id)
{
    if (id.isNull()) {
        return kListsTable;
    }

    QSqlQuery query(kSelectFrom.arg(kListsTable), QSqlDatabase::database());
    while (query.next()) {
        if (query.value(kId).toUuid() == id) {
            return query.value(kName).toString();
        }
    }
    return QString();

}

void Model::createList(const Item &row)
{
    if (!m_active_list_id.isNull()) {
        return;
    }

    QSqlQuery query(QSqlDatabase::database());
    if (!query.exec(kCreate.arg(row.uuid.toString(QUuid::WithoutBraces)))) {
        qWarning() << "Failed to create "<< row.name << "(" << row.uuid.toString(QUuid::WithoutBraces) << ") table. Error: " << query.lastError();
        return;
    }
}

const QUuid &Model::activeListId() const
{
    return m_active_list_id;
}

void Model::setActiveListId(const QUuid &id)
{
    if (m_active_list_id == id) {
        return;
    }

    qDebug() << "Active list changed from " << (m_active_list_id.isNull() ? kListsTable : resolve(m_active_list_id))
             << " to " << (id.isNull() ? kListsTable : resolve(id));

    m_active_list_id = id;
    load();
    Q_EMIT activeListChanged();
}

void Model::dropRemovedTables()
{
    if (m_read_only) {
        return;
    }

    QVector<Item> activeLists;
    QSqlQuery query(kSelectFrom.arg(kListsTable), QSqlDatabase::database());
    while (query.next()) {
        activeLists.append(Item(query.value(kName).toString(), query.value(kChecked).toBool(), query.value(kId).toUuid()));
    }

    if (!query.exec(kSelectAllTables)) {
        qWarning() << "Failed to all tables. Error:" << query.lastError();
        return;
    }

    QVector<QUuid> uuids;
    while (query.next()) {
        const auto id = query.value(kName).toUuid();
        if (!id.isNull()) {
            uuids.append(id);
        }
    }

    const auto begin = activeLists.cbegin();
    const auto end = activeLists.cend();
    for (const auto &uuid : uuids) {
        const auto result = std::find_if(begin, end, [&uuid] (const Item& value) { return value.uuid == uuid; });
        if (result == end) {
            qWarning() << "Drop table " << uuid;
            if (!query.exec(kDrop.arg(uuid.toString(QUuid::WithoutBraces)))) {
                qWarning() << "Failed to drop table " << uuid << ". Error:" << query.lastError();
            }
        }
    }
}
