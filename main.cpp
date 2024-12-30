#include <QtCore/QUuid>
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
#include "model.h"

int main(int argc, char *argv[])
{
    QCoreApplication::setApplicationName(QStringLiteral("QShopper"));
    QCoreApplication::setOrganizationName(QStringLiteral("Nevala"));
    QGuiApplication app(argc, argv);

    QTranslator translator;
    const auto uiLanguages = QLocale::system().uiLanguages();
    for (const auto &locale : uiLanguages) {
        const auto baseName = "QShopper_" + QLocale(locale).name();
        if (translator.load(":/i18n/" + baseName)) {
            app.installTranslator(&translator);
            break;
        }
    }

    const auto databaseLocation = QStringLiteral("%1/shop_list.sqlite").arg(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation));
    qDebug() << "Database location: " << databaseLocation;
    QDir dir(QFileInfo(databaseLocation).absolutePath());
    if (!dir.exists()) {
        if (!dir.mkpath(".")) {
            qWarning() << "Failed to create directory for database. Name: " << databaseLocation;
            return -1;
        }
    }

    auto database = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"));
    database.setDatabaseName(databaseLocation);
    if (!database.open()) {
        qWarning() << "Failed to open to the database. Error: " << database.lastError() << " Name: " << databaseLocation;
        return -1;
    }

    {
        QSqlQuery query;
        if (!query.exec(kCreate.arg(kListsTable))) {
            qWarning() << "Failed to create  "<< kListsTable <<" table. Error: " << query.lastError();
            return -1;
        }

        if (!query.exec(kSelectFrom.arg(kListsTable))) {
            qWarning() << "Failed to select rows from "<< kListsTable <<" table. Error:" << query.lastError().text();
            return -1;
        }

        if (!query.next()) {
            const auto defaultTableId = QUuid::createUuid().toString(QUuid::WithoutBraces);
            if (!query.exec(kCreate.arg(defaultTableId))) {
                qWarning() << "Failed to create  "<< kDefaultTable <<" table. Error: " << query.lastError();
                return -1;
            }
            query.prepare(kInsertTo.arg(kListsTable));
            query.addBindValue(defaultTableId);
            query.addBindValue(kDefaultTable);
            query.addBindValue(false);
            if (!query.exec()) {
                qWarning() << "Failed to insert "<< kDefaultTable <<" table info to "<< kListsTable << " table. Error:" << query.lastError();
                return -1;
            }
            qDebug() << kDefaultTable << " table created.";
        }
    }

    QQmlApplicationEngine engine;
    const QUrl url("qrc:/qt/qml/QShopper/main.qml");
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);
    engine.load(url);
    return app.exec();
}
