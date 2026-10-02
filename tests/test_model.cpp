#include <QtTest/QtTest>
#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlQuery>
#include <QtSql/QSqlError>
#include <limits>
#include "model.h"

class ModelTest : public QObject
{
    Q_OBJECT
    QString defaultId;

    void loadItems(Model &model) const
    {
        model.classBegin();
        model.setActiveList("default");
        model.componentComplete();
    }
    static QStringList names(const Model &model)
    {
        QStringList result;
        for (int row = 0; row < model.rowCount(); ++row)
        {
            result.append(model.data(model.index(row)).toString());
        }
        return result;
    }
    static QString id(const Model &model, int row)
    {
        return model.data(model.index(row), Qt::UserRole + 1).toString();
    }

private slots:
    void init()
    {
        // Fresh default connection per test; never opens the user's database.
        auto database = QSqlDatabase::addDatabase("QSQLITE");
        database.setDatabaseName(":memory:");
        QVERIFY2(database.open(), qPrintable(database.lastError().text()));
        QSqlQuery query(database);
        QVERIFY(query.exec(SQL::create().arg("lists")));
        defaultId = QUuid::createUuid().toString(QUuid::WithoutBraces);
        QVERIFY(query.exec(SQL::create().arg(defaultId)));
        query.prepare(SQL::insertTo().arg("lists"));
        query.addBindValue(defaultId);
        query.addBindValue("default");
        query.addBindValue(false);
        QVERIFY(query.exec());
    }
    void cleanup()
    {
        {
            auto database = QSqlDatabase::database();
            database.close();
        }
        QSqlDatabase::removeDatabase(QSqlDatabase::defaultConnection);
    }

    void roles_and_invalid_indexes()
    {
        Model model;
        loadItems(model);
        QCOMPARE(model.rowCount(), 0);
        QCOMPARE(model.editorIndex(), -1);
        QCOMPARE(model.activeList(), defaultId);
        QVERIFY(!model.canUndo());
        QVERIFY(!model.readOnly());
        QVERIFY(!model.data({}).isValid());
        QVERIFY(!model.setData({}, true, Qt::CheckStateRole));
        model.remove(-1); model.remove(100); model.setChecked(-1, true);
        model.insert(0, "Milk");
        QCOMPARE(model.rowCount(model.index(0)), 0);
        QCOMPARE(model.data(model.index(0)).toString(), "Milk");
        QVERIFY(!model.data(model.index(0), Qt::CheckStateRole).toBool());
        QVERIFY(!model.data(model.index(0), Qt::EditRole).toBool());
        QVERIFY(!QUuid(id(model, 0)).isNull());
        QVERIFY(!model.data(model.index(0), -99).isValid());
        QVERIFY(!model.setData(model.index(0), "Other", Qt::EditRole));
        QCOMPARE(model.roleNames().value(Qt::DisplayRole), "name");
        QCOMPARE(model.roleNames().value(Qt::CheckStateRole), "checked");
        QCOMPARE(model.roleNames().value(Qt::EditRole), "editor");
        QCOMPARE(model.roleNames().value(Qt::UserRole + 1), "id");
    }

    void editor_role_uses_explicit_index()
    {
        Model model;
        loadItems(model);
        model.insert(0, "");
        QCOMPARE(model.editorIndex(), -1);
        QVERIFY(!model.data(model.index(0), Qt::EditRole).toBool());

        model.addEditor();
        QCOMPARE(model.editorIndex(), 0);
        QVERIFY(model.data(model.index(0), Qt::EditRole).toBool());
        QVERIFY(!model.data(model.index(1), Qt::EditRole).toBool());
        QVERIFY(!model.setData(model.index(0), true, Qt::CheckStateRole));

        model.moveEditor(1, Model::Force::YES);
        QCOMPARE(model.editorIndex(), 1);
        QVERIFY(!model.data(model.index(0), Qt::EditRole).toBool());
        QVERIFY(model.data(model.index(1), Qt::EditRole).toBool());
        model.remove(0);
        QCOMPARE(model.editorIndex(), 0);
        QVERIFY(model.data(model.index(0), Qt::EditRole).toBool());
    }

