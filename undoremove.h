#ifndef UNDOREMOVE_H
#define UNDOREMOVE_H

#include <model.h>
#include <QUndoCommand>

class UndoRemove : public QUndoCommand
{
public:
    UndoRemove(Model& model);
    void undo() override;
    void append(Item &&item, qsizetype index);
    void append(const Item &item, qsizetype index);
private:
    Model& m_model;
    QVector<Item> m_items;
    QVector<qsizetype> m_indexs;
};

#endif // UNDOREMOVE_H
