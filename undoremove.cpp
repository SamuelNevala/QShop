#include "undoremove.h"

#include <utility>

#include <QtCore/QtTypes>

#include <model.h>

UndoRemove::UndoRemove(Model &model) : m_model(model) { }

void UndoRemove::undo()
{
    while (!m_items.empty()) {
        auto removed = m_items.takeFirst();
        m_model.insert(removed.index, std::move(removed.item));
    }
}

void UndoRemove::append(Item &&item, qsizetype index)
{
    m_items.append(RemovedItem{ .item = std::move(item), .index = index });
}

void UndoRemove::append(const Item &item, qsizetype index)
{
    m_items.append(RemovedItem{ .item = item, .index = index });
}