    void insert_move_and_reload_preserve_order_and_identity()
    {
        Model model;
        loadItems(model);
        QSignalSpy count(&model, &Model::countChanged);
        model.insert(-1, "Milk"); model.insert(100, "Eggs"); model.insert(1, "Bread");
        QCOMPARE(count.count(), 3);
        const QString milkId = id(model, 0);
        QCOMPARE(names(model), QStringList({"Milk", "Bread", "Eggs"}));
        model.move(0, 2);
        model.reload();
        QCOMPARE(names(model), QStringList({"Bread", "Eggs", "Milk"}));
        QCOMPARE(id(model, 2), milkId);
        model.move(2, 0);
        Model reloaded;
        loadItems(reloaded);
        QCOMPARE(names(reloaded), QStringList({"Milk", "Bread", "Eggs"}));
        QCOMPARE(id(reloaded, 0), milkId);
    }

    void move_rejects_invalid_rows_data()
    {
        QTest::addColumn<qsizetype>("source");
        QTest::addColumn<qsizetype>("destination");
        QTest::newRow("negative-source") << qsizetype(-1) << qsizetype(0);
        QTest::newRow("negative-destination") << qsizetype(0) << qsizetype(-1);
        QTest::newRow("source-count") << qsizetype(2) << qsizetype(0);
        QTest::newRow("destination-count") << qsizetype(0) << qsizetype(2);
        QTest::newRow("same-row") << qsizetype(1) << qsizetype(1);
        QTest::newRow("minimum-source") << std::numeric_limits<qsizetype>::min() << qsizetype(0);
        QTest::newRow("maximum-destination") << qsizetype(0) << std::numeric_limits<qsizetype>::max();
    }

    void move_rejects_invalid_rows()
    {
        QFETCH(qsizetype, source);
        QFETCH(qsizetype, destination);
        Model model;
        loadItems(model);
        model.insert(0, "A");
        model.insert(1, "B");
        QSignalSpy moved(&model, &Model::rowsMoved);
        QSignalSpy count(&model, &Model::countChanged);

        model.move(source, destination);

        QCOMPARE(names(model), QStringList({"A", "B"}));
        QCOMPARE(moved.count(), 0);
        QCOMPARE(count.count(), 0);
        Model persisted;
        loadItems(persisted);
        QCOMPARE(names(persisted), QStringList({"A", "B"}));
    }

    void checked_state_reorders_persists_and_resets()
    {
        Model model;
        loadItems(model);
        QSignalSpy count(&model, &Model::countChanged);
        model.reset();
        QCOMPARE(count.count(), 0);

        model.insert(0, "Milk"); model.insert(1, "Eggs"); model.insert(2, "Bread");
        QSignalSpy changed(&model, &Model::dataChanged);
        model.setChecked(0, true);
        QCOMPARE(names(model), QStringList({"Eggs", "Bread", "Milk"}));
        model.setChecked(0, true);
        QCOMPARE(names(model), QStringList({"Bread", "Eggs", "Milk"}));
        model.setChecked(1, true);
        QCOMPARE(changed.count(), 2);
        model.reload();
        QVERIFY(model.data(model.index(1), Qt::CheckStateRole).toBool());
        model.toggleChecked(2);
        QCOMPARE(names(model).first(), "Milk");
        model.reset();
        model.reload();
        for (int row = 0; row < model.rowCount(); ++row)
        {
            QVERIFY(!model.data(model.index(row), Qt::CheckStateRole).toBool());
        }
    }

    void toggle_checked_invalid_rows_data()
    {
        QTest::addColumn<bool>("populated");
        QTest::addColumn<bool>("readOnly");
        QTest::addColumn<qsizetype>("row");
        QTest::newRow("empty-negative") << false << false << qsizetype(-1);
        QTest::newRow("empty-zero") << false << false << qsizetype(0);
        QTest::newRow("populated-negative") << true << false << qsizetype(-1);
        QTest::newRow("populated-count") << true << false << qsizetype(2);
        QTest::newRow("populated-beyond-count") << true << false << qsizetype(3);
        QTest::newRow("minimum-index") << true << false << std::numeric_limits<qsizetype>::min();
        QTest::newRow("maximum-index") << true << false << std::numeric_limits<qsizetype>::max();
        QTest::newRow("readonly-empty") << false << true << qsizetype(0);
        QTest::newRow("readonly-negative") << true << true << qsizetype(-1);
        QTest::newRow("readonly-count") << true << true << qsizetype(2);
    }

