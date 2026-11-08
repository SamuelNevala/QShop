#include "model.h"
#include "logging.h"
#include <QtCore/QLoggingCategory>

#include <algorithm>
#include <iterator>
#include <memory>
#include <utility>

#include <QtCore/QAbstractListModel>
#include <QtCore/QByteArrayView>
#include <QtCore/QDebug>
#include <QtCore/QHash>
#include <QtCore/QList>
#include <QtCore/QObject>
#include <QtCore/QPointer>
#include <QtCore/QStandardPaths>
#include <QtCore/QString>
#include <QtCore/QtCompilerDetection>
#include <QtCore/QtLogging>
#include <QtCore/QtTypes>
#include <QtCore/qnamespace.h>
#include <QtCore/qtmetamacros.h>
#include <QtGui/QUndoStack>
#include <QtPreprocessorSupport>
#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlError>
#include <QtSql/QSqlQuery>

#include "undoremove.h"

constexpr QByteArrayView kChecked{ "checked" };
constexpr QByteArrayView kEditor{ "editor" };
constexpr QByteArrayView kId{ "id" };
constexpr QByteArrayView kName{ "name" };

Model::Model(QObject *parent) Q_DECL_NOTHROW : QAbstractListModel(parent)
{
    connect(&m_stack, &QUndoStack::canUndoChanged, this, &Model::canUndoChanged);
    connect(&m_stack, &QUndoStack::undoTextChanged, this, &Model::undoMessageChanged);
}

QVariant Model::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() < 0 || index.row() >= rowCount()) {
        return { };
    }

    switch (role) {
    case Qt::DisplayRole:
        return m_items.at(index.row()).name;
    case Qt::CheckStateRole:
        return m_items.at(index.row()).checked;
    case Qt::EditRole:
        return index.row() == m_editorIndex;
    case Qt::UserRole + 1:
        return m_items.at(index.row()).uuid.toString(QUuid::WithoutBraces);
    default:
        return { };
    }
}

bool Model::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (!index.isValid() || index.row() < 0 || index.row() >= rowCount()
        || index.row() == m_editorIndex || role != Qt::CheckStateRole || m_readOnly) {
        return false;
    }

    const bool checked = value.toBool();
    if (m_items.at(index.row()).checked == checked) {
        return false;
    }

    // The entry guard validates this mutable QList access; at() is const-only.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-avoid-unchecked-container-access)
    m_items[index.row()].checked = checked;
    Q_EMIT dataChanged(index, index, { Qt::CheckStateRole });
    return true;
}

QHash<int, QByteArray> Model::roleNames() const
{
    return QHash<int, QByteArray>{ { Qt::DisplayRole, kName.data() },
                                   { Qt::CheckStateRole, kChecked.data() },
                                   { Qt::EditRole, kEditor.data() },
                                   { Qt::UserRole + 1, kId.data() } };
}

int Model::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid()) {
        return 0;
    }

    return static_cast<int>(m_items.count());
}

void Model::classBegin() { }

void Model::componentComplete()
{
    dropRemovedTables();
    if (m_activeListId.isNull()) {
        load(m_activeListId);
    }
}

void Model::insert(qsizetype index, Item &&item)
{
    insert(index, std::move(item), true);
}

void Model::insert(qsizetype index, Item &&item, bool submitEdit)
{
    if (m_readOnly) {
        return;
    }
    const auto clamped = std::clamp(index, static_cast<qsizetype>(0), m_items.size());

    const auto editor = editorIndex();
    if (submitEdit && m_pendingEdit && clamped == editor && !item.name.isEmpty()) {
        // Preserve item identity, including the table identifier when renaming a list.
        item.uuid = m_pendingEdit->uuid;
        item.checked = m_pendingEdit->checked;
        m_pendingEdit.reset();
        // A pending edit always has an existing editor placeholder.
        // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-avoid-unchecked-container-access)
        m_items[editor].uuid = QUuid();
        const auto editorModelIndex = this->index(static_cast<int>(editor));
        Q_EMIT dataChanged(editorModelIndex, editorModelIndex, { Qt::UserRole + 1 });
    }

    const auto previousEditor = m_editorIndex;
    beginInsertRows(QModelIndex(), static_cast<int>(clamped), static_cast<int>(clamped));
    createList(item);
    m_items.insert(clamped, std::move(item));
    if (m_editorIndex >= clamped) {
        ++m_editorIndex;
    }
    endInsertRows();
    Q_EMIT countChanged();
    if (m_editorIndex != previousEditor) {
        Q_EMIT editorIndexChanged();
    }
    save();
}

