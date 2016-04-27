#include "model.h"
#include <QtCore/QDataStream>
#include <QtCore/QFile>
#include <QtCore/QStandardPaths>
#include <QtCore/QDir>

inline bool operator==(const Item& left, const Item& right)
{
    return left.name == right.name && left.checked == right.checked;
}

Model::Model(QObject *parent) Q_DECL_NOTHROW
    : QAbstractListModel(parent)
{
    load();
    QVector<Item>::iterator end = m_items.end();
    m_items.erase(std::remove_if(m_items.begin(), end, [](const Item &value) { return value.name.isEmpty(); }), end);
}

QVariant Model::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()
      || index.row() < 0
      || index.row() >= rowCount()) {
        return QVariant();
    }

    if (role == Qt::DisplayRole) {
        return m_items[index.row()].name;
    } else if (role == Qt::CheckStateRole) {
        return m_items[index.row()].checked;
    } else if (role == Qt::EditRole) {
        return m_items[index.row()].name.isEmpty();
    } else {
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
    Q_EMIT dataChanged(index, index, {{ Qt::CheckStateRole }});
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

void Model::insert(int index, const QString &name)
{
    const int bound = qBound(0, index, m_items.count());
    beginInsertRows(QModelIndex(), bound, bound);
    m_items.insert(bound, 1, Item(name));
    endInsertRows();
    Q_EMIT countChanged();
    save();
}

void Model::remove(int index)
{
    if (index < 0 || index >= m_items.count()) {
        return;
    }

    beginRemoveRows(QModelIndex(), index, index);
    m_items.remove(index);
    endRemoveRows();
    Q_EMIT countChanged();
    save();
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
    QVector<Item>::iterator begin = m_items.begin();
    QVector<Item>::iterator end = m_items.end();
    QVector<Item>::iterator first = std::find_if(begin, end, [] (const Item& value) { return value.checked; });

    if (first == end) {
        return;
    }

    const int position = std::distance(begin, first);
    beginRemoveRows(QModelIndex(), position, m_items.count() - 1);
    m_items.erase(std::remove_if(begin, end, [](const Item &value) { return value.checked; }), end);
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
    Item moved = m_items.takeAt(source);
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
    while (editorIndex() != -1) {
        remove(editorIndex());
    }
}

void Model::moveEditor(int destination, bool force)
{
    const int source = editorIndex();
    if (source == -1) {
        return;
    }

    destination = qBound(0, destination, m_items.count());
    move(source, destination + (!force && source >= destination && source != 1 ? 1 : 0));
    Q_EMIT editorIndexChanged();
}

int Model::editorIndex() const
{
    QVector<Item>::const_iterator begin = m_items.constBegin();
    QVector<Item>::const_iterator end = m_items.constEnd();
    QVector<Item>::const_iterator editor = std::find_if(begin, end, [](const Item &value) { return value.name.isEmpty(); });
    return editor == end ? -1 : std::distance(begin, editor);
}

void Model::append(const Item &item)
{
    beginInsertRows(QModelIndex(), m_items.count(), m_items.count());
    m_items.append(item);
    endInsertRows();
    Q_EMIT countChanged();
}

int Model::checkedIndex(int index) const
{
    QVector<Item>::const_iterator begin = m_items.constBegin();
    QVector<Item>::const_iterator end = m_items.constEnd();
    QVector<Item>::const_iterator checked = std::find_if(begin + index + 1, end, [](const Item &value) { return value.checked; });
    return checked == end ? m_items.count() : std::distance(begin, checked);
}

void Model::save()
{
    QString path = QStandardPaths::writableLocation(QStandardPaths::DataLocation);
    QDir dir(path);
    if (!dir.exists() && !dir.mkpath(path)) {
        qWarning("Could not create dir");
        return;
    }

    QFile file(QString("%1/store.dat").arg(path));
    if (!file.open(QIODevice::WriteOnly | QIODevice::Truncate)) {
        qWarning("On save couldn't open file.");
        return;
    }

    QDataStream out(&file);
    for (const Item &item : m_items) {
        out << item.name << item.checked;
    }
    file.close();
}

void Model::load()
{
    m_items.clear();

    QString path = QStandardPaths::writableLocation(QStandardPaths::DataLocation);
    QFile file(QString("%1/store.dat").arg(path));
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning("On load couldn't open file.");
        return;
    }

    QDataStream in(&file);
    while(!in.atEnd()) {
        QString name; bool checked;
        in >> name >> checked;
        append(Item(name, checked));
    }
    file.close();
}