    void toggle_checked_invalid_rows()
    {
        QFETCH(bool, populated);
        QFETCH(bool, readOnly);
        QFETCH(qsizetype, row);
        Model model;
        loadItems(model);
        if (populated)
        {
            model.insert(0, "Milk");
            model.insert(1, "Eggs");
        }
        model.setReadOnly(readOnly);
        const QStringList expected = names(model);
        QSignalSpy changed(&model, &Model::dataChanged);
        QSignalSpy moved(&model, &Model::rowsMoved);
        QSignalSpy count(&model, &Model::countChanged);

        model.setChecked(row, true);
        model.toggleChecked(row);

        QCOMPARE(names(model), expected);
        QCOMPARE(changed.count(), 0);
        QCOMPARE(moved.count(), 0);
        QCOMPARE(count.count(), 0);
        for (int index = 0; index < model.rowCount(); ++index)
        {
            QVERIFY(!model.data(model.index(index), Qt::CheckStateRole).toBool());
        }
        Model persisted;
        loadItems(persisted);
        QCOMPARE(names(persisted), expected);
        for (int index = 0; index < persisted.rowCount(); ++index)
        {
            QVERIFY(!persisted.data(persisted.index(index), Qt::CheckStateRole).toBool());
        }
    }

    void toggle_checked_reorders_persists_and_respects_readonly()
    {
        Model model;
        loadItems(model);
        model.insert(0, "Milk");
        model.insert(1, "Eggs");
        const QString milkId = id(model, 0);
        QSignalSpy changed(&model, &Model::dataChanged);
        model.toggleChecked(0);
        QCOMPARE(names(model), QStringList({"Eggs", "Milk"}));
        QCOMPARE(id(model, 1), milkId);
        QVERIFY(model.data(model.index(1), Qt::CheckStateRole).toBool());
        model.reload();
        QVERIFY(model.data(model.index(1), Qt::CheckStateRole).toBool());

        model.setReadOnly(true);
        model.toggleChecked(1);
        model.toggleChecked(0);
        QCOMPARE(changed.count(), 1);
        QCOMPARE(names(model), QStringList({"Eggs", "Milk"}));
        QVERIFY(model.data(model.index(1), Qt::CheckStateRole).toBool());
        QVERIFY(!model.data(model.index(0), Qt::CheckStateRole).toBool());
        model.setReadOnly(false);
        model.toggleChecked(1);
        QCOMPARE(changed.count(), 2);
        QCOMPARE(names(model), QStringList({"Milk", "Eggs"}));
        model.reload();
        QCOMPARE(id(model, 0), milkId);
        QVERIFY(!model.data(model.index(0), Qt::CheckStateRole).toBool());
    }

    void remove_and_undo_restore_exact_row_and_uuid()
    {
        Model model;
        loadItems(model);
        model.insert(0, "Milk"); model.insert(1, "Eggs");
        const QString milkId = id(model, 0);
        QSignalSpy undoChanged(&model, &Model::canUndoChanged);
        model.remove(0);
        QCOMPARE(names(model), QStringList({"Eggs"}));
        QVERIFY(model.canUndo());
        model.undo();
        QCOMPARE(names(model), QStringList({"Milk", "Eggs"}));
        QCOMPARE(id(model, 0), milkId);
        QVERIFY(!model.canUndo());
        QVERIFY(undoChanged.count() >= 2);
        model.reload();
        QCOMPARE(id(model, 0), milkId);
        model.remove(0); model.clearUndoStack(); model.undo();
        QCOMPARE(names(model), QStringList({"Eggs"}));
    }

