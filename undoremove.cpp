#include "undoremove.h"

UndoRemove::UndoRemove(Model &model, Item &&item, size_t index)
    : m_model(model),
      m_item(std::move(item)),
      m_index(index)
{
}

void UndoRemove::undo()
{
    m_model.insert(m_index, std::move(m_item));
}
