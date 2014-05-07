#include <QtQml>
#include <QtGui/QGuiApplication>
#include <QtGui/QStyleHints>
#include <QtQuick/QQuickView>
#include <QtCore/QString>
#include <QDebug>
#include "weekmodel.h"
#include "model.h"
#include "hwkeywatcher.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("shop");
    app.setOrganizationName("Kellonevala");

    qmlRegisterType<WeekModel>("Shop.models", 1, 0, "WeekModel");
    qmlRegisterType<Model>("Shop.models", 1, 0, "ItemModel");
    qmlRegisterType<HwKeyWatcher>("Shop.extra", 1, 0, "HwKeyWatcher");

    QQmlApplicationEngine engine;
    engine.load(QUrl("qrc:/qml/main.qml"));
    engine.rootObjects()[0]->setProperty("dragDistance", app.styleHints()->startDragDistance());
    return app.exec();
}