void Model::insert(qsizetype index, const QString &name)
{
    insert(index, Item(name));
}

void Model::remove(qsizetype index)
{
    if (m_readOnly || index < 0 || index >= m_items.size()) {
        return;
    }

    if (m_pendingEdit && index == editorIndex()) {
        restorePendingEdit();
        index = editorIndex();
        // Restoration emits notifications; a receiver may make the model read-only.
        if (m_readOnly || index < 0 || index >= m_items.size()) {
            return;
        }
    }

    std::unique_ptr<UndoRemove> removed;
    if (!m_items.at(index).name.isEmpty()) {
        removed = std::make_unique<UndoRemove>(*this);
        removed->append(index);
    }
    const auto previousEditor = m_editorIndex;
    beginRemoveRows(QModelIndex(), static_cast<int>(index), static_cast<int>(index));
    m_items.removeAt(index);
    if (m_editorIndex == index) {
        m_editorIndex = -1;
    } else if (m_editorIndex > index) {
        --m_editorIndex;
    }
    endRemoveRows();
    Q_EMIT countChanged();
    if (m_editorIndex != previousEditor) {
        Q_EMIT editorIndexChanged();
    }
    save();
    if (removed) {
        m_stack.push(removed.release());
        Q_EMIT deletionRecorded();
    }
}

QString Model::editItem(qsizetype index)
{
    const auto editor = editorIndex();
    if (m_readOnly || index < 0 || index >= m_items.size() || editor == -1 || index == editor
        || m_pendingEdit) {
        return { };
    }

    beginRemoveRows(QModelIndex(), static_cast<int>(index), static_cast<int>(index));
    m_pendingEdit = m_items.takeAt(index);
    endRemoveRows();
    const auto editorAfterRemoval = editor - (editor > index ? 1 : 0);
    m_editorIndex = editorAfterRemoval;
    // Associate the placeholder with the original row until submission.
    const auto editorModelIndex = this->index(static_cast<int>(editorAfterRemoval));
    // The guarded editor survives removal of a different row; the pending item was assigned above.
    // NOLINTNEXTLINE(bugprone-unchecked-optional-access,cppcoreguidelines-pro-bounds-avoid-unchecked-container-access)
    m_items[editorAfterRemoval].uuid = m_pendingEdit->uuid;
    Q_EMIT dataChanged(editorModelIndex, editorModelIndex, { Qt::UserRole + 1 });
    moveEditor(index - (editor < index ? 1 : 0), Force::YES);
    Q_EMIT countChanged();
    save();
    // NOLINTNEXTLINE(bugprone-unchecked-optional-access): moveEditor and save preserve the pending item.
    return m_pendingEdit->name;
}

void Model::removeAll()
{
    if (m_readOnly) {
        return;
    }

    removeAll(Save::YES);
}

void Model::removeChecked()
{
    if (m_readOnly) {
        return;
    }

    if (!std::ranges::any_of(m_items, [](const Item &value) { return value.checked; })) {
        return;
    }

    auto remove = std::make_unique<UndoRemove>(*this);
    for (qsizetype row = 0; row < m_items.size(); ++row) {
        if (m_items.at(row).checked) {
            remove->append(row);
        }
    }

    bool editorChanged = false;
    for (qsizetype row = m_items.size() - 1; row >= 0;) {
        if (!m_items.at(row).checked) {
            --row;
        } else {
            const auto last = row;
            while (row > 0 && m_items.at(row - 1).checked) {
                --row;
            }
            const auto first = row;
            beginRemoveRows(QModelIndex(), static_cast<int>(first), static_cast<int>(last));
            m_items.remove(first, last - first + 1);
            if (m_editorIndex > last) {
                m_editorIndex -= last - first + 1;
                editorChanged = true;
            } else if (m_editorIndex >= first && m_editorIndex <= last) {
                m_editorIndex = -1;
                editorChanged = true;
            }
            endRemoveRows();
            if (first == 0) {
                break;
            }
            row = first - 1;
        }
    }

    m_stack.push(remove.release());
    Q_EMIT countChanged();
    if (editorChanged) {
        Q_EMIT editorIndexChanged();
    }
    save();
    Q_EMIT deletionRecorded();
}

