#include "undoremove.h"

UndoRemove::UndoRemove(Model &model)
    : m_model(model)
{
}

void UndoRemove::undo()
{
    while(!m_items.empty()) {
        m_model.insert(m_indexs.takeFirst(), std::move(m_items.takeFirst()));
    }
}

void UndoRemove::append(Item &&item, qsizetype index)
{
    m_items.append(item);
    m_indexs.append(index);
}

void UndoRemove::append(const Item &item, qsizetype index)
{
    m_items.append(item);
    m_indexs.append(index);
}
