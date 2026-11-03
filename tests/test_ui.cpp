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
#include <QtCore/QCoreApplication>
#include <QtCore/QEvent>
#include <QtCore/QObject>
#include <QtCore/QString>
#include <QtCore/QtLogging>
#include <QtCore/QtTypes>
#include <QtCore/QVariant>
#include <QtCore/QLocale>
#include <QtCore/qtmetamacros.h>
#include "model.h"

namespace {

class UiSetup : public QObject
{
    Q_OBJECT
    QTemporaryDir settingsDirectory;

public:
    explicit UiSetup(QObject *parent = nullptr) : QObject(parent) { }

    [[nodiscard]] Q_INVOKABLE static QString exchangeLocale(const QString &name)
    {
        const auto previous = QLocale().name();
        QLocale::setDefault(QLocale(name));
        return previous;
    }

    [[nodiscard]] Q_INVOKABLE static bool cancelTouch()
    {
        auto *window = QGuiApplication::focusWindow();
        if (window == nullptr) {
            return false;
        }
        bool sent = false;
        const auto devices = QInputDevice::devices();
        for (const auto *input : devices) {
            if (input->type() == QInputDevice::DeviceType::TouchScreen) {
                const auto *device = qobject_cast<const QPointingDevice *>(input);
                QTouchEvent cancel(QEvent::TouchCancel, device);
                QCoreApplication::sendEvent(window, &cancel);
                sent = true;
            }
        }
        return sent;
    }

    [[nodiscard]] Q_INVOKABLE static QVariant savedSetting(const QString &key)
    {
        QSettings settings;
        settings.sync();
        return settings.value(key);
    }
    [[nodiscard]] Q_INVOKABLE static qreal restoredThemeScale()
    {
        QQmlEngine engine;
        auto *theme = engine.singletonInstance<QObject *>("QShopper", "Theme");
        if (theme == nullptr) {
            qFatal("Cannot create Theme in a fresh engine");
        }
        return theme->property("scale").toReal();
    }
    [[nodiscard]] Q_INVOKABLE static QString restoredActiveList()
    {
        QQmlEngine engine;
        auto *theme = engine.singletonInstance<QObject *>("QShopper", "Theme");
        if (theme == nullptr) {
            qFatal("Cannot create Theme in a fresh engine");
        }
        return theme->property("activeList").toString();
    }
    Q_INVOKABLE static void resetDatabase()
    {
        const auto database = QSqlDatabase::database();
        QSqlQuery query(database);
        const auto tables = database.tables();
        for (const auto &table : tables) {
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
    // NOLINTNEXTLINE(readability-redundant-access-specifiers): slots enables Qt setup discovery.
public Q_SLOTS:
    void applicationAvailable()
    {
        if (!settingsDirectory.isValid()) {
            qFatal("Cannot isolate UI test settings");
        }
        QCoreApplication::setOrganizationName(QStringLiteral("QShopperUiTests"));
        QCoreApplication::setApplicationName(QStringLiteral("IsolatedRun"));
        QSettings::setDefaultFormat(QSettings::IniFormat);
        QSettings::setPath(QSettings::IniFormat, QSettings::UserScope, settingsDirectory.path());
        QQuickStyle::setStyle(QStringLiteral("Material"));
        auto database = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"));
        database.setDatabaseName(QStringLiteral(":memory:"));
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
        engine->rootContext()->setContextProperty(QStringLiteral("uiSetup"), this);
        engine->rootContext()->setContextProperty(QStringLiteral("previewExpected"),
                                                  QSHOPPER_EXPECT_PREVIEW != 0);
        engine->rootContext()->setContextProperty(QStringLiteral("keyboardExpected"),
                                                  QSHOPPER_DESKTOP_KEYBOARD != 0);
    }
};

} // namespace

QUICK_TEST_MAIN_WITH_SETUP(qshopper_ui, UiSetup)
#include "test_ui.moc"
