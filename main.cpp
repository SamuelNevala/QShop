#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include <QLocale>
#include <QTranslator>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QSqlError>
#include <QStandardPaths>
#include <QDir>
#include <QFileInfo>
// #include <QAbstractListModel>
// #include <QtCore/QProcessEnvironment>
// #include "elapsedtimer.h"
// #include "model.h"
// #include "weekmodel.h"

static const QString createTable = "CREATE TABLE IF NOT EXISTS shop_list ("
                                   "id TEXT PRIMARY KEY NOT NULL,"
                                   "name TEXT NOT NULL,"
                                   "checked INTEGER NOT NULL DEFAULT 0)";


int main(int argc, char *argv[])
{
    // QProcessEnvironment env = QProcessEnvironment::systemEnvironment();
    // env.insert("QML_IMPORT_TRACE", "1");
    // //qputenv("QT_IM_MODULE", QByteArray("qtvirtualkeyboard"));
    QCoreApplication::setApplicationName("QShopper");
    QCoreApplication::setOrganizationName("Nevala");
    QGuiApplication app(argc, argv);


    // qmlRegisterAnonymousType<QAbstractListModel, 254>("QShopper", 1);
    // qmlRegisterUncreatableType<QAbstractListModel>("QtQml.Models", 2, 0, "QAbstractListModel", "Abstract base class");

    // qmlRegisterType<Model>("Shop.models", 1, 0, "ItemModel");
    // qmlRegisterType<WeekModel>("Shop.models", 1, 0, "WeekModel");
    // qmlRegisterType<ElapsedTimer>("Shop.timer", 1, 0, "ElapsedTimer");

    QTranslator translator;
    const auto uiLanguages = QLocale::system().uiLanguages();
    for (const auto &locale : uiLanguages) {
        const auto baseName = "QShopper_" + QLocale(locale).name();
        if (translator.load(":/i18n/" + baseName)) {
            app.installTranslator(&translator);
            break;
        }
    }

    const auto databaseLocation = QString("%1/shop_list.sqlite").arg(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation));
    qDebug() << "Database location: " << databaseLocation;
    QDir dir(QFileInfo(databaseLocation).absolutePath());
    if (!dir.exists()) {
        if (!dir.mkpath(".")) {
            qDebug() << "Failed to create directory for database. Name: " << databaseLocation;
            return -1;
        }
    }

    auto database = QSqlDatabase::addDatabase("QSQLITE");
    database.setDatabaseName(databaseLocation);
    if (!database.open()) {
        qWarning() << "Failed to open to the database. Error: " << database.lastError() << " Name: " << databaseLocation;
        return -1;
    }

    QSqlQuery query;
    if (!query.exec(createTable)) {
        qDebug() << "Failed to create table. Error: " << query.lastError();
        return -1;
    }

    QQmlApplicationEngine engine;
    // engine.addImportPath("C:/Qt/6.8.0/msvc2022_64/qml/QuickDynamics");
    qDebug() << "ImportPaths: " << engine.importPathList();
    // engine.addPluginPath("C:/Qt/6.8.0/msvc2022_64/qml/QuickDynamics");
    // qDebug() << "pluginPathList: " << engine.pluginPathList();
    const QUrl url("qrc:/qt/qml/QShopper/main.qml");
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