    void remove_checked_and_undo_preserve_remaining_items()
    {
        Model model;
        loadItems(model);
        model.removeChecked();
        model.insert(0, "A"); model.insert(1, "B"); model.insert(2, "C");
        model.addEditor();
        model.setChecked(1, true); model.setChecked(1, true);
        QCOMPARE(names(model), QStringList({"", "C", "B", "A"}));
        const QString aId = id(model, 3);
        QSignalSpy removed(&model, &Model::rowsRemoved);
        model.removeChecked();
        QCOMPARE(names(model), QStringList({"", "C"}));
        QCOMPARE(removed.count(), 1);
        QVERIFY(model.canUndo());
        model.undo();
        QCOMPARE(names(model), QStringList({"", "C", "B", "A"}));
        QCOMPARE(id(model, 3), aId);
        QVERIFY(model.data(model.index(2), Qt::CheckStateRole).toBool());
        model.reload();
        QCOMPARE(names(model), QStringList({"", "C", "B", "A"}));
    }

    void remove_checked_handles_scattered_rows()
    {
        Model model;
        loadItems(model);
        model.insert(0, "A");
        model.insert(1, "B");
        model.insert(2, "C");
        model.insert(3, "D");
        const QString aId = id(model, 0);
        const QString bId = id(model, 1);
        const QString cId = id(model, 2);
        const QString dId = id(model, 3);
        QVERIFY(model.setData(model.index(0), true, Qt::CheckStateRole));
        QVERIFY(model.setData(model.index(2), true, Qt::CheckStateRole));

        QSignalSpy removed(&model, &Model::rowsRemoved);
        model.removeChecked();

        QCOMPARE(names(model), QStringList({"B", "D"}));
        QCOMPARE(id(model, 0), bId);
        QCOMPARE(id(model, 1), dId);
        QCOMPARE(removed.count(), 2);
        QCOMPARE(removed.at(0).at(1).toInt(), 2);
        QCOMPARE(removed.at(0).at(2).toInt(), 2);
        QCOMPARE(removed.at(1).at(1).toInt(), 0);
        QCOMPARE(removed.at(1).at(2).toInt(), 0);

        model.undo();
        QCOMPARE(names(model), QStringList({"A", "B", "C", "D"}));
        QCOMPARE(id(model, 0), aId);
        QCOMPARE(id(model, 1), bId);
        QCOMPARE(id(model, 2), cId);
        QCOMPARE(id(model, 3), dId);
        QVERIFY(model.data(model.index(0), Qt::CheckStateRole).toBool());
        QVERIFY(model.data(model.index(2), Qt::CheckStateRole).toBool());

        model.reload();
        QCOMPARE(names(model), QStringList({"A", "B", "C", "D"}));
        QCOMPARE(id(model, 0), aId);
        QCOMPARE(id(model, 2), cId);
    }

    void remove_all_preserves_editor_and_supports_undo()
    {
        Model model;
        loadItems(model);
        model.removeAll(); model.addEditor(); model.removeAll();
        QCOMPARE(model.rowCount(), 1);
        model.insert(0, "A"); model.insert(1, "B");
        model.removeAll();
        QCOMPARE(model.editorIndex(), 0);
        QCOMPARE(model.rowCount(), 1);
        QVERIFY(model.canUndo());
        model.undo();
        QCOMPARE(names(model), QStringList({"", "A", "B"}));
        model.removeEditor(); model.removeAll();
        QCOMPARE(model.rowCount(), 0);
        model.undo();
        QCOMPARE(names(model), QStringList({"A", "B"}));
    }

    void readonly_remove_all_preserves_rows_and_undo_data()
    {
        QTest::addColumn<int>("editorPosition");
        QTest::newRow("no-editor") << -1;
        QTest::newRow("editor-first") << 0;
        QTest::newRow("editor-middle") << 1;
        QTest::newRow("editor-last") << 3;
    }

