#ifndef UNDOREMOVE_H
#define UNDOREMOVE_H

#include <QtCore/QtTypes>
#include <QtCore/QList>
#include <QtGui/QUndoCommand>

#include <model.h>

class UndoRemove : public QUndoCommand
{
public:
    explicit UndoRemove(Model& model);
    void undo() override;
    void append(Item &&item, qsizetype index);
    void append(const Item &item, qsizetype index);
private:
    Model& m_model;
    QList<Item> m_items;
    QList<qsizetype> m_indexs;
};

#endif // UNDOREMOVE_H
