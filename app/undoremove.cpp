#include "undoremove.h"

#include <utility>

#include <QtCore/QtTypes>
#include <QtCore/QCoreApplication>
#include <QtCore/QUuid>
#include <QtGui/QUndoCommand>

#include <model.h>

UndoRemove::UndoRemove(Model &model) : m_model(model) { }

void UndoRemove::undo()
{
    while (!m_items.empty()) {
        auto removed = m_items.takeLast();
        // Restoring next to an active editor must not submit its pending draft.
        m_model.insert(restoreIndex(removed), std::move(removed.item), false);
    }
}

qsizetype UndoRemove::findRow(QUuid identifier) const
{
    if (!identifier.isNull()) {
        for (qsizetype row = 0; row < m_model.m_items.size(); ++row) {
            if (m_model.m_items.at(row).uuid == identifier) {
                return row;
            }
        }
    }
    return -1;
}

qsizetype UndoRemove::restoreIndex(const RemovedItem &removed) const
{
    const auto before = findRow(removed.before);
    const auto after = findRow(removed.after);
    if (after >= 0) {
        // If newer moves reversed the neighbors, restore between them.
        return before >= after ? after + 1 : after;
    }
    if (before >= 0) {
        return before + 1;
    }
    qsizetype row = 0;
    qsizetype position = 0;
    while (row < m_model.m_items.size()
           && (position < removed.index || row == m_model.m_editorIndex)) {
        if (row != m_model.m_editorIndex) {
            ++position;
        }
        ++row;
    }
    return row;
}

int UndoRemove::id() const
{
    return 1;
}

bool UndoRemove::mergeWith(const QUndoCommand *command)
{
    const auto *removed = dynamic_cast<const UndoRemove *>(command);
    if (removed == nullptr || &removed->m_model != &m_model) {
        return false;
    }
    m_items.append(removed->m_items);
    updateText();
    return true;
}

void UndoRemove::append(qsizetype index)
{
    RemovedItem removed{ .item = m_model.m_items.at(index), .index = index };
    if (m_model.m_editorIndex >= 0 && m_model.m_editorIndex < index) {
        --removed.index;
    }
    for (auto row = index - 1; row >= 0; --row) {
        if (!m_model.m_items.at(row).uuid.isNull()) {
            removed.before = m_model.m_items.at(row).uuid;
            break;
        }
    }
    for (auto row = index + 1; row < m_model.m_items.size(); ++row) {
        if (!m_model.m_items.at(row).uuid.isNull()) {
            removed.after = m_model.m_items.at(row).uuid;
            break;
        }
    }
    m_items.append(std::move(removed));
    updateText();
}

void UndoRemove::updateText()
{
    setText(m_items.size() == 1
                    ? QCoreApplication::translate("UndoBar", "%1 removed")
                              .arg(m_items.constFirst().item.name)
                    : QCoreApplication::translate("UndoBar", "%n items removed", nullptr,
                                                  static_cast<int>(m_items.size())));
}