    void readonly_remove_all_preserves_rows_and_undo()
    {
        QFETCH(int, editorPosition);
        Model model;
        loadItems(model);
        model.insert(0, "A");
        model.insert(1, "B");
        model.insert(2, "C");
        if (editorPosition >= 0)
        {
            model.addEditor();
            model.moveEditor(editorPosition, Model::Force::YES);
        }
        const QStringList original = names(model);
        model.remove(original.indexOf("C"));
        QVERIFY(model.canUndo());
        const QStringList expected = names(model);
        const qsizetype expectedEditor = model.editorIndex();
        const QString aId = id(model, expected.indexOf("A"));
        const QString bId = id(model, expected.indexOf("B"));
        model.setReadOnly(true);
        QSignalSpy removed(&model, &Model::rowsRemoved);
        QSignalSpy changed(&model, &Model::dataChanged);
        QSignalSpy count(&model, &Model::countChanged);
        QSignalSpy undoChanged(&model, &Model::canUndoChanged);

        model.removeAll();

        QCOMPARE(names(model), expected);
        QCOMPARE(model.editorIndex(), expectedEditor);
        QCOMPARE(id(model, expected.indexOf("A")), aId);
        QCOMPARE(id(model, expected.indexOf("B")), bId);
        QCOMPARE(removed.count(), 0);
        QCOMPARE(changed.count(), 0);
        QCOMPARE(count.count(), 0);
        QCOMPARE(undoChanged.count(), 0);
        Model persisted;
        loadItems(persisted);
        QCOMPARE(names(persisted), QStringList({"A", "B"}));
        model.setReadOnly(false);
        QVERIFY(model.canUndo());
        model.undo();
        QCOMPARE(names(model), original);
    }

    void readonly_remove_all_preserves_pending_edit()
    {
        Model model;
        loadItems(model);
        model.insert(0, "Milk");
        const QString milkId = id(model, 0);
        model.addEditor();
        QCOMPARE(model.editItem(1), "Milk");
        model.setReadOnly(true);
        QSignalSpy inserted(&model, &Model::rowsInserted);
        QSignalSpy removed(&model, &Model::rowsRemoved);
        QSignalSpy changed(&model, &Model::dataChanged);
        QSignalSpy count(&model, &Model::countChanged);
        model.removeAll();
        QCOMPARE(names(model), QStringList({""}));
        QCOMPARE(inserted.count(), 0);
        QCOMPARE(removed.count(), 0);
        QCOMPARE(changed.count(), 0);
        QCOMPARE(count.count(), 0);
        model.setReadOnly(false);
        model.insert(model.editorIndex(), "Renamed");
        model.removeEditor();
        model.reload();
        QCOMPARE(names(model), QStringList({"Renamed"}));
        QCOMPARE(id(model, 0), milkId);
    }

    void readonly_reload_still_replaces_rows()
    {
        Model writer;
        loadItems(writer);
        writer.insert(0, "Milk");
        Model reader;
        loadItems(reader);
        reader.setReadOnly(true);
        writer.removeAll();
        writer.insert(0, "Eggs");
        reader.reload();
        QCOMPARE(names(reader), QStringList({"Eggs"}));
        QCOMPARE(id(reader, 0), id(writer, 0));
        QVERIFY(reader.readOnly());
    }

    void editor_lifecycle_and_item_edit()
    {
        Model model;
        loadItems(model);
        model.moveEditor(0);
        QVERIFY(model.editItem(-1).isEmpty());
        model.insert(0, "A"); model.insert(1, "B");
        QSignalSpy editorChanged(&model, &Model::editorIndexChanged);
        model.addEditor(); model.addEditor();
        QCOMPARE(model.rowCount(), 3);
        QCOMPARE(model.editorIndex(), 0);
        QVERIFY(model.data(model.index(0), Qt::EditRole).toBool());
        model.moveEditor(2, Model::Force::YES);
        QCOMPARE(model.editorIndex(), 2);
        model.moveEditor(0);
        QCOMPARE(model.editorIndex(), 1);
        model.moveEditor(2, Model::Force::YES);
        QCOMPARE(model.editItem(0), "A");
        model.insert(model.editorIndex(), "Renamed A");
        model.removeEditor(); model.removeEditor();
        QCOMPARE(model.editorIndex(), -1);
        QVERIFY(editorChanged.count() >= 4);
        model.reload();
        QCOMPARE(names(model), QStringList({"Renamed A", "B"}));
    }

