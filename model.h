#ifndef MODEL_H
#define MODEL_H

#include <QtCore/QAbstractListModel>
#include <QtCore/QUuid>
#include <QtGui/QUndoStack>
#include <QtQml/QQmlParserStatus>
#include <QtQmlIntegration>


static const QString kCreate = QStringLiteral("CREATE TABLE IF NOT EXISTS \"%1\" ("
                                                  "id TEXT PRIMARY KEY NOT NULL,"
                                                  "name TEXT NOT NULL,"
                                                  "checked INTEGER NOT NULL DEFAULT 0)");
static const QString kDrop = QStringLiteral("DROP TABLE IF EXISTS \"%1\"");
static const QString kDeleteFrom = QStringLiteral("DELETE FROM \"%1\"");
static const QString kInsertTo = QStringLiteral("INSERT INTO \"%1\" (id, name, checked) VALUES (?, ?, ?)");
static const QString kSelectFrom = QStringLiteral("SELECT name, checked, id FROM \"%1\"");
static const QString kSelectFromAscending = QStringLiteral("SELECT name, checked, id FROM \"%1\" ORDER BY name ASC");
static const QString kSelectAllTables = QStringLiteral("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name;");
static const QString kListsTable = QStringLiteral("lists");
static const QString kDefaultTable = QStringLiteral("default");

struct Item
{
    Item() = default;
    Item(const QString &name) : name(name), uuid(QUuid::createUuid()) {}
    Item(const QString &name, bool checked) : name(name), checked(checked), uuid(QUuid::createUuid()) {}
    Item(const QString &name, bool checked, const QUuid &uuid) : name(name), checked(checked), uuid(uuid) {}
    Item(const Item&) = default;
    Item& operator=(const Item&) = default;
    Item(Item&&) noexcept = default;
    Item& operator = (Item&&) noexcept = default;
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
    enum class Save { YES, NO };
    Q_ENUM(Save);

    enum class Force { YES, NO };
    Q_ENUM(Force);

    explicit Model(QObject *parent = 0) Q_DECL_NOTHROW;

    // from QAbstractListModel
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const Q_DECL_OVERRIDE;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) Q_DECL_OVERRIDE;
    QHash<int, QByteArray> roleNames() const Q_DECL_OVERRIDE;
    int rowCount(const QModelIndex &parent = QModelIndex()) const Q_DECL_OVERRIDE;

    // // from QQmlParserStatus
    void classBegin() Q_DECL_OVERRIDE;
    void componentComplete() Q_DECL_OVERRIDE;

    void insert(qsizetype index, Item &&item);
    Q_INVOKABLE void insert(qsizetype index, const QString &name);
    Q_INVOKABLE void remove(qsizetype index);
    Q_INVOKABLE QString editItem(qsizetype index);
    Q_INVOKABLE void removeAll();
    Q_INVOKABLE void removeChecked();
    Q_INVOKABLE void setChecked(qsizetype index, bool checked);
    Q_INVOKABLE void toggleChecked(qsizetype index);
    Q_INVOKABLE void reset();
    Q_INVOKABLE void move(qsizetype source, qsizetype destination);
    Q_INVOKABLE void addEditor();
    Q_INVOKABLE void removeEditor();
    Q_INVOKABLE void moveEditor(qsizetype destination, Force force = Force::NO);
    Q_INVOKABLE void undo();
    Q_INVOKABLE void clearUndoStack();
    Q_INVOKABLE void reload();
    qsizetype editorIndex() const;
    bool canUndo() const;
    QString activeList() const;
    void setActiveList(const QString &id);
    bool readOnly() const;
    void setReadOnly(bool value);

Q_SIGNALS:
    void canUndoChanged();
    void countChanged();
    void editorIndexChanged();
    void activeListChanged();
    void readOnlyChanged();

private:
    void append(Item &&item);
    qsizetype checkedIndex(qsizetype index) const;
    void move(qsizetype source, qsizetype destination, Save changes);
    void removeAll(Save changes);
    void save();
    void load();
    QUuid resolve(const QString &name);
    QString resolve(const QUuid &id);
    void createList(const Item &row);
    const QUuid &activeListId() const;
    void setActiveListId(const QUuid &id);
    void dropRemovedTables();

    QUuid m_active_list_id;
    QVector<Item> m_items;
    QUndoStack m_stack;
    bool m_read_only { false };
};

#endif // MODEL_H
