#include <QtCore/QCoreApplication>
#include <QtCore/QDir>
#include <QtCore/QDebug>
#include <QtCore/QFileInfo>
#include <QtCore/QLocale>
#include <QtCore/QtLogging>
#include <QtCore/QObject>
#include <QtCore/QStandardPaths>
#include <QtCore/QSettings>
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

#if defined(Q_OS_ANDROID)
#include <QtCore/QJniObject>
#include <QtCore/qcoreapplication_platform.h>
#include <QtGui/QInputMethod>
#include <QtQuick/QQuickWindow>

static void updateSystemBarIcons(const QColor &color)
{
    const bool light = color.lightnessF() > 0.5;
    QNativeInterface::QAndroidApplication::runOnAndroidMainThread([light] {
        if (!QNativeInterface::QAndroidApplication::isActivityContext()) {
            return;
        }
        const QJniObject activity = QNativeInterface::QAndroidApplication::context();
        const auto window = activity.callObjectMethod("getWindow", "()Landroid/view/Window;");
        if (!window.isValid()) {
            return;
        }
        if (QNativeInterface::QAndroidApplication::sdkVersion() >= 30) {
            const auto controller = window.callObjectMethod("getInsetsController",
                "()Landroid/view/WindowInsetsController;");
            if (controller.isValid()) {
                const auto mask = QJniObject::getStaticField<jint>("android/view/WindowInsetsController",
                    "APPEARANCE_LIGHT_STATUS_BARS")
                    | QJniObject::getStaticField<jint>("android/view/WindowInsetsController",
                        "APPEARANCE_LIGHT_NAVIGATION_BARS");
                controller.callMethod<void>("setSystemBarsAppearance", "(II)V", light ? mask : 0, mask);
            }
        } else {
            // Android 9/10 use the earlier API; retain every unrelated UI flag.
            const auto decor = window.callObjectMethod("getDecorView", "()Landroid/view/View;");
            if (decor.isValid()) {
                const auto mask = QJniObject::getStaticField<jint>("android/view/View",
                    "SYSTEM_UI_FLAG_LIGHT_STATUS_BAR")
                    | QJniObject::getStaticField<jint>("android/view/View",
                        "SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR");
                const auto flags = decor.callMethod<jint>("getSystemUiVisibility");
                decor.callMethod<void>("setSystemUiVisibility", "(I)V", light ? flags | mask : flags & ~mask);
            }
        }
    });
}
#endif

int main(int argc, char *argv[])
{


    QCoreApplication::setApplicationName(QStringLiteral("QShopper"));
    QCoreApplication::setOrganizationName(QStringLiteral("Nevala"));
#if QSHOPPER_DESKTOP_KEYBOARD && !defined(Q_OS_ANDROID)
    qputenv("QT_IM_MODULE", "qtvirtualkeyboard");
    qputenv("QT_VIRTUALKEYBOARD_DESKTOP_DISABLE", "1");
#endif
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

    // Automated runs can use disposable data and settings without touching the user's lists.
    const auto testDataDirectory = qEnvironmentVariable("QSHOPPER_DATA_DIR");
    if (!testDataDirectory.isEmpty()) {
        QSettings::setDefaultFormat(QSettings::IniFormat);
        QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, testDataDirectory);
    }
    const auto dataDirectory = testDataDirectory.isEmpty()
        ? QStandardPaths::writableLocation(QStandardPaths::AppDataLocation)
        : testDataDirectory;
    const auto databaseLocation = QDir(dataDirectory).filePath(QStringLiteral("shop_list.sqlite"));
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
#if !defined(Q_OS_ANDROID) && !defined(NDEBUG)
    auto *theme = engine.singletonInstance<QObject *>("QShopper", "Theme");
    theme->setProperty("scaleable", true);
#endif
    const QUrl url(QStringLiteral("qrc:/qt/qml/QShopper/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &application, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl) {
            QCoreApplication::exit(-1);
        }
    }, Qt::QueuedConnection);
#if defined(Q_OS_ANDROID)
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
        &application, [](QObject *object, const QUrl &) {
            auto *window = qobject_cast<QQuickWindow *>(object);
            if (!window) {
                return;
            }
            const auto update = [window] { updateSystemBarIcons(window->color()); };
            QObject::connect(window, &QQuickWindow::colorChanged, window, update);
            QObject::connect(qGuiApp->inputMethod(), &QInputMethod::visibleChanged, window, update);
            QObject::connect(qGuiApp, &QGuiApplication::applicationStateChanged, window,
                [update](Qt::ApplicationState state) {
                    if (state == Qt::ApplicationActive) {
                        update();
                    }
                });
            update();
        });
#endif
    engine.load(url);
    return QGuiApplication::exec();
}