    void pending_edit_preserves_saved_item_and_cancels()
    {
        Model model;
        loadItems(model);
        model.insert(0, "Milk");
        model.insert(1, "Eggs");
        const QString milkId = id(model, 0);
        model.addEditor();
        QCOMPARE(model.editItem(1), "Milk");

        QSqlQuery saved;
        QVERIFY(saved.exec(SQL::selectFrom().arg(defaultId)));
        QVERIFY(saved.next());
        QCOMPARE(saved.value("name").toString(), "Milk");
        QCOMPARE(saved.value("id").toUuid().toString(QUuid::WithoutBraces), milkId);
        QVERIFY(saved.next());
        QCOMPARE(saved.value("name").toString(), "Eggs");
        QVERIFY(!saved.next());
        saved.finish();

        // Saving another change must also retain the unfinished edit.
        model.remove(1);
        Model persisted;
        loadItems(persisted);
        QCOMPARE(names(persisted), QStringList({"Milk"}));
        QCOMPARE(id(persisted, 0), milkId);

        model.removeEditor();
        QCOMPARE(names(model), QStringList({"Milk"}));
        QCOMPARE(id(model, 0), milkId);
        QCOMPARE(model.editorIndex(), -1);
        model.reload();
        QCOMPARE(names(model), QStringList({"Milk"}));
    }

    void edit_item_at_each_position_data()
    {
        QTest::addColumn<int>("editorPosition");
        QTest::addColumn<int>("itemPosition");
        QTest::newRow("editor-before-first") << 0 << 0;
        QTest::newRow("editor-before-last") << 0 << 1;
        QTest::newRow("editor-between-first") << 1 << 0;
        QTest::newRow("editor-between-last") << 1 << 1;
        QTest::newRow("editor-after-first") << 2 << 0;
        QTest::newRow("editor-after-last") << 2 << 1;
    }

    void edit_item_at_each_position()
    {
        QFETCH(int, editorPosition);
        QFETCH(int, itemPosition);
        Model model;
        loadItems(model);
        model.insert(0, "A");
        model.insert(1, "B");
        const QString originalId = id(model, itemPosition);
        const QString originalName = names(model).at(itemPosition);
        model.addEditor();
        model.moveEditor(editorPosition, Model::Force::YES);
        const int row = itemPosition + (itemPosition >= editorPosition ? 1 : 0);

        QCOMPARE(model.editItem(row), originalName);
        QCOMPARE(model.rowCount(), 2);
        QCOMPARE(model.editorIndex(), itemPosition);
        model.insert(model.editorIndex(), "Renamed");
        model.removeEditor();
        QStringList expected = {"A", "B"};
        expected[itemPosition] = "Renamed";
        QCOMPARE(names(model), expected);
        QCOMPARE(id(model, itemPosition), originalId);
        model.reload();
        QCOMPARE(names(model), expected);
        QCOMPARE(id(model, itemPosition), originalId);
    }

    void edit_item_tags_adjusted_editor_row_data()
    {
        QTest::addColumn<int>("editorPosition");
        QTest::addColumn<int>("itemPosition");
        QTest::addColumn<int>("taggedRow");

        QTest::newRow("editor-after-edited-item") << 3 << 0 << 2;
        QTest::newRow("editor-before-edited-item") << 0 << 2 << 0;
    }

    void edit_item_tags_adjusted_editor_row()
    {
        QFETCH(int, editorPosition);
        QFETCH(int, itemPosition);
        QFETCH(int, taggedRow);

        Model model;
        loadItems(model);
        model.insert(0, "A");
        model.insert(1, "B");
        model.insert(2, "C");
        const QString originalName = names(model).at(itemPosition);
        const QString originalId = id(model, itemPosition);

        model.addEditor();
        model.moveEditor(editorPosition, Model::Force::YES);
        const int editedRow = itemPosition + (itemPosition >= editorPosition ? 1 : 0);

        QSignalSpy changed(&model, &Model::dataChanged);
        QCOMPARE(model.editItem(editedRow), originalName);
        QCOMPARE(changed.count(), 1);

        const auto arguments = changed.takeFirst();
        QCOMPARE(arguments.at(0).value<QModelIndex>().row(), taggedRow);
        QCOMPARE(arguments.at(1).value<QModelIndex>().row(), taggedRow);
        QCOMPARE(arguments.at(2).value<QList<int>>(), QList<int>({ Qt::UserRole + 1 }));
        QCOMPARE(model.editorIndex(), itemPosition);
        QCOMPARE(id(model, itemPosition), originalId);
    }

