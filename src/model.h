#ifndef MODEL_H
#define MODEL_H

#include <QtCore/QAbstractListModel>

struct Item {
    Item() : checked(false) {}
    Item(const QString &name) : name(name), checked(false) {}
    Item(const QString &name, bool checked) : name(name), checked(checked) {}
    QString name;
    bool checked : 1;
};

Q_DECLARE_TYPEINFO(Item, Q_MOVABLE_TYPE);

class Model : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)
    Q_PROPERTY(int editorIndex READ editorIndex NOTIFY editorIndexChanged)

public:
    explicit Model(QObject *parent = 0) Q_DECL_NOTHROW;

    // from QAbstractItemModel
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const Q_DECL_OVERRIDE;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) Q_DECL_OVERRIDE;
    QHash<int, QByteArray> roleNames() const Q_DECL_OVERRIDE;
    int rowCount(const QModelIndex &parent = QModelIndex()) const Q_DECL_OVERRIDE;

    Q_INVOKABLE void insert(int index, const QString &name);
    Q_INVOKABLE void remove(int index);
    Q_INVOKABLE void removeAll();
    Q_INVOKABLE void removeChecked();
    Q_INVOKABLE void setChecked(int index, bool checked);
    Q_INVOKABLE void toggleChecked(int index);
    Q_INVOKABLE void reset();
    Q_INVOKABLE void move(int source, int destination);
    Q_INVOKABLE void addEditor();
    Q_INVOKABLE void removeEditor();
    Q_INVOKABLE void moveEditor(int destination, bool force = false);

    int editorIndex() const;

Q_SIGNALS:
    void countChanged();
    void editorIndexChanged();

private:
    void append(const Item &item);
    int checkedIndex(int index) const;
    void save();
    void load();

    QVector<Item> m_items;
};

#endif // MODEL_H
