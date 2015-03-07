#include "model.h"
#include <QtCore/QDataStream>
#include <QtCore/QFile>
#include <QtCore/QStandardPaths>
#include <QtCore/QDir>

Model::Model(QObject *parent)
    : QAbstractListModel(parent)
{
    load();
    removeEditor();
}

int Model::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent);
    return m_items.count();
}

QVariant Model::data(const QModelIndex &index, int role) const
{
    if (!index.isValid()
      || index.row() < 0
      || index.row() >= rowCount()) {
        return QVariant();
    }

    if (role == Qt::DisplayRole) {
        return m_items[index.row()];
    } else if (role == Qt::CheckStateRole) {
        return m_selection[index.row()];
    } else if (role == Qt::EditRole) {
        return m_editor[index.row()];
    } else
        return QVariant();
}

bool Model::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if (!index.isValid()
      || index.row() < 0
      || index.row() >= rowCount()
      || role != Qt::CheckStateRole) {
        return false;
    }

    bool state = value.toBool();
    if (m_selection[index.row()] == state) {
        return false;
    }

    m_selection[index.row()] = state;
    Q_EMIT dataChanged(index, index);
    return true;
}

QHash<int, QByteArray> Model::roleNames() const
{
    QHash<int, QByteArray> names;
    names.insert(Qt::DisplayRole, "itemText");
    names.insert(Qt::CheckStateRole, "selected");
    names.insert(Qt::EditRole, "editor");
    return names;
}

int Model::count() const
{
    return m_items.count();
}

int Model::editorIndex() const
{
    return m_editor.indexOf(true);
}

void Model::append(const QString &item)
{
    beginInsertRows(QModelIndex(), m_items.count(), m_items.count());
    m_items.append(item);
    m_selection.append(false);
    m_editor.append(false);
    endInsertRows();
    Q_EMIT countChanged();
    save();
}

void Model::insert(int index, const QString &item)
{
    int boundIndex = qBound(0, index, m_items.count());
    beginInsertRows(QModelIndex(), boundIndex, boundIndex);
    m_items.insert(boundIndex, item);
    m_selection.insert(boundIndex, false);
    m_editor.insert(boundIndex, false);
    endInsertRows();
    Q_EMIT countChanged();
    save();
}

void Model::remove(const QString &item)
{
    remove(m_items.indexOf(item));
}

void Model::remove(int index)
{
    if (index < 0 || index >= m_items.count()) {
        return;
    }

    beginRemoveRows(QModelIndex(), index, index);
    m_items.removeAt(index);
    m_selection.removeAt(index);
    m_editor.removeAt(index);
    endRemoveRows();
    Q_EMIT countChanged();
    save();
}

void Model::removeAll()
{
    beginRemoveRows(QModelIndex(), 0, m_items.count() - 1);
    m_items.clear();
    m_selection.clear();
    m_editor.clear();
    endRemoveRows();
    Q_EMIT countChanged();
    save();
}

void Model::removeSelected()
{
    while (m_selection.contains(true)) {
        remove(m_selection.indexOf(true));
    }
}

void Model::reset()
{
    for (int index = 0; index < m_selection.count(); ++index) {
        setSelected(index, false);
    }
}

void Model::move(int source, int destination)
{
    if (source == destination) {
        return;
    }

    beginMoveRows(QModelIndex(), source, source, QModelIndex(), destination + (destination > source ? 1 : 0));
    m_items.move(source, destination);
    m_selection.move(source, destination);
    m_editor.move(source, destination);
    endMoveRows();
    save();
}

void Model::addEditor()
{
    if (m_editor.contains(true)) {
        return;
    }

    beginInsertRows(QModelIndex(), 0, 0);
    m_items.insert(0, "editor");
    m_selection.insert(0, false);
    m_editor.insert(0, true);
    endInsertRows();
    Q_EMIT countChanged();
    Q_EMIT editorIndexChanged();
}

void Model::removeEditor()
{
    while (m_editor.contains(true)) {
        remove(m_editor.indexOf(true));
    }
    Q_EMIT editorIndexChanged();
}

void Model::moveEditor(int index, bool force)
{
    int editorIndex = m_editor.indexOf(true);
    int moveTo = qBound(0, index, count());
    move(editorIndex, moveTo + (!force && editorIndex >= index && editorIndex != 1 ? 1 : 0));
    Q_EMIT editorIndexChanged();
}

void Model::setSelected(int index, bool selected)
{
    if (!setData(this->index(index, 0), selected, Qt::CheckStateRole)) {
        return;
    }

    if (m_selection[index])
        moveToEnd(index);
    else
        moveToStart(index);
    save();
}

void Model::toggleSelected(int index)
{
    if (!setData(this->index(index ,0), !m_selection[index], Qt::CheckStateRole)) {
        return;
    }

    if (m_selection[index])
        moveToEnd(index);
    else
        moveToStart(index);
    save();
}

void Model::moveToEnd(int from)
{
    int to = m_selection.count(true) == 1 ? m_selection.count() - 1 : m_selection.indexOf(true, from + 1) - 1;
    if (from != to) {
        beginMoveRows(QModelIndex(), from, from, QModelIndex(), to + 1);
        m_items.move(from, to);
        m_selection.move(from, to);
        m_editor.move(from, to);
        endMoveRows();
    }
}

void Model::moveToStart(int from)
{
    if (from != 0) {
        beginMoveRows(QModelIndex(), from, from, QModelIndex(), 0);
        m_items.move(from, 0);
        m_selection.move(from, 0);
        m_editor.move(from, 0);
        endMoveRows();
    }
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
    out << m_items.count();
    for (int index = 0; index < m_items.count(); ++index) {
        out << m_items[index] << m_selection[index] << m_editor[index];
    }
    file.close();
}

void Model::load()
{
    m_items.clear();
    m_selection.clear();
    int count = 0;

    QString path = QStandardPaths::writableLocation(QStandardPaths::DataLocation);
    QFile file(QString("%1/store.dat").arg(path));
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning("On load couldn't open file.");
        return;
    }

    QDataStream in(&file);
    in >> count;
    for (int index = 0; index < count; ++index) {
        QString item; bool selected; bool editor;
        in >> item >> selected >> editor;
        m_items.append(item);
        m_selection.append(selected);
        m_editor.append(editor);
    }
    file.close();
}