    void edit_item_rejects_missing_editor_and_invalid_rows()
    {
        Model model;
        loadItems(model);
        QVERIFY(model.editItem(0).isEmpty());
        model.insert(0, "A");
        model.insert(1, "B");
        QSignalSpy removed(&model, &Model::rowsRemoved);
        QSignalSpy count(&model, &Model::countChanged);
        QVERIFY(model.editItem(0).isEmpty());
        QCOMPARE(names(model), QStringList({"A", "B"}));
        model.addEditor();
        count.clear();
        QVERIFY(model.editItem(-1).isEmpty());
        QVERIFY(model.editItem(model.rowCount()).isEmpty());
        QVERIFY(model.editItem(model.editorIndex()).isEmpty());
        QCOMPARE(names(model), QStringList({"", "A", "B"}));
        QCOMPARE(removed.count(), 0);
        QCOMPARE(count.count(), 0);

        QCOMPARE(model.editItem(1), "A");
        QVERIFY(model.editItem(1).isEmpty());
        model.reload();
        QCOMPARE(names(model), QStringList({"", "A", "B"}));
    }

    void pending_list_edit_keeps_table_and_item_identity()
    {
        Model catalog;
        catalog.componentComplete();
        catalog.insert(1, "Weekly");
        const QString weeklyId = id(catalog, 1);
        Model items;
        items.setActiveList(weeklyId);
        items.componentComplete();
        items.insert(0, "Milk");
        catalog.addEditor();
        catalog.moveEditor(2, Model::Force::YES);
        QCOMPARE(catalog.editItem(1), "Weekly");

        // A second model must not regard the pending list as deleted.
        Model fresh;
        fresh.componentComplete();
        QCOMPARE(names(fresh), QStringList({"default", "Weekly"}));
        QVERIFY(QSqlDatabase::database().tables().contains(weeklyId));
        items.reload();
        QCOMPARE(names(items), QStringList({"Milk"}));

        catalog.removeEditor();
        QCOMPARE(names(catalog), QStringList({"default", "Weekly"}));
        QCOMPARE(id(catalog, 1), weeklyId);
    }

    void checked_item_edit_preserves_state_and_identity()
    {
        Model model;
        loadItems(model);
        model.insert(0, "Milk");
        model.setChecked(0, true);
        const QString milkId = id(model, 0);
        model.addEditor();
        QCOMPARE(model.editItem(1), "Milk");
        model.insert(model.editorIndex(), "Renamed");
        model.removeEditor();
        model.reload();
        QCOMPARE(names(model), QStringList({"Renamed"}));
        QCOMPARE(id(model, 0), milkId);
        QVERIFY(model.data(model.index(0), Qt::CheckStateRole).toBool());
    }

    void pending_edit_can_be_removed_and_undone()
    {
        Model model;
        loadItems(model);
        model.insert(0, "Milk");
        const QString milkId = id(model, 0);
        model.addEditor();
        QCOMPARE(model.editItem(1), "Milk");
        model.removeAll();
        QCOMPARE(names(model), QStringList({""}));
        QVERIFY(model.canUndo());
        model.undo();
        model.removeEditor();
        model.reload();
        QCOMPARE(names(model), QStringList({"Milk"}));
        QCOMPARE(id(model, 0), milkId);

        model.addEditor();
        QCOMPARE(model.editItem(1), "Milk");
        model.remove(model.editorIndex());
        QCOMPARE(names(model), QStringList({"Milk"}));
        QCOMPARE(model.editorIndex(), -1);
    }

