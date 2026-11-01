#include <QtQuickTest/quicktest.h>
#include <QQmlContext>
#include <QQmlEngine>
#include <QQuickStyle>
#include <QSettings>
#include <QTemporaryDir>
#include <QSqlDatabase>
#include <QSqlQuery>
#include <QGuiApplication>
#include <QInputDevice>
#include <QPointingDevice>
#include <QTouchEvent>
#include <QWindow>
#include "model.h"

class UiSetup : public QObject
{
    Q_OBJECT
    QTemporaryDir settingsDirectory;

public:
    Q_INVOKABLE bool cancelTouch()
    {
        auto *window = QGuiApplication::focusWindow();
        if (!window) {
            return false;
        }
        bool sent = false;
        for (const auto *input : QInputDevice::devices()) {
            if (input->type() == QInputDevice::DeviceType::TouchScreen) {
                const auto *device = qobject_cast<const QPointingDevice *>(input);
                QTouchEvent cancel(QEvent::TouchCancel, device);
                QCoreApplication::sendEvent(window, &cancel);
                sent = true;
            }
        }
        return sent;
    }

    Q_INVOKABLE QVariant savedSetting(const QString &key) const
    {
        QSettings settings;
        settings.sync();
        return settings.value(key);
    }
    Q_INVOKABLE qreal restoredThemeScale() const
    {
        QQmlEngine engine;
        auto *theme = engine.singletonInstance<QObject *>("QShopper", "Theme");
        if (!theme) {
            qFatal("Cannot create Theme in a fresh engine");
        }
        return theme->property("scale").toReal();
    }
    Q_INVOKABLE QString restoredActiveList() const
    {
        QQmlEngine engine;
        auto *theme = engine.singletonInstance<QObject *>("QShopper", "Theme");
        if (!theme) {
            qFatal("Cannot create Theme in a fresh engine");
        }
        return theme->property("activeList").toString();
    }
    Q_INVOKABLE void resetDatabase()
    {
        const auto database = QSqlDatabase::database();
        QSqlQuery query(database);
        for (const auto &table : database.tables()) {
            if (!query.exec(QStringLiteral("DROP TABLE \"%1\"").arg(table))) {
                qFatal("Cannot reset UI test database");
            }
        }
        if (!query.exec(SQL::create().arg("lists"))
            || !query.exec(SQL::create().arg("11111111-1111-1111-1111-111111111111"))) {
            qFatal("Cannot create UI test tables");
        }
        query.prepare(SQL::insertTo().arg("lists"));
        query.addBindValue("11111111-1111-1111-1111-111111111111");
        query.addBindValue("default");
        query.addBindValue(false);
        if (!query.exec()) {
            qFatal("Cannot seed UI test list");
        }
    }
public slots:
    void applicationAvailable()
    {
        if (!settingsDirectory.isValid()) {
            qFatal("Cannot isolate UI test settings");
        }
        QCoreApplication::setOrganizationName("QShopperUiTests");
        QCoreApplication::setApplicationName("IsolatedRun");
        QSettings::setDefaultFormat(QSettings::IniFormat);
        QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, settingsDirectory.path());
        QQuickStyle::setStyle("Material");
        auto database = QSqlDatabase::addDatabase("QSQLITE");
        database.setDatabaseName(":memory:");
        if (!database.open()) {
            qFatal("Cannot open isolated UI database");
        }
        resetDatabase();
    }
    void qmlEngineAvailable(QQmlEngine *engine)
    {
#if !defined(Q_OS_ANDROID) && !defined(NDEBUG)
        auto *theme = engine->singletonInstance<QObject *>("QShopper", "Theme");
        theme->setProperty("scaleable", true);
#endif
        engine->rootContext()->setContextProperty("uiSetup", this);
        engine->rootContext()->setContextProperty("previewExpected", bool(QSHOPPER_EXPECT_PREVIEW));
        engine->rootContext()->setContextProperty("keyboardExpected",
                                                  bool(QSHOPPER_DESKTOP_KEYBOARD));
    }
};

QUICK_TEST_MAIN_WITH_SETUP(qshopper_ui, UiSetup)
#include "test_ui.moc"
