#ifndef UNDOREMOVE_H
#define UNDOREMOVE_H

#include <QtCore/QtTypes>
#include <QtCore/QList>
#include <QtCore/QUuid>
#include <QtGui/QUndoCommand>

#include <model.h>

class UndoRemove : public QUndoCommand
{
public:
    explicit UndoRemove(Model &model);
    void undo() override;
    void append(qsizetype index);

private:
    struct RemovedItem
    {
        Item item;
        qsizetype index;
        QUuid before;
        QUuid after;
    };

    void updateText();
    [[nodiscard]] qsizetype findRow(QUuid identifier) const;
    [[nodiscard]] qsizetype restoreIndex(const RemovedItem &removed) const;

    Model &m_model;
    QList<RemovedItem> m_items;
};

#endif // UNDOREMOVE_H
