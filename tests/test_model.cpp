#include <QtTest/QTest>
#include <QtTest/QSignalSpy>
#include <QtTest/qtestcase.h>
#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QModelIndex>
#include <QtCore/QStringList>
#include <QtCore/QHash>
#include <QtCore/QList>
#include <QtCore/QtTypes>
#include <QtCore/qnamespace.h>
#include <QtCore/qtmetamacros.h>
#include <QtCore/QMetaProperty>
#include <QtCore/QMetaObject>
#include <QtCore/QMetaType>
#include <QtCore/QVariant>
#include <QtCore/QDate>
#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlQuery>
#include <QtSql/QSqlError>
#include <limits>
#include <QtCore/QFile>
#include "licensenotices.h"
#include "model.h"
#include "weekmodel.h"

namespace {

using Qt::Literals::StringLiterals::operator""_s;

class TestWeekModel : public WeekModel
{
    Q_OBJECT

public:
    explicit TestWeekModel(QObject *parent = nullptr) : WeekModel(parent) { }
    using WeekModel::updateDate;
};

class ModelTest : public QObject
{
    Q_OBJECT

public:
    explicit ModelTest(QObject *parent = nullptr) : QObject(parent) { }

private:
    QString defaultId;

    static void loadItems(Model &model)
    {
        model.classBegin();
        model.setActiveList(QStringLiteral("default"));
        model.componentComplete();
    }
    // NOLINTNEXTLINE(misc-include-cleaner): QStringList's public header is included directly above.
    static QStringList names(const Model &model)
    {
        QStringList result;
        result.reserve(model.rowCount());
        for (int row = 0; row < model.rowCount(); ++row) {
            result.append(model.data(model.index(row)).toString());
        }
        return result;
    }
    static QString id(const Model &model, int row)
    {
        return model.data(model.index(row), Qt::UserRole + 1).toString();
    }

    // NOLINTNEXTLINE(readability-redundant-access-specifiers): Q_SLOTS registers Qt test methods.
private Q_SLOTS:
    static void license_notices_preserve_resources_data()
    {
        QTest::addColumn<bool>("qtNotice");
        QTest::newRow("qt") << true;
        QTest::newRow("font-awesome") << false;
    }

    static void license_notices_preserve_resources()
    {
        QFETCH(const bool, qtNotice);
        const LicenseNotices notices;
        QFile file(qtNotice ? QStringLiteral(":/qt/qml/QShopper/licenses/Qt.txt")
                            : QStringLiteral(":/qt/qml/QShopper/licenses/FontAwesome.txt"));
        QVERIFY(file.open(QIODevice::ReadOnly));
        const auto &paragraphs = qtNotice ? notices.qt() : notices.fontAwesome();
        QVERIFY(!paragraphs.isEmpty());
        QCOMPARE(paragraphs.join(QStringLiteral("\n\n")), QString::fromUtf8(file.readAll()));
    }