void Model::setChecked(qsizetype index, bool checked)
{
    if (m_readOnly || index < 0 || index >= m_items.size()) {
        return;
    }

    if (!setData(this->index(static_cast<int>(index)), checked, Qt::CheckStateRole)) {
        return;
    }

    move(index, checked ? checkedIndex(index) - 1 : 0, Save::NO);
    save();
}

void Model::toggleChecked(qsizetype index)
{
    if (m_readOnly || index < 0 || index >= m_items.size()) {
        return;
    }

    setChecked(index, !m_items.at(index).checked);
}

void Model::reset()
{
    if (m_readOnly) {
        return;
    }

    // Record checked positions, including the original item being edited.
    QList<qsizetype> checkedRows;
    checkedRows.reserve(m_items.size());
    for (int row = 0; row < rowCount(); ++row) {
        const bool editedChecked = row == m_editorIndex && m_pendingEdit && m_pendingEdit->checked;
        if (m_items.at(row).checked || editedChecked) {
            checkedRows.append(row);
            setData(index(row), false, Qt::CheckStateRole);
        }
    }
    if (m_pendingEdit) {
        m_pendingEdit->checked = false;
    }

    for (qsizetype left = 0, right = checkedRows.size() - 1; left < right; ++left, --right) {
        const auto first = checkedRows.at(left);
        const auto last = checkedRows.at(right);
        // Swap checked rows without shifting unchecked positions or recreating the editor.
        move(last, first, Save::NO);
        move(first + 1, last, Save::NO);
    }
    if (!checkedRows.isEmpty()) {
        save();
    }
}

void Model::move(qsizetype source, qsizetype destination)
{
    move(source, destination, Save::YES);
}

void Model::addEditor()
{
    if (m_readOnly) {
        return;
    }

    // Editor is added already.
    if (m_editorIndex != -1) {
        return;
    }

    beginInsertRows(QModelIndex(), 0, 0);
    m_items.insert(0, 1, Item());
    m_editorIndex = 0;
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
    if (m_readOnly) {
        return;
    }

    const auto source = editorIndex();
    // No editor to move.
    if (source == -1) {
        return;
    }

    destination = std::clamp(destination, static_cast<qsizetype>(0), m_items.size() - 1);
    move(source, destination + (force == Force::NO && source >= destination && source != 1 ? 1 : 0),
         Save::NO);
    Q_EMIT editorIndexChanged();
}

void Model::undo()
{
    if (m_readOnly) {
        return;
    }

    m_stack.undo();
}

void Model::clearUndoStack()
{
    if (m_readOnly) {
        return;
    }

    m_stack.clear();
}

void Model::reload()
{
    load(m_activeListId);
}

int Model::editorIndex() const
{
    return static_cast<int>(m_editorIndex);
}

bool Model::canUndo() const
{
    return m_readOnly ? false : m_stack.canUndo();
}

QString Model::undoMessage() const
{
    return m_stack.undoText();
}

QString Model::activeList() const
{
    return m_activeListId.isNull() ? SQL::tableLists()
                                   : m_activeListId.toString(QUuid::WithoutBraces);
}

void Model::setActiveList(const QString &identifier)
{
    if (identifier.isEmpty()) {
        return;
    }

    QUuid uuid;
    if (identifier == SQL::tableLists()) {
        uuid = QUuid();
    } else if (identifier == SQL::tableDefault()) {
        uuid = resolve(identifier);
    } else {
        uuid = QUuid::fromString(identifier);
    }
    setActiveListId(uuid);
}

bool Model::readOnly() const
{
    return m_readOnly;
}

void Model::setReadOnly(bool value)
{
    if (m_readOnly == value) {
        return;
    }
    const bool previousCanUndo = canUndo();
    m_readOnly = value;
    Q_EMIT readOnlyChanged();
    if (previousCanUndo != canUndo()) {
        Q_EMIT canUndoChanged();
    }
}

void Model::append(Item &&item)
{
    beginInsertRows(QModelIndex(), static_cast<int>(m_items.size()),
                    static_cast<int>(m_items.size()));
    m_items.append(std::move(item));
    endInsertRows();
    Q_EMIT countChanged();
}

