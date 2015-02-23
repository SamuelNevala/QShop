#include <QtQml>
#include <QtGui/QGuiApplication>
#include <QtGui/QStyleHints>
#include <QtQuick/QQuickView>
#include <QtCore/QString>
#include <QDebug>
#include "weekmodel.h"
#include "model.h"
#include "hwkeywatcher.h"
#include "theme.h"
#include "qmlelapsedtimer.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("Lister");
    app.setOrganizationName("Nevala");

    qmlRegisterType<WeekModel>("Shop.models", 1, 0, "WeekModel");
    qmlRegisterType<Model>("Shop.models", 1, 0, "ItemModel");
    qmlRegisterType<HwKeyWatcher>("Shop.extra", 1, 0, "HwKeyWatcher");
    qmlRegisterType<Theme>("Shop.extra", 1, 0, "Theme");
    qmlRegisterType<QmlElapsedTimer>("Shop.timer", 1, 0, "ElapsedTimer");

    QQmlApplicationEngine engine;
#ifdef QT_DEBUG
    engine.load(QUrl(QStringLiteral("qrc:/qml/main_debug.qml")));
#else
    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
#endif
    engine.rootObjects()[0]->setProperty("dragDistance", app.styleHints()->startDragDistance());
    return app.exec();
}