    void init()
    {
        // Fresh default connection per test; never opens the user's database.
        auto database = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"));
        database.setDatabaseName(QStringLiteral(":memory:"));
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
    static void cleanup()
    {
        {
            auto database = QSqlDatabase::database();
            database.close();
        }
        QSqlDatabase::removeDatabase(static_cast<const char *>(QSqlDatabase::defaultConnection));
    }

    static void week_model_has_no_child_rows()
    {
        const WeekModel model;
        QCOMPARE(model.rowCount(), 7);
        for (int row = 0; row < model.rowCount(); ++row) {
            const auto parentIndex = model.index(row, 0);
            QVERIFY(parentIndex.isValid());
            QCOMPARE(model.rowCount(parentIndex), 0);
            QVERIFY(!model.index(0, 0, parentIndex).isValid());
        }
        QCOMPARE(model.rowCount(), 7);
    }

    static void week_model_date_refresh_data()
    {
        QTest::addColumn<QString>("initialDateIso");
        QTest::addColumn<QString>("nextDateIso");
        QTest::newRow("unchanged") << u"2026-11-02"_s << u"2026-11-02"_s;
        QTest::newRow("next-day") << u"2026-11-02"_s << u"2026-11-03"_s;
        QTest::newRow("same-day-next-month") << u"2026-11-02"_s << u"2026-12-02"_s;
        QTest::newRow("same-day-next-year") << u"2026-11-02"_s << u"2027-11-02"_s;
        QTest::newRow("same-day-backward-month") << u"2026-11-02"_s << u"2026-10-02"_s;
        QTest::newRow("month-end") << u"2026-11-30"_s << u"2026-12-01"_s;
        QTest::newRow("year-end") << u"2026-12-31"_s << u"2027-01-01"_s;
        QTest::newRow("leap-day") << u"2028-02-28"_s << u"2028-02-29"_s;
        QTest::newRow("multi-day-resume") << u"2026-11-02"_s << u"2026-11-09"_s;
    }

    static void week_model_date_refresh()
    {
        QFETCH(const QString, initialDateIso);
        QFETCH(const QString, nextDateIso);
        const auto initialDate = QDate::fromString(initialDateIso, Qt::ISODate);
        const auto nextDate = QDate::fromString(nextDateIso, Qt::ISODate);
        QVERIFY(initialDate.isValid());
        QVERIFY(nextDate.isValid());
        TestWeekModel model;
        // Two different day numbers seed the fixture independently of the real date.
        model.updateDate(initialDate.addDays(-1));
        model.updateDate(initialDate);
        QCOMPARE(model.rowCount(), 7);
        QCOMPARE(model.data(model.index(0, 0), Qt::UserRole).toString(),
                 initialDate.toString(QStringLiteral("ddd")));
        QCOMPARE(model.data(model.index(0, 0), Qt::UserRole + 1).toString(),
                 initialDate.toString(QStringLiteral("d")));
        const QSignalSpy resets(&model, &QAbstractItemModel::modelReset);
        QVERIFY(resets.isValid());

        // Exercise the production update path called by timerEvent.
        model.updateDate(nextDate);

        QCOMPARE(resets.count(), initialDate == nextDate ? 0 : 1);
        QCOMPARE(model.rowCount(), 7);
        for (int row = 0; row < model.rowCount(); ++row) {
            const auto date = nextDate.addDays(row);
            const auto index = model.index(row, 0);
            QCOMPARE(model.data(index, Qt::UserRole).toString(),
                     date.toString(QStringLiteral("ddd")));
            QCOMPARE(model.data(index, Qt::UserRole + 1).toString(),
                     date.toString(QStringLiteral("d")));
        }
        model.updateDate(nextDate);
        QCOMPARE(resets.count(), initialDate == nextDate ? 0 : 1);
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
        QVERIFY(!model.data({ }).isValid());
        QVERIFY(!model.setData({ }, true, Qt::CheckStateRole));
        model.remove(-1);
        model.remove(std::numeric_limits<qsizetype>::max());
        model.setChecked(-1, true);
        model.insert(0, QStringLiteral("Milk"));
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

    static void editor_role_uses_explicit_index()
    {
        Model model;
        loadItems(model);
        model.insert(0, u""_s);
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

    static void editor_index_property_matches_accessor()
    {
        Model model;
        loadItems(model);
        const int propertyIndex = model.metaObject()->indexOfProperty("editorIndex");
        QVERIFY(propertyIndex >= 0);
        const QMetaProperty property = model.metaObject()->property(propertyIndex);
        QVERIFY(property.isReadable());
        QCOMPARE(property.metaType().id(), QMetaType::Int);
        QCOMPARE(property.metaType().id(),
                 QMetaType::fromType<decltype(model.editorIndex())>().id());
        QCOMPARE(property.read(&model).toInt(), -1);

        model.insert(0, QStringLiteral("Milk"));
        model.insert(1, QStringLiteral("Eggs"));
        model.addEditor();
        QCOMPARE(property.read(&model).toInt(), 0);
        model.moveEditor(2, Model::Force::YES);
        QCOMPARE(property.read(&model).toInt(), 2);
        model.remove(0);
        QCOMPARE(property.read(&model).toInt(), 1);
        model.removeEditor();
        QCOMPARE(property.read(&model).toInt(), -1);
        model.reload();
        QCOMPARE(property.read(&model).toInt(), -1);
        QCOMPARE(names(model), QStringList({ "Eggs" }));
    }

    static void pending_editor_restore_respects_readonly_data()
    {
        QTest::addColumn<bool>("throughRowRemoval");
        QTest::newRow("remove-editor") << false;
        QTest::newRow("remove-row") << true;
    }

    static void pending_editor_restore_respects_readonly()
    {
        QFETCH(const bool, throughRowRemoval);
        Model model;
        loadItems(model);
        model.insert(0, QStringLiteral("Milk"));
        model.insert(1, QStringLiteral("Eggs"));
        const QString milkId = id(model, 0);
        model.addEditor();
        QCOMPARE(model.editItem(1), QStringLiteral("Milk"));
        QObject::connect(&model, &Model::rowsInserted, &model,
                         [&model] { model.setReadOnly(true); });

        if (throughRowRemoval) {
            model.remove(model.editorIndex());
        } else {
            model.removeEditor();
        }

        QVERIFY(model.readOnly());
        QCOMPARE(names(model),
                 QStringList({ QStringLiteral("Milk"), u""_s, QStringLiteral("Eggs") }));
        QCOMPARE(model.editorIndex(), 1);
        QCOMPARE(id(model, 0), milkId);
        model.setReadOnly(false);
        model.removeEditor();
        QCOMPARE(names(model), QStringList({ QStringLiteral("Milk"), QStringLiteral("Eggs") }));
        QCOMPARE(model.editorIndex(), -1);
        model.reload();
        QCOMPARE(names(model), QStringList({ QStringLiteral("Milk"), QStringLiteral("Eggs") }));
        QCOMPARE(id(model, 0), milkId);
    }

    static void move_editor_through_meta_object()
    {
        Model model;
        loadItems(model);
        model.insert(0, QStringLiteral("Milk"));
        model.insert(1, QStringLiteral("Eggs"));
        model.addEditor();
        QVERIFY(QMetaObject::invokeMethod(&model, "moveEditor", Q_ARG(qsizetype, 2),
                                          Q_ARG(Model::Force, Model::Force::YES)));
        QCOMPARE(model.editorIndex(), 2);
        QCOMPARE(names(model), QStringList({ "Milk", "Eggs", "" }));
        model.removeEditor();
        model.reload();
        QCOMPARE(names(model), QStringList({ "Milk", "Eggs" }));
    }

    static void insert_move_and_reload_preserve_order_and_identity()
    {
        Model model;
        loadItems(model);
        QSignalSpy count(&model, &Model::countChanged);
        model.insert(-1, QStringLiteral("Milk"));
        model.insert(std::numeric_limits<qsizetype>::max(), QStringLiteral("Eggs"));
        model.insert(1, QStringLiteral("Bread"));
        QCOMPARE(count.count(), 3);
        const QString milkId = id(model, 0);
        QCOMPARE(names(model), QStringList({ "Milk", "Bread", "Eggs" }));
        model.move(0, 2);
        model.reload();
        QCOMPARE(names(model), QStringList({ "Bread", "Eggs", "Milk" }));
        QCOMPARE(id(model, 2), milkId);
        model.move(2, 0);
        Model reloaded;
        loadItems(reloaded);
        QCOMPARE(names(reloaded), QStringList({ "Milk", "Bread", "Eggs" }));
        QCOMPARE(id(reloaded, 0), milkId);
    }

    static void move_rejects_invalid_rows_data()
    {
        QTest::addColumn<qsizetype>("source");
        QTest::addColumn<qsizetype>("destination");
        QTest::newRow("negative-source") << static_cast<qsizetype>(-1) << static_cast<qsizetype>(0);
        QTest::newRow("negative-destination")
                << static_cast<qsizetype>(0) << static_cast<qsizetype>(-1);
        QTest::newRow("source-count") << static_cast<qsizetype>(2) << static_cast<qsizetype>(0);
        QTest::newRow("destination-count")
                << static_cast<qsizetype>(0) << static_cast<qsizetype>(2);
        QTest::newRow("same-row") << static_cast<qsizetype>(1) << static_cast<qsizetype>(1);
        QTest::newRow("minimum-source")
                << std::numeric_limits<qsizetype>::min() << static_cast<qsizetype>(0);
        QTest::newRow("maximum-destination")
                << static_cast<qsizetype>(0) << std::numeric_limits<qsizetype>::max();
    }

    static void move_rejects_invalid_rows()
    {
        QFETCH(const qsizetype, source);
        QFETCH(const qsizetype, destination);
        Model model;
        loadItems(model);
        model.insert(0, QStringLiteral("A"));
        model.insert(1, QStringLiteral("B"));
        QSignalSpy moved(&model, &Model::rowsMoved);
        QSignalSpy count(&model, &Model::countChanged);

        model.move(source, destination);

        QCOMPARE(names(model), QStringList({ "A", "B" }));
        QCOMPARE(moved.count(), 0);
        QCOMPARE(count.count(), 0);
        Model persisted;
        loadItems(persisted);
        QCOMPARE(names(persisted), QStringList({ "A", "B" }));
    }

    static void checked_state_reorders_persists_and_resets()
    {
        Model model;
        loadItems(model);
        QSignalSpy count(&model, &Model::countChanged);
        model.reset();
        QCOMPARE(count.count(), 0);

        model.insert(0, QStringLiteral("Milk"));
        model.insert(1, QStringLiteral("Eggs"));
        model.insert(2, QStringLiteral("Bread"));
        QSignalSpy changed(&model, &Model::dataChanged);
        model.setChecked(0, true);
        QCOMPARE(names(model), QStringList({ "Eggs", "Bread", "Milk" }));
        model.setChecked(0, true);
        QCOMPARE(names(model), QStringList({ "Bread", "Eggs", "Milk" }));
        model.setChecked(1, true);
        QCOMPARE(changed.count(), 2);
        model.reload();
        QVERIFY(model.data(model.index(1), Qt::CheckStateRole).toBool());
        model.toggleChecked(2);
        QCOMPARE(names(model).constFirst(), "Milk");
        model.reset();
        model.reload();
        for (int row = 0; row < model.rowCount(); ++row) {
            QVERIFY(!model.data(model.index(row), Qt::CheckStateRole).toBool());
        }
    }

    void reset_restores_checking_order()
    {
        Model model;
        loadItems(model);
        model.insert(0, QStringLiteral("1"));
        model.insert(1, QStringLiteral("2"));
        model.insert(2, QStringLiteral("3"));
        const QStringList expected({ "3", "1", "2" });
        for (const auto &name : expected) {
            model.setChecked(names(model).indexOf(name), true);
        }
        QCOMPARE(names(model), QStringList({ "2", "1", "3" }));
        const QStringList identities({ id(model, 2), id(model, 1), id(model, 0) });
        model.reset();
        QCOMPARE(names(model), expected);
        for (int row = 0; row < model.rowCount(); ++row) {
            QVERIFY(!model.data(model.index(row), Qt::CheckStateRole).toBool());
            QCOMPARE(id(model, row), identities.at(row));
        }
        model.reset();
        QCOMPARE(names(model), expected);
        model.setActiveList(QStringLiteral("lists"));
        model.setActiveList(defaultId);
        QCOMPARE(names(model), expected);
        Model reopened;
        loadItems(reopened);
        QCOMPARE(names(reopened), expected);
        for (int row = 0; row < reopened.rowCount(); ++row) {
            QVERIFY(!reopened.data(reopened.index(row), Qt::CheckStateRole).toBool());
            QCOMPARE(id(reopened, row), identities.at(row));
        }
    }

    static void reset_reverses_checked_group_data()
    {
        QTest::addColumn<int>("editorPosition");
        QTest::newRow("without-editor") << -1;
        QTest::newRow("editor-front") << 0;
        QTest::newRow("editor-boundary") << 2;
        QTest::newRow("editor-in-checked-group") << 4;
        constexpr int lastEditorPosition = 5;
        QTest::newRow("editor-at-end") << lastEditorPosition;
    }

    static void reset_reverses_checked_group()
    {
        QFETCH(const int, editorPosition);
        Model model;
        loadItems(model);
        const QStringList items({ "A", "B", "1", "2", "3" });
        for (const auto &name : items) {
            model.insert(model.rowCount(), name);
        }
        const QStringList checkingOrder({ "3", "1", "2" });
        for (const auto &name : checkingOrder) {
            model.setChecked(names(model).indexOf(name), true);
        }
        QCOMPARE(names(model), QStringList({ "A", "B", "2", "1", "3" }));
        if (editorPosition >= 0) {
            model.addEditor();
            model.moveEditor(editorPosition, Model::Force::YES);
        }
        QStringList expected({ "A", "B", "3", "1", "2" });
        if (editorPosition >= 0) {
            expected.insert(editorPosition, u""_s);
        }
        QHash<QString, QString> identities;
        for (int row = 0; row < model.rowCount(); ++row) {
            identities.insert(names(model).at(row), id(model, row));
        }
        const auto editor = model.editorIndex();
        model.reset();
        QCOMPARE(names(model), expected);
        QCOMPARE(model.editorIndex(), editor);
        for (int row = 0; row < model.rowCount(); ++row) {
            QVERIFY(!model.data(model.index(row), Qt::CheckStateRole).toBool());
            QCOMPARE(id(model, row), identities.value(names(model).at(row)));
        }
        model.reset();
        QCOMPARE(names(model), expected);
        model.removeEditor();
        Model reopened;
        loadItems(reopened);
        QCOMPARE(names(reopened), QStringList({ "A", "B", "3", "1", "2" }));
        for (int row = 0; row < reopened.rowCount(); ++row) {
            QVERIFY(!reopened.data(reopened.index(row), Qt::CheckStateRole).toBool());
        }
    }

    static void reset_during_checked_item_edit_data()
    {
        QTest::addColumn<QString>("itemName");
        QTest::newRow("first-checked") << QStringLiteral("3");
        QTest::newRow("middle-checked") << QStringLiteral("1");
        QTest::newRow("last-checked") << QStringLiteral("2");
    }

    static void reset_during_checked_item_edit()
    {
        QFETCH(const QString, itemName);
        Model model;
        loadItems(model);
        model.insert(0, QStringLiteral("1"));
        model.insert(1, QStringLiteral("2"));
        model.insert(2, QStringLiteral("3"));
        const QStringList checkingOrder({ "3", "1", "2" });
        for (const auto &name : checkingOrder) {
            model.setChecked(names(model).indexOf(name), true);
        }
        model.addEditor();
        QCOMPARE(model.editItem(names(model).indexOf(itemName)), itemName);
        model.reset();
        model.removeEditor();
        QCOMPARE(names(model), QStringList({ "3", "1", "2" }));
        for (int row = 0; row < model.rowCount(); ++row) {
            QVERIFY(!model.data(model.index(row), Qt::CheckStateRole).toBool());
        }
        Model reopened;
        loadItems(reopened);
        QCOMPARE(names(reopened), names(model));
        for (int row = 0; row < reopened.rowCount(); ++row) {
            QVERIFY(!reopened.data(reopened.index(row), Qt::CheckStateRole).toBool());
        }
    }

    static void toggle_checked_invalid_rows_data()
    {
        QTest::addColumn<bool>("populated");
        QTest::addColumn<bool>("readOnly");
        QTest::addColumn<qsizetype>("row");
        QTest::newRow("empty-negative") << false << false << static_cast<qsizetype>(-1);
        QTest::newRow("empty-zero") << false << false << static_cast<qsizetype>(0);
        QTest::newRow("populated-negative") << true << false << static_cast<qsizetype>(-1);
        QTest::newRow("populated-count") << true << false << static_cast<qsizetype>(2);
        QTest::newRow("populated-beyond-count") << true << false << static_cast<qsizetype>(3);
        QTest::newRow("minimum-index") << true << false << std::numeric_limits<qsizetype>::min();
        QTest::newRow("maximum-index") << true << false << std::numeric_limits<qsizetype>::max();
        QTest::newRow("readonly-empty") << false << true << static_cast<qsizetype>(0);
        QTest::newRow("readonly-negative") << true << true << static_cast<qsizetype>(-1);
        QTest::newRow("readonly-count") << true << true << static_cast<qsizetype>(2);
    }

    static void toggle_checked_invalid_rows()
    {
        QFETCH(const bool, populated);
        QFETCH(const bool, readOnly);
        QFETCH(const qsizetype, row);
        Model model;
        loadItems(model);
        if (populated) {
            model.insert(0, QStringLiteral("Milk"));
            model.insert(1, QStringLiteral("Eggs"));
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
        for (int index = 0; index < model.rowCount(); ++index) {
            QVERIFY(!model.data(model.index(index), Qt::CheckStateRole).toBool());
        }
        Model persisted;
        loadItems(persisted);
        QCOMPARE(names(persisted), expected);
        for (int index = 0; index < persisted.rowCount(); ++index) {
            QVERIFY(!persisted.data(persisted.index(index), Qt::CheckStateRole).toBool());
        }
    }

    static void toggle_checked_reorders_persists_and_respects_readonly()
    {
        Model model;
        loadItems(model);
        model.insert(0, QStringLiteral("Milk"));
        model.insert(1, QStringLiteral("Eggs"));
        const QString milkId = id(model, 0);
        QSignalSpy changed(&model, &Model::dataChanged);
        model.toggleChecked(0);
        QCOMPARE(names(model), QStringList({ "Eggs", "Milk" }));
        QCOMPARE(id(model, 1), milkId);
        QVERIFY(model.data(model.index(1), Qt::CheckStateRole).toBool());
        model.reload();
        QVERIFY(model.data(model.index(1), Qt::CheckStateRole).toBool());

        model.setReadOnly(true);
        model.toggleChecked(1);
        model.toggleChecked(0);
        QCOMPARE(changed.count(), 1);
        QCOMPARE(names(model), QStringList({ "Eggs", "Milk" }));
        QVERIFY(model.data(model.index(1), Qt::CheckStateRole).toBool());
        QVERIFY(!model.data(model.index(0), Qt::CheckStateRole).toBool());
        model.setReadOnly(false);
        model.toggleChecked(1);
        QCOMPARE(changed.count(), 2);
        QCOMPARE(names(model), QStringList({ "Milk", "Eggs" }));
        model.reload();
        QCOMPARE(id(model, 0), milkId);
        QVERIFY(!model.data(model.index(0), Qt::CheckStateRole).toBool());
    }

    static void deletion_batch_survives_mutations_data()
    {
        QTest::addColumn<QString>("mutation");
        for (const auto &mutation : { "prepend", "reorder", "pending-edit", "check" }) {
            QTest::newRow(mutation) << QString::fromLatin1(mutation);
        }
    }

    static void deletion_batch_survives_mutations()
    {
        QFETCH(const QString, mutation);
        Model model;
        loadItems(model);
        for (const auto &name : { "A", "B", "C", "D", "E" }) {
            model.insert(model.rowCount(), QString::fromLatin1(name));
        }
        const auto bId = id(model, 1);
        const auto cId = id(model, 2);
        const auto dId = id(model, 3);
        model.addEditor();
        model.moveEditor(model.rowCount() - 1, Model::Force::YES);
        model.remove(1);
        model.remove(2);
        QCOMPARE(names(model), QStringList({ "A", "C", "E", "" }));
        QStringList expected;
        if (mutation == u"prepend"_s) {
            model.insert(0, QStringLiteral("New"));
            expected = { u"New"_s, u"A"_s, u"B"_s, u"C"_s, u"D"_s, u"E"_s };
        } else if (mutation == u"reorder"_s) {
            model.move(0, 2);
            expected = { u"C"_s, u"B"_s, u"D"_s, u"E"_s, u"A"_s };
        } else if (mutation == u"pending-edit"_s) {
            QCOMPARE(model.editItem(1), "C");
            expected = { u"A"_s, u"B"_s, u"Renamed C"_s, u"D"_s, u"E"_s };
        } else {
            model.setChecked(1, true);
            expected = { u"A"_s, u"E"_s, u"D"_s, u"B"_s, u"C"_s };
        }
        model.undo();
        QVERIFY(!model.canUndo());
        if (mutation == u"pending-edit"_s) {
            QCOMPARE(id(model, model.editorIndex()), cId);
            model.insert(model.editorIndex(), QStringLiteral("Renamed C"));
        }
        model.removeEditor();
        QCOMPARE(names(model), expected);
        QCOMPARE(id(model, static_cast<int>(expected.indexOf(u"B"_s))), bId);
        QCOMPARE(id(model, static_cast<int>(expected.indexOf(u"D"_s))), dId);
        const auto cRow = static_cast<int>(
                expected.indexOf(mutation == u"pending-edit"_s ? u"Renamed C"_s : u"C"_s));
        QCOMPARE(id(model, cRow), cId);
        QCOMPARE(model.data(model.index(cRow), Qt::CheckStateRole).toBool(),
                 mutation == u"check"_s);
        model.reload();
        QCOMPARE(names(model), expected);
        QCOMPARE(id(model, static_cast<int>(expected.indexOf(u"B"_s))), bId);
        QCOMPARE(id(model, static_cast<int>(expected.indexOf(u"D"_s))), dId);
    }

    static void undo_preserves_pending_edit_and_removed_identity()
    {
        Model model;
        loadItems(model);
        for (const auto &name : { "A", "B", "C", "D" }) {
            model.insert(model.rowCount(), QString::fromLatin1(name));
        }
        const auto bId = id(model, 1);
        const auto cId = id(model, 2);
        model.addEditor();
        model.remove(2);
        QCOMPARE(model.editItem(2), "C");
        model.undo();
        QCOMPARE(id(model, model.editorIndex()), cId);
        model.insert(model.editorIndex(), QStringLiteral("Renamed C"));
        model.removeEditor();
        QCOMPARE(names(model), QStringList({ "A", "B", "Renamed C", "D" }));
        QCOMPARE(id(model, 1), bId);
        QCOMPARE(id(model, 2), cId);
        model.reload();
        QCOMPARE(names(model), QStringList({ "A", "B", "Renamed C", "D" }));
    }

    static void remove_and_undo_restore_exact_row_and_uuid()
    {
        Model model;
        loadItems(model);
        model.insert(0, QStringLiteral("Milk"));
        model.insert(1, QStringLiteral("Eggs"));
        const QString milkId = id(model, 0);
        QSignalSpy undoChanged(&model, &Model::canUndoChanged);
        model.remove(0);
        QCOMPARE(names(model), QStringList({ "Eggs" }));
        QVERIFY(model.canUndo());
        model.undo();
        QCOMPARE(names(model), QStringList({ "Milk", "Eggs" }));
        QCOMPARE(id(model, 0), milkId);
        QVERIFY(!model.canUndo());
        QVERIFY(undoChanged.count() >= 2);
        model.reload();
        QCOMPARE(id(model, 0), milkId);
        model.remove(0);
        model.clearUndoStack();
        model.undo();
        QCOMPARE(names(model), QStringList({ "Eggs" }));
    }

    static void remove_checked_and_undo_preserve_remaining_items()
    {
        Model model;
        loadItems(model);
        model.removeChecked();
        model.insert(0, QStringLiteral("A"));
        model.insert(1, QStringLiteral("B"));
        model.insert(2, QStringLiteral("C"));
        model.addEditor();
        model.setChecked(1, true);
        model.setChecked(1, true);
        QCOMPARE(names(model), QStringList({ "", "C", "B", "A" }));
        const QString aId = id(model, 3);
        QSignalSpy removed(&model, &Model::rowsRemoved);
        model.removeChecked();
        QCOMPARE(names(model), QStringList({ "", "C" }));
        QCOMPARE(removed.count(), 1);
        QVERIFY(model.canUndo());
        model.undo();
        QCOMPARE(names(model), QStringList({ "", "C", "B", "A" }));
        QCOMPARE(id(model, 3), aId);
        QVERIFY(model.data(model.index(2), Qt::CheckStateRole).toBool());
        model.reload();
        QCOMPARE(names(model), QStringList({ "", "C", "B", "A" }));
    }

    static void remove_checked_handles_scattered_rows()
    {
        Model model;
        loadItems(model);
        model.insert(0, QStringLiteral("A"));
        model.insert(1, QStringLiteral("B"));
        model.insert(2, QStringLiteral("C"));
        model.insert(3, QStringLiteral("D"));
        const QString aId = id(model, 0);
        const QString bId = id(model, 1);
        const QString cId = id(model, 2);
        const QString dId = id(model, 3);
        QVERIFY(model.setData(model.index(0), true, Qt::CheckStateRole));
        QVERIFY(model.setData(model.index(2), true, Qt::CheckStateRole));

        QSignalSpy removed(&model, &Model::rowsRemoved);
        model.removeChecked();

        QCOMPARE(names(model), QStringList({ "B", "D" }));
        QCOMPARE(id(model, 0), bId);
        QCOMPARE(id(model, 1), dId);
        QCOMPARE(removed.count(), 2);
        QCOMPARE(removed.at(0).at(1).toInt(), 2);
        QCOMPARE(removed.at(0).at(2).toInt(), 2);
        QCOMPARE(removed.at(1).at(1).toInt(), 0);
        QCOMPARE(removed.at(1).at(2).toInt(), 0);

        model.undo();
        QCOMPARE(names(model), QStringList({ "A", "B", "C", "D" }));
        QCOMPARE(id(model, 0), aId);
        QCOMPARE(id(model, 1), bId);
        QCOMPARE(id(model, 2), cId);
        QCOMPARE(id(model, 3), dId);
        QVERIFY(model.data(model.index(0), Qt::CheckStateRole).toBool());
        QVERIFY(model.data(model.index(2), Qt::CheckStateRole).toBool());

        model.reload();
        QCOMPARE(names(model), QStringList({ "A", "B", "C", "D" }));
        QCOMPARE(id(model, 0), aId);
        QCOMPARE(id(model, 2), cId);
    }

    static void remove_all_preserves_editor_and_supports_undo()
    {
        Model model;
        loadItems(model);
        model.removeAll();
        model.addEditor();
        model.removeAll();
        QCOMPARE(model.rowCount(), 1);
        model.insert(0, QStringLiteral("A"));
        model.insert(1, QStringLiteral("B"));
        model.removeAll();
        QCOMPARE(model.editorIndex(), 0);
        QCOMPARE(model.rowCount(), 1);
        QVERIFY(model.canUndo());
        model.undo();
        QCOMPARE(names(model), QStringList({ "", "A", "B" }));
        model.removeEditor();
        model.removeAll();
        QCOMPARE(model.rowCount(), 0);
        model.undo();
        QCOMPARE(names(model), QStringList({ "A", "B" }));
    }

    static void readonly_remove_all_preserves_rows_and_undo_data()
    {
        QTest::addColumn<int>("editorPosition");
        QTest::newRow("no-editor") << -1;
        QTest::newRow("editor-first") << 0;
        QTest::newRow("editor-middle") << 1;
        QTest::newRow("editor-last") << 3;
    }

    static void readonly_remove_all_preserves_rows_and_undo()
    {
        QFETCH(const int, editorPosition);
        Model model;
        loadItems(model);
        model.insert(0, QStringLiteral("A"));
        model.insert(1, QStringLiteral("B"));
        model.insert(2, QStringLiteral("C"));
        if (editorPosition >= 0) {
            model.addEditor();
            model.moveEditor(editorPosition, Model::Force::YES);
        }
        const QStringList original = names(model);
        model.remove(original.indexOf("C"));
        QVERIFY(model.canUndo());
        const QStringList expected = names(model);
        const qsizetype expectedEditor = model.editorIndex();
        const QString aId = id(model, static_cast<int>(expected.indexOf("A")));
        const QString bId = id(model, static_cast<int>(expected.indexOf("B")));
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
        QCOMPARE(names(persisted), QStringList({ "A", "B" }));
        model.setReadOnly(false);
        QVERIFY(model.canUndo());
        model.undo();
        QCOMPARE(names(model), original);
    }

    static void readonly_remove_all_preserves_pending_edit()
    {
        Model model;
        loadItems(model);
        model.insert(0, QStringLiteral("Milk"));
        const QString milkId = id(model, 0);
        model.addEditor();
        QCOMPARE(model.editItem(1), "Milk");
        model.setReadOnly(true);
        QSignalSpy inserted(&model, &Model::rowsInserted);
        QSignalSpy removed(&model, &Model::rowsRemoved);
        QSignalSpy changed(&model, &Model::dataChanged);
        QSignalSpy count(&model, &Model::countChanged);
        model.removeAll();
        QCOMPARE(names(model), QStringList({ "" }));
        QCOMPARE(inserted.count(), 0);
        QCOMPARE(removed.count(), 0);
        QCOMPARE(changed.count(), 0);
        QCOMPARE(count.count(), 0);
        model.setReadOnly(false);
        model.insert(model.editorIndex(), QStringLiteral("Renamed"));
        model.removeEditor();
        model.reload();
        QCOMPARE(names(model), QStringList({ "Renamed" }));
        QCOMPARE(id(model, 0), milkId);
    }

    static void readonly_reload_still_replaces_rows()
    {
        Model writer;
        loadItems(writer);
        writer.insert(0, QStringLiteral("Milk"));
        Model reader;
        loadItems(reader);
        reader.setReadOnly(true);
        writer.removeAll();
        writer.insert(0, QStringLiteral("Eggs"));
        reader.reload();
        QCOMPARE(names(reader), QStringList({ "Eggs" }));
        QCOMPARE(id(reader, 0), id(writer, 0));
        QVERIFY(reader.readOnly());
    }

    static void editor_lifecycle_and_item_edit()
    {
        Model model;
        loadItems(model);
        model.moveEditor(0);
        QVERIFY(model.editItem(-1).isEmpty());
        model.insert(0, QStringLiteral("A"));
        model.insert(1, QStringLiteral("B"));
        QSignalSpy editorChanged(&model, &Model::editorIndexChanged);
        model.addEditor();
        model.addEditor();
        QCOMPARE(model.rowCount(), 3);
        QCOMPARE(model.editorIndex(), 0);
        QVERIFY(model.data(model.index(0), Qt::EditRole).toBool());
        model.moveEditor(2, Model::Force::YES);
        QCOMPARE(model.editorIndex(), 2);
        model.moveEditor(0);
        QCOMPARE(model.editorIndex(), 1);
        model.moveEditor(2, Model::Force::YES);
        QCOMPARE(model.editItem(0), "A");
        model.insert(model.editorIndex(), QStringLiteral("Renamed A"));
        model.removeEditor();
        model.removeEditor();
        QCOMPARE(model.editorIndex(), -1);
        QVERIFY(editorChanged.count() >= 4);
        model.reload();
        QCOMPARE(names(model), QStringList({ "Renamed A", "B" }));
    }

    void pending_edit_preserves_saved_item_and_cancels()
    {
        Model model;
        loadItems(model);
        model.insert(0, QStringLiteral("Milk"));
        model.insert(1, QStringLiteral("Eggs"));
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
        QCOMPARE(names(persisted), QStringList({ "Milk" }));
        QCOMPARE(id(persisted, 0), milkId);

        model.removeEditor();
        QCOMPARE(names(model), QStringList({ "Milk" }));
        QCOMPARE(id(model, 0), milkId);
        QCOMPARE(model.editorIndex(), -1);
        model.reload();
        QCOMPARE(names(model), QStringList({ "Milk" }));
    }

    static void edit_item_at_each_position_data()
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

    static void edit_item_at_each_position()
    {
        QFETCH(const int, editorPosition);
        QFETCH(const int, itemPosition);
        Model model;
        loadItems(model);
        model.insert(0, QStringLiteral("A"));
        model.insert(1, QStringLiteral("B"));
        const QString originalId = id(model, itemPosition);
        const QString originalName = names(model).at(itemPosition);
        model.addEditor();
        model.moveEditor(editorPosition, Model::Force::YES);
        const int row = itemPosition + (itemPosition >= editorPosition ? 1 : 0);

        QCOMPARE(model.editItem(row), originalName);
        QCOMPARE(model.rowCount(), 2);
        QCOMPARE(model.editorIndex(), itemPosition);
        model.insert(model.editorIndex(), QStringLiteral("Renamed"));
        model.removeEditor();
        QStringList expected = { "A", "B" };
        expected.replace(itemPosition, QStringLiteral("Renamed"));
        QCOMPARE(names(model), expected);
        QCOMPARE(id(model, itemPosition), originalId);
        model.reload();
        QCOMPARE(names(model), expected);
        QCOMPARE(id(model, itemPosition), originalId);
    }

    static void edit_item_tags_adjusted_editor_row_data()
    {
        QTest::addColumn<int>("editorPosition");
        QTest::addColumn<int>("itemPosition");
        QTest::addColumn<int>("taggedRow");

        QTest::newRow("editor-after-edited-item") << 3 << 0 << 2;
        QTest::newRow("editor-before-edited-item") << 0 << 2 << 0;
    }

    static void edit_item_tags_adjusted_editor_row()
    {
        QFETCH(const int, editorPosition);
        QFETCH(const int, itemPosition);
        QFETCH(const int, taggedRow);

        Model model;
        loadItems(model);
        model.insert(0, QStringLiteral("A"));
        model.insert(1, QStringLiteral("B"));
        model.insert(2, QStringLiteral("C"));
        const QString originalName = names(model).at(itemPosition);
        const QString originalId = id(model, itemPosition);

        model.addEditor();
        model.moveEditor(editorPosition, Model::Force::YES);
        const int editedRow = itemPosition + (itemPosition >= editorPosition ? 1 : 0);

        QSignalSpy changed(&model, &Model::dataChanged);
        QCOMPARE(model.editItem(editedRow), originalName);
        QCOMPARE(changed.count(), 1);

        const auto arguments = changed.takeFirst();
        QCOMPARE(arguments.at(0).toModelIndex().row(), taggedRow);
        QCOMPARE(arguments.at(1).toModelIndex().row(), taggedRow);
        QCOMPARE(arguments.at(2).value<QList<int>>(), QList<int>({ Qt::UserRole + 1 }));
        QCOMPARE(model.editorIndex(), itemPosition);
        QCOMPARE(id(model, itemPosition), originalId);
    }

    static void edit_item_rejects_missing_editor_and_invalid_rows()
    {
        Model model;
        loadItems(model);
        QVERIFY(model.editItem(0).isEmpty());
        model.insert(0, QStringLiteral("A"));
        model.insert(1, QStringLiteral("B"));
        QSignalSpy removed(&model, &Model::rowsRemoved);
        QSignalSpy count(&model, &Model::countChanged);
        QVERIFY(model.editItem(0).isEmpty());
        QCOMPARE(names(model), QStringList({ "A", "B" }));
        model.addEditor();
        count.clear();
        QVERIFY(model.editItem(-1).isEmpty());
        QVERIFY(model.editItem(model.rowCount()).isEmpty());
        QVERIFY(model.editItem(model.editorIndex()).isEmpty());
        QCOMPARE(names(model), QStringList({ "", "A", "B" }));
        QCOMPARE(removed.count(), 0);
        QCOMPARE(count.count(), 0);

        QCOMPARE(model.editItem(1), "A");
        QVERIFY(model.editItem(1).isEmpty());
        model.reload();
        QCOMPARE(names(model), QStringList({ "", "A", "B" }));
    }

    static void pending_list_edit_keeps_table_and_item_identity()
    {
        Model catalog;
        catalog.componentComplete();
        catalog.insert(1, QStringLiteral("Weekly"));
        const QString weeklyId = id(catalog, 1);
        Model items;
        items.setActiveList(weeklyId);
        items.componentComplete();
        items.insert(0, QStringLiteral("Milk"));
        catalog.addEditor();
        catalog.moveEditor(2, Model::Force::YES);
        QCOMPARE(catalog.editItem(1), "Weekly");

        // A second model must not regard the pending list as deleted.
        Model fresh;
        fresh.componentComplete();
        QCOMPARE(names(fresh), QStringList({ "default", "Weekly" }));
        QVERIFY(QSqlDatabase::database().tables().contains(weeklyId));
        items.reload();
        QCOMPARE(names(items), QStringList({ "Milk" }));

        catalog.removeEditor();
        QCOMPARE(names(catalog), QStringList({ "default", "Weekly" }));
        QCOMPARE(id(catalog, 1), weeklyId);
    }

    static void checked_item_edit_preserves_state_and_identity()
    {
        Model model;
        loadItems(model);
        model.insert(0, QStringLiteral("Milk"));
        model.setChecked(0, true);
        const QString milkId = id(model, 0);
        model.addEditor();
        QCOMPARE(model.editItem(1), "Milk");
        model.insert(model.editorIndex(), QStringLiteral("Renamed"));
        model.removeEditor();
        model.reload();
        QCOMPARE(names(model), QStringList({ "Renamed" }));
        QCOMPARE(id(model, 0), milkId);
        QVERIFY(model.data(model.index(0), Qt::CheckStateRole).toBool());
    }

    static void pending_edit_can_be_removed_and_undone()
    {
        Model model;
        loadItems(model);
        model.insert(0, QStringLiteral("Milk"));
        const QString milkId = id(model, 0);
        model.addEditor();
        QCOMPARE(model.editItem(1), "Milk");
        model.removeAll();
        QCOMPARE(names(model), QStringList({ "" }));
        QVERIFY(model.canUndo());
        model.undo();
        model.removeEditor();
        model.reload();
        QCOMPARE(names(model), QStringList({ "Milk" }));
        QCOMPARE(id(model, 0), milkId);

        model.addEditor();
        QCOMPARE(model.editItem(1), "Milk");
        model.remove(model.editorIndex());
        QCOMPARE(names(model), QStringList({ "Milk" }));
        QCOMPARE(model.editorIndex(), -1);
    }

    static void switching_list_discards_pending_edit_without_losing_original()
    {
        Model catalog;
        catalog.componentComplete();
        catalog.insert(1, QStringLiteral("Weekly"));
        const QString weeklyId = id(catalog, 1);
        Model model;
        loadItems(model);
        model.insert(0, QStringLiteral("Milk"));
        const QString milkId = id(model, 0);
        model.addEditor();
        QCOMPARE(model.editItem(1), "Milk");
        model.setActiveList(weeklyId);
        QCOMPARE(names(model), QStringList({ "" }));
        model.insert(model.editorIndex(), QStringLiteral("Eggs"));
        QVERIFY(id(model, 0) != milkId);
        model.setActiveList(QStringLiteral("default"));
        model.removeEditor();
        QCOMPARE(names(model), QStringList({ "Milk" }));
        QCOMPARE(id(model, 0), milkId);
    }

    static void readonly_blocks_item_mutations_and_allows_reload()
    {
        Model model;
        loadItems(model);
        model.insert(0, QStringLiteral("A"));
        model.insert(1, QStringLiteral("B"));
        model.insert(2, QStringLiteral("C"));
        const QString aId = id(model, 0);
        const QString bId = id(model, 1);
        const QString cId = id(model, 2);
        model.remove(2);
        QVERIFY(model.canUndo());
        QSignalSpy changed(&model, &Model::readOnlyChanged);
        QSignalSpy moved(&model, &Model::rowsMoved);
        model.setReadOnly(true);
        model.setReadOnly(true);
        QCOMPARE(changed.count(), 1);
        QVERIFY(!model.canUndo());
        // Both moves are valid when writable; same-row movement cannot test this guard.
        model.move(0, 1);
        QCOMPARE(names(model), QStringList({ "A", "B" }));
        QCOMPARE(moved.count(), 0);
        model.move(1, 0);
        QCOMPARE(names(model), QStringList({ "A", "B" }));
        QCOMPARE(moved.count(), 0);
        QCOMPARE(id(model, 0), aId);
        QCOMPARE(id(model, 1), bId);
        model.insert(0, QStringLiteral("D"));
        model.remove(0);
        model.removeChecked();
        model.setChecked(0, true);
        model.reset();
        model.move(0, 0);
        model.addEditor();
        model.removeEditor();
        model.moveEditor(0);
        model.undo();
        model.clearUndoStack();
        QVERIFY(model.editItem(0).isEmpty());
        QCOMPARE(names(model), QStringList({ "A", "B" }));
        Model persisted;
        loadItems(persisted);
        QCOMPARE(names(persisted), QStringList({ "A", "B" }));
        QCOMPARE(id(persisted, 0), aId);
        QCOMPARE(id(persisted, 1), bId);
        model.setReadOnly(false);
        QCOMPARE(changed.count(), 2);
        QVERIFY(model.canUndo());
        model.undo();
        QCOMPARE(names(model), QStringList({ "A", "B", "C" }));
        QCOMPARE(id(model, 2), cId);
        model.setReadOnly(true);
        model.reload();
        QCOMPARE(names(model), QStringList({ "A", "B", "C" }));
        QVERIFY(model.readOnly());
        model.setReadOnly(false);
        QCOMPARE(changed.count(), 4);
    }

    void lists_create_rename_switch_and_cleanup()
    {
        Model catalog;
        catalog.componentComplete();
        catalog.insert(1, QStringLiteral("Weekly"));
        const QString weeklyId = id(catalog, 1);
        QVERIFY(QSqlDatabase::database().tables().contains(weeklyId));
        Model items;
        items.setActiveList(weeklyId);
        items.componentComplete();
        items.insert(0, QStringLiteral("Milk"));
        catalog.addEditor();
        catalog.moveEditor(2, Model::Force::YES);
        QCOMPARE(catalog.editItem(1), "Weekly");
        catalog.insert(catalog.editorIndex(), QStringLiteral("Renamed"));
        catalog.removeEditor();
        QCOMPARE(id(catalog, 1), weeklyId);
        items.reload();
        QCOMPARE(names(items), QStringList({ "Milk" }));
        QSignalSpy activeChanged(&items, &Model::activeListChanged);
        items.setActiveList(weeklyId);
        items.setActiveList(u""_s);
        QCOMPARE(activeChanged.count(), 0);
        items.setActiveList(QStringLiteral("default"));
        QCOMPARE(items.activeList(), defaultId);
        items.setActiveList(QStringLiteral("lists"));
        QCOMPARE(items.rowCount(), 2);
        QCOMPARE(activeChanged.count(), 2);
        catalog.remove(1);
        catalog.undo();
        QVERIFY(QSqlDatabase::database().tables().contains(weeklyId));
        catalog.remove(1);
        Model fresh;
        fresh.componentComplete();
        QVERIFY(!QSqlDatabase::database().tables().contains(weeklyId));
        QVERIFY(QSqlDatabase::database().tables().contains(defaultId));
        Model selector;
        selector.setReadOnly(true);
        selector.componentComplete();
        QCOMPARE(names(selector), QStringList({ "default", "lists" }));
        selector.reload();
        QCOMPARE(selector.rowCount(), 2);
    }

    static void cleanup_requires_complete_catalog_data()
    {
        QTest::addColumn<QString>("fault");
        QTest::addColumn<bool>("readOnly");
        QTest::addColumn<bool>("emptyCatalog");
        QTest::newRow("initial-read-failure") << u"initial"_s << false << false;
        QTest::newRow("iteration-read-failure") << u"iteration"_s << false << false;
        QTest::newRow("readonly-read-failure") << u"iteration"_s << true << false;
        QTest::newRow("healthy-catalog") << u"none"_s << false << false;
        QTest::newRow("healthy-empty-catalog") << u"none"_s << false << true;
    }

    void cleanup_requires_complete_catalog()
    {
        QFETCH(const QString, fault);
        QFETCH(const bool, readOnly);
        QFETCH(const bool, emptyCatalog);
        const auto database = QSqlDatabase::database();
        QSqlQuery query(database);
        const auto otherList = QUuid::createUuid().toString(QUuid::WithoutBraces);
        const auto orphan = QUuid::createUuid().toString(QUuid::WithoutBraces);
        const QString metadata = QStringLiteral("retained_metadata");
        const QStringList savedTables{ defaultId, otherList, orphan, metadata };
        QHash<QString, QUuid> identities;
        for (const auto &table : savedTables) {
            QVERIFY(query.exec(SQL::create().arg(table)));
            const auto identity = QUuid::createUuid();
            identities.insert(table, identity);
            query.prepare(SQL::insertTo().arg(table));
            query.addBindValue(identity);
            query.addBindValue(QStringLiteral("Retained fixture"));
            query.addBindValue(true);
            QVERIFY(query.exec());
        }
        query.prepare(SQL::insertTo().arg(SQL::tableLists()));
        query.addBindValue(otherList);
        query.addBindValue(QStringLiteral("weekly"));
        query.addBindValue(false);
        QVERIFY(query.exec());
        if (emptyCatalog) {
            QVERIFY(query.exec(SQL::deleteFrom().arg(SQL::tableLists())));
        }
        if (fault != u"none"_s) {
            QVERIFY(query.exec(QStringLiteral("ALTER TABLE lists RENAME TO catalog_entries")));
            if (fault == u"initial"_s) {
                QVERIFY(query.exec(QStringLiteral("CREATE VIEW lists AS "
                                                  "SELECT name, checked FROM catalog_entries")));
            } else {
                QVERIFY(query.exec(QStringLiteral(
                        "CREATE VIEW lists AS SELECT name, checked, "
                        "CASE WHEN name='weekly' THEN abs(-9223372036854775808) ELSE id END AS id "
                        "FROM catalog_entries")));
            }
        }
        // Establish the fault stage independently, before production cleanup runs.
        {
            QSqlQuery catalog(database);
            const bool executed = catalog.exec(SQL::selectFrom().arg(SQL::tableLists()));
            int rows = 0;
            while (catalog.next()) {
                ++rows;
            }
            if (fault == u"initial"_s) {
                QVERIFY(!executed);
                QCOMPARE(rows, 0);
                QVERIFY(catalog.lastError().isValid());
            } else if (fault == u"iteration"_s) {
                QVERIFY(executed);
                QCOMPARE(rows, 1);
                QVERIFY(catalog.lastError().isValid());
            } else {
                QVERIFY(executed);
                QCOMPARE(rows, emptyCatalog ? 0 : 2);
                QVERIFY(!catalog.lastError().isValid());
            }
        }

        Model model;
        model.setReadOnly(readOnly);
        model.componentComplete();

        const auto remainingTables = database.tables();
        for (const auto &table : savedTables) {
            const bool keep = readOnly || fault != u"none"_s || table == metadata
                    || (!emptyCatalog && table != orphan);
            QCOMPARE(remainingTables.contains(table), keep);
            if (keep) {
                QVERIFY(query.exec(SQL::selectFrom().arg(table)));
                QVERIFY(query.next());
                QCOMPARE(query.value(QStringLiteral("name")).toString(),
                         QStringLiteral("Retained fixture"));
                QVERIFY(query.value(QStringLiteral("checked")).toBool());
                QCOMPARE(query.value(QStringLiteral("id")).toUuid(), identities.value(table));
                QVERIFY(!query.next());
            }
        }
        QVERIFY(remainingTables.contains(fault == u"none"_s ? SQL::tableLists()
                                                            : QStringLiteral("catalog_entries")));
    }

    static void reload_applies_only_complete_reads_data()
    {
        QTest::addColumn<QString>("fault");
        QTest::addColumn<bool>("readOnly");
        QTest::addColumn<bool>("empty");
        QTest::newRow("initial-failure") << u"initial"_s << false << false;
        QTest::newRow("iteration-failure") << u"iteration"_s << false << false;
        QTest::newRow("readonly-initial-failure") << u"initial"_s << true << false;
        QTest::newRow("readonly-iteration-failure") << u"iteration"_s << true << false;
        QTest::newRow("healthy") << u"none"_s << false << false;
        QTest::newRow("readonly-healthy") << u"none"_s << true << false;
        QTest::newRow("healthy-empty") << u"none"_s << false << true;
    }

    void reload_applies_only_complete_reads()
    {
        QFETCH(const QString, fault);
        QFETCH(const bool, readOnly);
        QFETCH(const bool, empty);
        Model model;
        loadItems(model);
        model.insert(0, QStringLiteral("Milk"));
        model.insert(1, QStringLiteral("Eggs"));
        model.setChecked(1, true);
        const QString milkId = id(model, 0);
        const QString eggsId = id(model, 1);
        QSqlQuery query;
        if (fault != u"none"_s) {
            QVERIFY(query.exec(
                    QStringLiteral("ALTER TABLE \"%1\" RENAME TO saved_items").arg(defaultId)));
            const auto columns = fault == u"initial"_s
                    ? u"name, checked"_s
                    : u"name, checked, CASE WHEN name='Eggs' THEN abs(-9223372036854775808) "
                      "ELSE id END AS id"_s;
            QVERIFY(query.exec(QStringLiteral("CREATE VIEW \"%1\" AS SELECT %2 FROM saved_items")
                                       .arg(defaultId, columns)));
            // Prove this fixture fails before the first row or after one complete row.
            QSqlQuery read;
            const bool executed = read.exec(SQL::selectFrom().arg(defaultId));
            int rows = 0;
            while (read.next()) {
                ++rows;
            }
            QCOMPARE(executed, fault == u"iteration"_s);
            QCOMPARE(rows, fault == u"iteration"_s ? 1 : 0);
            QVERIFY(read.lastError().isValid());
        } else if (empty) {
            QVERIFY(query.exec(SQL::deleteFrom().arg(defaultId)));
        } else {
            QVERIFY(query.exec(QStringLiteral("UPDATE \"%1\" SET name='Updated milk' "
                                              "WHERE name='Milk'")
                                       .arg(defaultId)));
        }
        model.setReadOnly(readOnly);
        QSignalSpy removed(&model, &Model::rowsRemoved);
        QSignalSpy inserted(&model, &Model::rowsInserted);
        QSignalSpy count(&model, &Model::countChanged);
        model.reload();
        const auto reloadedNames = names(model);
        if (fault != u"none"_s) {
            QVERIFY(query.exec(QStringLiteral("DROP VIEW \"%1\"").arg(defaultId)));
            QVERIFY(query.exec(
                    QStringLiteral("ALTER TABLE saved_items RENAME TO \"%1\"").arg(defaultId)));
        }

        QStringList expected;
        if (!empty) {
            expected = { fault == u"none"_s ? u"Updated milk"_s : u"Milk"_s, u"Eggs"_s };
        }
        // Exercise the destructive follow-up, not just the failed read's immediate row count.
        model.setReadOnly(false);
        const auto removedAfterReload = removed.count();
        const auto insertedAfterReload = inserted.count();
        const auto countAfterReload = count.count();
        model.insert(model.rowCount(), QStringLiteral("New item"));
        Model persisted;
        loadItems(persisted);
        QCOMPARE(names(persisted), expected + QStringList{ "New item" });
        QCOMPARE(reloadedNames, expected);
        if (!empty) {
            QCOMPARE(id(persisted, 0), milkId);
            QCOMPARE(id(persisted, 1), eggsId);
            QVERIFY(!persisted.data(persisted.index(0), Qt::CheckStateRole).toBool());
            QVERIFY(persisted.data(persisted.index(1), Qt::CheckStateRole).toBool());
        }
        if (fault != u"none"_s) {
            QCOMPARE(removedAfterReload, 0);
            QCOMPARE(insertedAfterReload, 0);
            QCOMPARE(countAfterReload, 0);
        }
    }

    static void failed_reload_preserves_edit_and_undo_data()
    {
        QTest::addColumn<bool>("partial");
        QTest::addColumn<bool>("readOnly");
        QTest::newRow("initial") << false << false;
        QTest::newRow("partial") << true << false;
        QTest::newRow("readonly-initial") << false << true;
        QTest::newRow("readonly-partial") << true << true;
    }

    void failed_reload_preserves_edit_and_undo()
    {
        QFETCH(const bool, partial);
        QFETCH(const bool, readOnly);
        Model model;
        loadItems(model);
        model.insert(0, QStringLiteral("Milk"));
        model.insert(1, QStringLiteral("Eggs"));
        model.insert(2, QStringLiteral("Bread"));
        model.setChecked(1, true);
        // Checking moved Eggs to the end; remove Bread to populate Undo.
        const QString milkId = id(model, 0);
        const QString breadId = id(model, 1);
        const QString eggsId = id(model, 2);
        model.remove(1);
        model.addEditor();
        QCOMPARE(model.editItem(1), "Milk");
        model.moveEditor(1, Model::Force::YES);
        QCOMPARE(names(model), QStringList({ "Eggs", "" }));
        model.setReadOnly(readOnly);
        QSqlQuery query;
        QVERIFY(query.exec(
                QStringLiteral("ALTER TABLE \"%1\" RENAME TO saved_items").arg(defaultId)));
        const auto columns = partial
                ? u"name, checked, CASE WHEN name='Eggs' THEN abs(-9223372036854775808) "
                  "ELSE id END AS id"_s
                : u"name, checked"_s;
        QVERIFY(query.exec(QStringLiteral("CREATE VIEW \"%1\" AS SELECT %2 FROM saved_items")
                                   .arg(defaultId, columns)));
        QSignalSpy removed(&model, &Model::rowsRemoved);
        QSignalSpy inserted(&model, &Model::rowsInserted);
        QSignalSpy editorChanged(&model, &Model::editorIndexChanged);
        QSignalSpy undoChanged(&model, &Model::canUndoChanged);
        model.reload();
        QVERIFY(query.exec(QStringLiteral("DROP VIEW \"%1\"").arg(defaultId)));
        QVERIFY(query.exec(
                QStringLiteral("ALTER TABLE saved_items RENAME TO \"%1\"").arg(defaultId)));
        QCOMPARE(names(model), QStringList({ "Eggs", "" }));
        QCOMPARE(model.editorIndex(), 1);
        QCOMPARE(id(model, 0), eggsId);
        QCOMPARE(id(model, 1), milkId);
        QVERIFY(model.data(model.index(0), Qt::CheckStateRole).toBool());
        QCOMPARE(model.canUndo(), !readOnly);
        QCOMPARE(removed.count(), 0);
        QCOMPARE(inserted.count(), 0);
        QCOMPARE(editorChanged.count(), 0);
        QCOMPARE(undoChanged.count(), 0);
        model.setReadOnly(false);
        QVERIFY(model.canUndo());
        model.insert(model.editorIndex(), QStringLiteral("Renamed"));
        model.removeEditor();
        model.undo();
        // The pending edit retained its identity, and the old removal command still works.
        QCOMPARE(names(model), QStringList({ "Eggs", "Bread", "Renamed" }));
        QCOMPARE(id(model, 0), eggsId);
        QCOMPARE(id(model, 1), breadId);
        QCOMPARE(id(model, 2), milkId);
        model.reload();
        QCOMPARE(names(model), QStringList({ "Eggs", "Bread", "Renamed" }));
    }

    static void failed_list_switch_preserves_source_and_target_data()
    {
        QTest::addColumn<bool>("partial");
        QTest::newRow("initial") << false;
        QTest::newRow("partial") << true;
    }

    void failed_list_switch_preserves_source_and_target()
    {
        QFETCH(const bool, partial);
        Model catalog;
        catalog.componentComplete();
        catalog.insert(1, QStringLiteral("Weekly"));
        const QString weeklyId = id(catalog, 1);
        Model weekly;
        weekly.setActiveList(weeklyId);
        weekly.insert(0, QStringLiteral("Milk"));
        weekly.insert(1, QStringLiteral("Eggs"));
        weekly.setChecked(1, true);
        const QString milkId = id(weekly, 0);
        const QString eggsId = id(weekly, 1);
        Model model;
        loadItems(model);
        model.insert(0, QStringLiteral("Source"));
        const QString sourceId = id(model, 0);
        QSqlQuery query;
        QVERIFY(query.exec(
                QStringLiteral("ALTER TABLE \"%1\" RENAME TO saved_items").arg(weeklyId)));
        const auto columns = partial
                ? u"name, checked, CASE WHEN name='Eggs' THEN abs(-9223372036854775808) "
                  "ELSE id END AS id"_s
                : u"name, checked"_s;
        QVERIFY(query.exec(QStringLiteral("CREATE VIEW \"%1\" AS SELECT %2 FROM saved_items")
                                   .arg(weeklyId, columns)));
        QSignalSpy activeChanged(&model, &Model::activeListChanged);
        model.setActiveList(weeklyId);
        const auto listAfterFailure = model.activeList();
        const auto namesAfterFailure = names(model);
        const auto changesAfterFailure = activeChanged.count();
        QVERIFY(query.exec(QStringLiteral("DROP VIEW \"%1\"").arg(weeklyId)));
        QVERIFY(query.exec(
                QStringLiteral("ALTER TABLE saved_items RENAME TO \"%1\"").arg(weeklyId)));
        model.insert(model.rowCount(), QStringLiteral("New item"));
        weekly.reload();
        QCOMPARE(names(weekly), QStringList({ "Milk", "Eggs" }));
        QCOMPARE(id(weekly, 0), milkId);
        QCOMPARE(id(weekly, 1), eggsId);
        QVERIFY(weekly.data(weekly.index(1), Qt::CheckStateRole).toBool());
        QCOMPARE(listAfterFailure, defaultId);
        QCOMPARE(namesAfterFailure, QStringList({ "Source" }));
        QCOMPARE(changesAfterFailure, 0);
        Model source;
        loadItems(source);
        QCOMPARE(names(source), QStringList({ "Source", "New item" }));
        QCOMPARE(id(source, 0), sourceId);
        // A failed switch must remain retryable after the target becomes readable.
        model.setActiveList(weeklyId);
        QCOMPARE(model.activeList(), weeklyId);
        QCOMPARE(names(model), QStringList({ "Milk", "Eggs" }));
        QCOMPARE(activeChanged.count(), 1);
    }

    void failed_save_rolls_back_database_contents()
    {
        Model model;
        loadItems(model);
        const QUuid uuid = QUuid::createUuid();
        model.insert(0, Item(QStringLiteral("Original"), false, uuid));
        model.insert(1, Item(QStringLiteral("Duplicate"), false, uuid));
        Model persisted;
        loadItems(persisted);
        QCOMPARE(names(persisted), QStringList({ "Original" }));
        auto database = QSqlDatabase::database();
        QVERIFY(database.transaction());
        persisted.insert(1, QStringLiteral("Unsaved"));
        QVERIFY(database.rollback());
        persisted.reload();
        QCOMPARE(names(persisted), QStringList({ "Original" }));
        QVERIFY(QSqlQuery().exec(SQL::drop().arg(defaultId)));
        persisted.insert(1, QStringLiteral("Missing table"));
        QCOMPARE(persisted.rowCount(), 2);
    }
};

} // namespace

QTEST_GUILESS_MAIN(ModelTest)
#include "test_model.moc"
