#include <QtCore/QCoreApplication>
#include <QtCore/QDir>
#include <QtCore/QDebug>
#include <QtCore/QFileInfo>
#include <QtCore/QLocale>
#include <QtCore/QtLogging>
#include <QtCore/QObject>
#include <QtCore/QStandardPaths>
#include <QtCore/QString>
#include <QtCore/QTranslator>
#include <QtCore/qnamespace.h>
#include <QtCore/QUrl>
#include <QtCore/QUuid>
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlApplicationEngine>
#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlQuery>
#include <QtSql/QSqlError>
#include <QQuickStyle>
#include "model.h"

int main(int argc, char *argv[])
{

    QCoreApplication::setApplicationName(QStringLiteral("QShopper"));
    QCoreApplication::setOrganizationName(QStringLiteral("Nevala"));
    QGuiApplication application(argc, argv);

    QTranslator translator;
    const auto uiLanguages = QLocale::system().uiLanguages();
    for (const auto &locale : uiLanguages) {
        const auto baseName = QStringLiteral("QShopper_") + QLocale(locale).name();
        if (translator.load(QStringLiteral(":/i18n/") + baseName)) {
            QGuiApplication::installTranslator(&translator);
            break;
        }
    }

    const auto databaseLocation = QStringLiteral("%1/shop_list.sqlite").arg(QStandardPaths::writableLocation(QStandardPaths::AppDataLocation));
    qDebug() << "Database location: " << databaseLocation;
    const QDir dir(QFileInfo(databaseLocation).absolutePath());
    if (!dir.exists()) {
        if (!dir.mkpath(QStringLiteral("."))) {
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
        if (!query.exec(SQL::create().arg(SQL::tableLists()))) {
            qWarning() << "Failed to create  "<< SQL::tableLists() <<" table. Error: " << query.lastError();
            return -1;
        }

        if (!query.exec(SQL::selectFrom().arg(SQL::tableLists()))) {
            qWarning() << "Failed to select rows from "<< SQL::tableLists() <<" table. Error:" << query.lastError().text();
            return -1;
        }

        if (!query.next()) {
            const auto defaultTableId = QUuid::createUuid().toString(QUuid::WithoutBraces);
            if (!query.exec(SQL::create().arg(defaultTableId))) {
                qWarning() << "Failed to create  "<< SQL::tableDefault() <<" table. Error: " << query.lastError();
                return -1;
            }
            query.prepare(SQL::insertTo().arg(SQL::tableLists()));
            query.addBindValue(defaultTableId);
            query.addBindValue(SQL::tableDefault());
            query.addBindValue(false);
            if (!query.exec()) {
                qWarning() << "Failed to insert "<< SQL::tableDefault() <<" table info to "<< SQL::tableLists() << " table. Error:" << query.lastError();
                return -1;
            }
            qDebug() << SQL::tableDefault() << " table created.";
        }
    }

    QQuickStyle::setStyle("Material");
    qputenv("QT_QUICK_CONTROLS_MATERIAL_VARIANT", "Normal");

    QQmlApplicationEngine engine;
    const QUrl url(QStringLiteral("qrc:/qt/qml/QShopper/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &application, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);
    engine.load(url);
    return QGuiApplication::exec();
}
