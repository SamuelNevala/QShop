#ifndef UNDOREMOVE_H
#define UNDOREMOVE_H

#include <QtCore/QtTypes>
#include <QtCore/QList>
#include <QtGui/QUndoCommand>

#include <model.h>

class UndoRemove : public QUndoCommand
{
public:
    explicit UndoRemove(Model &model);
    void undo() override;
    void append(Item &&item, qsizetype index);
    void append(const Item &item, qsizetype index);

private:
    struct RemovedItem
    {
        Item item;
        qsizetype index;
    };

    Model &m_model;
    QList<RemovedItem> m_items;
};

#endif // UNDOREMOVE_H
