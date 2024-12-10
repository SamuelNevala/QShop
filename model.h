#ifndef MODEL_H
#define MODEL_H

#include <QtCore/QAbstractListModel>
#include <QtCore/QUuid>
#include <QtGui/QUndoStack>
#include <QtQmlIntegration>

struct Item
{
    Item() = default;
    Item(const QString &name) : name(name), uuid(QUuid::createUuid()) {}
    Item(const QString &name, bool checked) : name(name), checked(checked), uuid(QUuid::createUuid()) {}
    Item(const Item&) = default;
    Item& operator=(const Item&) = default;
    Item(Item&&) noexcept = default;
    Item& operator = (Item&&) noexcept = default;
    QString name;
    bool checked = false;
    QUuid uuid;
};

Q_DECLARE_TYPEINFO(Item, Q_MOVABLE_TYPE);

class Model : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(int editorIndex READ editorIndex NOTIFY editorIndexChanged)
    Q_PROPERTY(bool canUndo READ canUndo NOTIFY canUndoChanged)

public:
    explicit Model(QObject *parent = 0) Q_DECL_NOTHROW;

    // from QAbstractListModel
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const Q_DECL_OVERRIDE;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) Q_DECL_OVERRIDE;
    QHash<int, QByteArray> roleNames() const Q_DECL_OVERRIDE;
    int rowCount(const QModelIndex &parent = QModelIndex()) const Q_DECL_OVERRIDE;

    void insert(int index, Item &&item);
    Q_INVOKABLE void insert(int index, const QString &name);
    Q_INVOKABLE void remove(int index);
    Q_INVOKABLE QString editItem(int index);
    Q_INVOKABLE void removeAll();
    Q_INVOKABLE void removeChecked();
    Q_INVOKABLE void setChecked(int index, bool checked);
    Q_INVOKABLE void toggleChecked(int index);
    Q_INVOKABLE void reset();
    Q_INVOKABLE void move(int source, int destination);
    Q_INVOKABLE void addEditor();
    Q_INVOKABLE void removeEditor();
    Q_INVOKABLE void moveEditor(int destination, bool force = false);
    Q_INVOKABLE void undo();
    Q_INVOKABLE void clearUndoStack();
    int editorIndex() const;
    bool canUndo() const;

Q_SIGNALS:
    void canUndoChanged();
    void countChanged();
    void editorIndexChanged();

private:
    void append(Item &&item);
    int checkedIndex(int index) const;
    void doMove(int source, int destination);
    void doSetChecked(int index, bool checked);
    void save();
    void load();

    QVector<Item> m_items;
    QUndoStack m_stack;
};

#endif // MODEL_H
