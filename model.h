#ifndef MODEL_H
#define MODEL_H

#include <QtCore/QAbstractListModel>
#include <QtCore/QtCompilerDetection>
#include <QtCore/QObject>
#include <QtCore/QHash>
#include <QtCore/QString>
#include <QtCore/QTypeInfo>
#include <QtCore/QtTypes>
#include <QtCore/QList>
#include <QtCore/qtmetamacros.h>
#include <QtCore/qnamespace.h>
#include <QtCore/QUuid>
#include <QtGui/QUndoStack>
#include <QtQml/QQmlParserStatus>
#include <QtQmlIntegration/qqmlintegration.h>
// #include <QtQmlIntegration>
#include <optional>
#include <utility>

namespace SQL {
static const QString &create()
{
    static const QString kCreate = QStringLiteral("CREATE TABLE IF NOT EXISTS \"%1\" ("
                                                  "id TEXT PRIMARY KEY NOT NULL,"
                                                  "name TEXT NOT NULL,"
                                                  "checked INTEGER NOT NULL DEFAULT 0)");
    return kCreate;
}

static const QString &drop()
{
    static const QString kDrop = QStringLiteral("DROP TABLE IF EXISTS \"%1\"");
    return kDrop;
}

static const QString &deleteFrom()
{
    static const QString kDeleteFrom = QStringLiteral("DELETE FROM \"%1\"");
    return kDeleteFrom;
}

static const QString &insertTo()
{
    static const QString kInsertTo =
            QStringLiteral("INSERT INTO \"%1\" (id, name, checked) VALUES (?, ?, ?)");
    return kInsertTo;
}

static const QString &selectFrom()
{
    static const QString kSelectFrom = QStringLiteral("SELECT name, checked, id FROM \"%1\"");
    return kSelectFrom;
}

static const QString &selectAllTables()
{
    static const QString kSelectAllTables =
            QStringLiteral("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;");
    return kSelectAllTables;
}

static const QString &tableLists()
{
    static const QString kListsTable = QStringLiteral("lists");
    return kListsTable;
}

static const QString &tableDefault()
{
    static const QString kDefaultTable = QStringLiteral("default");
    return kDefaultTable;
}
} // namespace SQL

struct Item
{
    Item() = default;
    explicit Item(QString name) : name(std::move(name)), uuid(QUuid::createUuid()) { }
    Item(QString name, bool checked)
        : name(std::move(name)), checked(checked), uuid(QUuid::createUuid())
    {
    }
    Item(QString name, bool checked, QUuid uuid)
        : name(std::move(name)), checked(checked), uuid(uuid)
    {
    }
    QString name;
    bool checked = false;
    QUuid uuid;
};

Q_DECLARE_TYPEINFO(Item, Q_MOVABLE_TYPE);

class Model : public QAbstractListModel, public QQmlParserStatus
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(int editorIndex READ editorIndex NOTIFY editorIndexChanged)
    Q_PROPERTY(bool canUndo READ canUndo NOTIFY canUndoChanged)
    Q_PROPERTY(bool readOnly READ readOnly WRITE setReadOnly NOTIFY readOnlyChanged)
    Q_PROPERTY(QString activeList READ activeList WRITE setActiveList NOTIFY activeListChanged)
    Q_INTERFACES(QQmlParserStatus)

public:
    enum class Save : quint8 { YES, NO };
    Q_ENUM(Save);

    enum class Force : quint8 { YES, NO };
    Q_ENUM(Force);

    explicit Model(QObject *parent = nullptr) Q_DECL_NOTHROW;

    // from QAbstractListModel
    [[nodiscard]] QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const
            Q_DECL_OVERRIDE;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole)
            Q_DECL_OVERRIDE;
    [[nodiscard]] QHash<int, QByteArray> roleNames() const Q_DECL_OVERRIDE;
    [[nodiscard]] int rowCount(const QModelIndex &parent = QModelIndex()) const Q_DECL_OVERRIDE;

    // // from QQmlParserStatus
    void classBegin() Q_DECL_OVERRIDE;
    void componentComplete() Q_DECL_OVERRIDE;

    void insert(qsizetype index, Item &&item);
    Q_INVOKABLE void insert(qsizetype index, const QString &name);
    Q_INVOKABLE void remove(qsizetype index);
    // Requires an editor; removing it or successfully reloading cancels an unfinished edit.
    Q_INVOKABLE QString editItem(qsizetype index);
    Q_INVOKABLE void removeAll();
    Q_INVOKABLE void removeChecked();
    Q_INVOKABLE void setChecked(qsizetype index, bool checked);
    Q_INVOKABLE void toggleChecked(qsizetype index);
    Q_INVOKABLE void reset();
    Q_INVOKABLE void move(qsizetype source, qsizetype destination);
    Q_INVOKABLE void addEditor();
    Q_INVOKABLE void removeEditor();
    Q_INVOKABLE void moveEditor(qsizetype destination, Model::Force force = Model::Force::NO);
    Q_INVOKABLE void undo();
    Q_INVOKABLE void clearUndoStack();
    Q_INVOKABLE void reload();
    [[nodiscard]] int editorIndex() const;
    [[nodiscard]] bool canUndo() const;
    [[nodiscard]] QString activeList() const;
    void setActiveList(const QString &identifier);
    [[nodiscard]] bool readOnly() const;
    void setReadOnly(bool value);

Q_SIGNALS:
    void canUndoChanged();
    void countChanged();
    void editorIndexChanged();
    void activeListChanged();
    void readOnlyChanged();

private:
    void append(Item &&item);
    [[nodiscard]] qsizetype checkedIndex(qsizetype index) const;
    void move(qsizetype source, qsizetype destination, Save changes);
    void removeAll(Save changes);
    void restorePendingEdit();
    void save();
    bool load(QUuid identifier);
    static QUuid resolve(const QString &name);
    static QString resolve(QUuid identifier);
    void createList(const Item &row);
    void setActiveListId(QUuid identifier);
    void dropRemovedTables() const;

    QUuid m_activeListId;
    QList<Item> m_items;
    std::optional<Item> m_pendingEdit;
    QUndoStack m_stack;
    qsizetype m_editorIndex{ -1 };
    bool m_readOnly{ false };
};

#endif // MODEL_H