    void switching_list_discards_pending_edit_without_losing_original()
    {
        Model catalog;
        catalog.componentComplete();
        catalog.insert(1, "Weekly");
        const QString weeklyId = id(catalog, 1);
        Model model;
        loadItems(model);
        model.insert(0, "Milk");
        const QString milkId = id(model, 0);
        model.addEditor();
        QCOMPARE(model.editItem(1), "Milk");
        model.setActiveList(weeklyId);
        QCOMPARE(names(model), QStringList({""}));
        model.insert(model.editorIndex(), "Eggs");
        QVERIFY(id(model, 0) != milkId);
        model.setActiveList("default");
        model.removeEditor();
        QCOMPARE(names(model), QStringList({"Milk"}));
        QCOMPARE(id(model, 0), milkId);
    }

    void readonly_blocks_item_mutations_and_allows_reload()
    {
        Model model;
        loadItems(model);
        model.insert(0, "A"); model.insert(1, "B"); model.remove(1);
        QVERIFY(model.canUndo());
        QSignalSpy changed(&model, &Model::readOnlyChanged);
        model.setReadOnly(true); model.setReadOnly(true);
        QCOMPARE(changed.count(), 1);
        QVERIFY(!model.canUndo());
        model.insert(0, "C"); model.remove(0); model.removeChecked();
        model.setChecked(0, true); model.reset(); model.move(0, 0);
        model.addEditor(); model.removeEditor(); model.moveEditor(0);
        model.undo(); model.clearUndoStack();
        QVERIFY(model.editItem(0).isEmpty());
        QCOMPARE(names(model), QStringList({"A"}));
        model.reload();
        QCOMPARE(names(model), QStringList({"A"}));
        model.setReadOnly(false);
        QCOMPARE(changed.count(), 2);
    }

    void lists_create_rename_switch_and_cleanup()
    {
        Model catalog;
        catalog.componentComplete();
        catalog.insert(1, "Weekly");
        const QString weeklyId = id(catalog, 1);
        QVERIFY(QSqlDatabase::database().tables().contains(weeklyId));
        Model items;
        items.setActiveList(weeklyId); items.componentComplete(); items.insert(0, "Milk");
        catalog.addEditor(); catalog.moveEditor(2, Model::Force::YES);
        QCOMPARE(catalog.editItem(1), "Weekly");
        catalog.insert(catalog.editorIndex(), "Renamed"); catalog.removeEditor();
        QCOMPARE(id(catalog, 1), weeklyId);
        items.reload();
        QCOMPARE(names(items), QStringList({"Milk"}));
        QSignalSpy activeChanged(&items, &Model::activeListChanged);
        items.setActiveList(weeklyId); items.setActiveList("");
        QCOMPARE(activeChanged.count(), 0);
        items.setActiveList("default");
        QCOMPARE(items.activeList(), defaultId);
        items.setActiveList("lists");
        QCOMPARE(items.rowCount(), 2);
        QCOMPARE(activeChanged.count(), 2);
        catalog.remove(1); catalog.undo();
        QVERIFY(QSqlDatabase::database().tables().contains(weeklyId));
        catalog.remove(1);
        Model fresh;
        fresh.componentComplete();
        QVERIFY(!QSqlDatabase::database().tables().contains(weeklyId));
        QVERIFY(QSqlDatabase::database().tables().contains(defaultId));
        Model selector;
        selector.setReadOnly(true); selector.componentComplete();
        QCOMPARE(names(selector), QStringList({"default", "lists"}));
        selector.reload();
        QCOMPARE(selector.rowCount(), 2);
    }

    void failed_save_rolls_back_database_contents()
    {
        Model model;
        loadItems(model);
        const QUuid uuid = QUuid::createUuid();
        model.insert(0, Item("Original", false, uuid));
        model.insert(1, Item("Duplicate", false, uuid));
        Model persisted;
        loadItems(persisted);
        QCOMPARE(names(persisted), QStringList({"Original"}));
        auto database = QSqlDatabase::database();
        QVERIFY(database.transaction());
        persisted.insert(1, "Unsaved");
        QVERIFY(database.rollback());
        persisted.reload();
        QCOMPARE(names(persisted), QStringList({"Original"}));
        QVERIFY(QSqlQuery().exec(SQL::drop().arg(defaultId)));
        persisted.insert(1, "Missing table");
        QCOMPARE(persisted.rowCount(), 2);
    }
};
QTEST_GUILESS_MAIN(ModelTest)
#include "test_model.moc"
