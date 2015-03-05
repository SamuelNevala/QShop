#ifndef MODEL_H
#define MODEL_H

#include <QAbstractListModel>

class Model : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    explicit Model(QObject *parent = 0);

    // from QAbstractItemModel
    int rowCount(const QModelIndex &parent = QModelIndex()) const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;
    QHash<int, QByteArray> roleNames() const;
    bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole);

    int count() const;

    Q_INVOKABLE void setSelected(int index, bool selected);
    Q_INVOKABLE void toggleSelected(int index);
    Q_INVOKABLE void append(const QString &item);
    Q_INVOKABLE void insert(int index, const QString &item);
    Q_INVOKABLE void remove(int index);
    Q_INVOKABLE void remove(const QString &item);
    Q_INVOKABLE void removeAll();
    Q_INVOKABLE void removeSelected();
    Q_INVOKABLE void reset();
    Q_INVOKABLE void move(int source, int destination);
    Q_INVOKABLE void addEditor();
    Q_INVOKABLE void removeEditor();
    Q_INVOKABLE void moveEditor(int index, bool force = false);

Q_SIGNALS:
    void countChanged();

private:
    void moveToEnd(int from);
    void moveToStart(int from);
    void save();
    void load();

    QList<QString> m_items;
    QList<bool> m_selection;
    QList<bool> m_editor;
};

#endif // MODEL_H