qsizetype Model::checkedIndex(qsizetype index) const
{
    const auto begin = m_items.cbegin();
    const auto end = m_items.cend();
    const auto checked =
            std::find_if(begin + index + 1, end, [](const Item &value) { return value.checked; });
    return checked == end ? m_items.size() : std::distance(begin, checked);
}

void Model::move(qsizetype source, qsizetype destination, Save changes)
{
    if (m_readOnly || source < 0 || destination < 0 || source >= m_items.size()
        || destination >= m_items.size() || source == destination) {
        return;
    }

    if (!beginMoveRows(QModelIndex(), static_cast<int>(source), static_cast<int>(source),
                       QModelIndex(),
                       static_cast<int>(destination + (destination > source ? 1 : 0)))) {
        return;
    }

    const auto previousEditor = m_editorIndex;
    m_items.move(source, destination);
    if (m_editorIndex == source) {
        m_editorIndex = destination;
    } else if (source < m_editorIndex && destination >= m_editorIndex) {
        --m_editorIndex;
    } else if (source > m_editorIndex && destination <= m_editorIndex) {
        ++m_editorIndex;
    }
    endMoveRows();
    if (m_editorIndex != previousEditor) {
        Q_EMIT editorIndexChanged();
    }
    if (changes == Save::NO) {
        return;
    }
    save();
}

void Model::removeAll(Save changes)
{
    // Reloads may clear read-only models without changing their saved contents.
    if (m_readOnly && changes == Save::YES) {
        return;
    }

    restorePendingEdit();
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
    auto remove = std::make_unique<UndoRemove>(*this);
    for (qsizetype row = position; row < m_items.size(); ++row) {
        if (!m_items.at(row).name.isEmpty()) {
            remove->append(row);
        }
    }
    beginRemoveRows(QModelIndex(), position, static_cast<int>(m_items.size() - 1));
    m_items.removeIf([](const Item &value) { return !value.name.isEmpty(); });

    endRemoveRows();
    Q_EMIT countChanged();
    if (changes == Save::NO) {
        return;
    }
    save();
    m_stack.push(remove.release());
    Q_EMIT deletionRecorded();
}

void Model::restorePendingEdit()
{
    if (!m_pendingEdit) {
        return;
    }

    const auto editor = editorIndex();
    // A pending edit always has an existing editor placeholder.
    // NOLINTNEXTLINE(cppcoreguidelines-pro-bounds-avoid-unchecked-container-access)
    m_items[editor].uuid = QUuid();
    const auto editorModelIndex = index(static_cast<int>(editor));
    Q_EMIT dataChanged(editorModelIndex, editorModelIndex, { Qt::UserRole + 1 });
    beginInsertRows(QModelIndex(), static_cast<int>(editor), static_cast<int>(editor));
    // NOLINTNEXTLINE(bugprone-unchecked-optional-access): guarded on entry; notifications preserve it.
    m_items.insert(editor, std::move(*m_pendingEdit));
    ++m_editorIndex;
    m_pendingEdit.reset();
    endInsertRows();
    Q_EMIT countChanged();
    Q_EMIT editorIndexChanged();
}

void Model::save()
{
    if (m_readOnly) {
        return;
    }

    auto database = QSqlDatabase::database();
    if (!database.transaction()) {
        qCWarning(qshopperModelLog)
                << "Failed to start transaction while saving. Error:" << database.lastError();
        return;
    }

    const auto table = activeList();
    QSqlQuery query(database);
    if (!query.exec(SQL::deleteFrom().arg(table))) {
        qCWarning(qshopperModelLog) << "Failed to clear items from " << resolve(m_activeListId)
                                    << "(" << m_activeListId << "). Error:" << query.lastError();
        database.rollback();
        return;
    }

    query.prepare(SQL::insertTo().arg(table));
    for (const auto &item : std::as_const(m_items)) {
        // The editor is only a placeholder until the replacement is submitted.
        const auto &savedItem =
                m_pendingEdit && item.name.isEmpty() && item.uuid == m_pendingEdit->uuid
                ? *m_pendingEdit
                : item;
        if (!savedItem.name.isEmpty()) {
            query.addBindValue(savedItem.uuid);
            query.addBindValue(savedItem.name);
            query.addBindValue(savedItem.checked);

            if (!query.exec()) {
                qCWarning(qshopperModelLog)
                        << "Failed to insert item to " << resolve(m_activeListId) << "("
                        << m_activeListId << ") while saving. Error:" << query.lastError();
                database.rollback();
                return;
            }
        }
    }

    if (!database.commit()) {
        qCWarning(qshopperModelLog)
                << "Failed to commit transaction while saving error:" << database.lastError();
        database.rollback();
    }
}

