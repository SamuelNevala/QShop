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
    int rowCount(const QModelIndex & parent = QModelIndex()) const;
    QVariant data(const QModelIndex & index, int role = Qt::DisplayRole) const;
    QHash<int, QByteArray> roleNames() const;

    int count() const;

    Q_INVOKABLE void setSelected(int index, bool selected);
    Q_INVOKABLE void toggleSelected(int index);
    Q_INVOKABLE void append(QString item);
    Q_INVOKABLE void insert(int index, QString item);
    Q_INVOKABLE void remove(int index);
    Q_INVOKABLE void remove(QString item);
    Q_INVOKABLE void removeAll();
    Q_INVOKABLE void reset();
    Q_INVOKABLE void move(int source, int destination);
    Q_INVOKABLE void addEditor();
    Q_INVOKABLE void removeEditor();

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
    QHash<int, QByteArray> m_roleNames;
};

#endif // MODEL_H
