#include <QtQuickTest/quicktest.h>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickStyle>
#include <QSettings>
#include <QTemporaryDir>
#include <QSqlDatabase>
#include <QSqlQuery>
#include "model.h"

class UiSetup : public QObject
{
    Q_OBJECT
    QTemporaryDir settingsDirectory;
public:
    Q_INVOKABLE void resetDatabase()
    {
        const auto database = QSqlDatabase::database();
        QSqlQuery query(database);
        for (const auto &table : database.tables())
            if (!query.exec(QStringLiteral("DROP TABLE \"%1\"").arg(table)))
                qFatal("Cannot reset UI test database");
        if (!query.exec(SQL::create().arg("lists"))
            || !query.exec(SQL::create().arg("11111111-1111-1111-1111-111111111111")))
            qFatal("Cannot create UI test tables");
        query.prepare(SQL::insertTo().arg("lists"));
        query.addBindValue("11111111-1111-1111-1111-111111111111");
        query.addBindValue("default");
        query.addBindValue(false);
        if (!query.exec()) qFatal("Cannot seed UI test list");
    }
public slots:
    void applicationAvailable()
    {
        if (!settingsDirectory.isValid()) qFatal("Cannot isolate UI test settings");
        QCoreApplication::setOrganizationName("QShopperUiTests");
        QCoreApplication::setApplicationName("IsolatedRun");
        QSettings::setDefaultFormat(QSettings::IniFormat);
        QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, settingsDirectory.path());
        QQuickStyle::setStyle("Material");
        auto database = QSqlDatabase::addDatabase("QSQLITE");
        database.setDatabaseName(":memory:");
        if (!database.open()) qFatal("Cannot open isolated UI database");
        resetDatabase();
    }
    void qmlEngineAvailable(QQmlEngine *engine)
    {
        engine->rootContext()->setContextProperty("uiSetup", this);
    }
};

QUICK_TEST_MAIN_WITH_SETUP(qshopper_ui, UiSetup)
#include "test_ui.moc"