bool Model::load(QUuid identifier)
{
    const auto table =
            identifier.isNull() ? SQL::tableLists() : identifier.toString(QUuid::WithoutBraces);
    QList<Item> items;
    QSqlQuery query(SQL::selectFrom().arg(table), QSqlDatabase::database());
    qCDebug(qshopperModelLog) << "Load from " << resolve(identifier) << "(" << identifier << ")";
    while (query.next()) {
        qCDebug(qshopperModelLog) << " id:" << query.value(kId) << " name:" << query.value(kName)
                                  << " checked:" << query.value(kChecked);
        items.append(Item(query.value(kName).toString(), query.value(kChecked).toBool(),
                          query.value(kId).toUuid()));
    }
    if (query.lastError().isValid()) {
        qCWarning(qshopperModelLog)
                << "Failed to load list" << table << ". Error:" << query.lastError();
        return false;
    }

    // Keep rows, editor, Undo and their list identity intact until the full read succeeds.
    m_stack.clear();
    removeAll(Save::NO);
    m_activeListId = identifier;
    for (auto &item : items) {
        append(std::move(item));
    }
    if (m_readOnly && table == SQL::tableLists()) {
        Item lists;
        lists.name = SQL::tableLists();
        append(std::move(lists));
    }
    return true;
}

QUuid Model::resolve(const QString &name)
{
    QSqlQuery query(SQL::selectFrom().arg(SQL::tableLists()), QSqlDatabase::database());
    while (query.next()) {
        if (query.value(kName).toString() == name) {
            return query.value(kId).toUuid();
        }
    }
    return { };
}

QString Model::resolve(QUuid identifier)
{
    if (identifier.isNull()) {
        return SQL::tableLists();
    }

    QSqlQuery query(SQL::selectFrom().arg(SQL::tableLists()), QSqlDatabase::database());
    while (query.next()) {
        if (query.value(kId).toUuid() == identifier) {
            return query.value(kName).toString();
        }
    }
    return { };
}

void Model::createList(const Item &row)
{
    if (!m_activeListId.isNull()) {
        return;
    }

    QSqlQuery query(QSqlDatabase::database());
    if (!query.exec(SQL::create().arg(row.uuid.toString(QUuid::WithoutBraces)))) {
        qCWarning(qshopperModelLog)
                << "Failed to create " << row.name << "(" << row.uuid.toString(QUuid::WithoutBraces)
                << ") table. Error: " << query.lastError();
        return;
    }
}

void Model::setActiveListId(QUuid identifier)
{
    if (m_activeListId == identifier) {
        return;
    }

    if (load(identifier)) {
        Q_EMIT activeListChanged();
    }
}

void Model::dropRemovedTables() const
{
    if (m_readOnly) {
        return;
    }

    QList<QUuid> activeLists;
    QSqlQuery query(SQL::selectFrom().arg(SQL::tableLists()), QSqlDatabase::database());
    while (query.next()) {
        activeLists.append(query.value(kId).toUuid());
    }
    if (query.lastError().isValid()) {
        qCWarning(qshopperModelLog)
                << "Failed to read list catalog before table cleanup. Error:" << query.lastError();
        return;
    }

    if (!query.exec(SQL::selectAllTables())) {
        qCWarning(qshopperModelLog) << "Failed to all tables. Error:" << query.lastError();
        return;
    }

    QList<QUuid> uuids;
    while (query.next()) {
        const auto identifier = query.value(kName).toUuid();
        if (!identifier.isNull()) {
            uuids.append(identifier);
        }
    }

    for (const auto &uuid : uuids) {
        if (!activeLists.contains(uuid)) {
            qCDebug(qshopperModelLog) << "Drop table " << uuid;
            if (!query.exec(SQL::drop().arg(uuid.toString(QUuid::WithoutBraces)))) {
                qCWarning(qshopperModelLog)
                        << "Failed to drop table " << uuid << ". Error:" << query.lastError();
            }
        }
    }
}
