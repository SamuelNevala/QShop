#ifndef UNDOREMOVE_H
#define UNDOREMOVE_H

#include <model.h>
#include <QUndoCommand>

class UndoRemove : public QUndoCommand
{
public:
    UndoRemove(Model& model, Item &&item, size_t index);
    void undo() override;
private:
    Model& m_model;
    Item m_item;
    const size_t m_index;
};

#endif // UNDOREMOVE_H
