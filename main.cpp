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
    QQmlEngine engine;

    app.setApplicationName("shop");
    app.setOrganizationName("Kellonevala");

    qmlRegisterType<WeekModel>("Shop.models", 1, 0, "WeekModel");
    qmlRegisterType<Model>("Shop.models", 1, 0, "ItemModel");
    qmlRegisterType<HwKeyWatcher>("Shop.extra", 1, 0, "HwKeyWatcher");

    QQmlComponent component(&engine);
    component.loadUrl(QUrl("qrc:/qml/main.qml"));
    if ( !component.isReady() ) {
        qWarning("%s", qPrintable(component.errorString()));
        return -1;
    }
    QObject *topLevel = component.create();
    QQuickWindow *window = qobject_cast<QQuickWindow *>(topLevel);
    if ( !window ) {
        qWarning("Error: Your root item has to be a Window.");
        return -2;
    }
    window->setProperty("dragDistance", app.styleHints()->startDragDistance());
    QObject::connect(&engine, SIGNAL(quit()), &app, SLOT(quit()));

#if defined(Q_OS_ANDROID)
    window->showFullScreen();
#else
    window->show();
#endif

    return app.exec();
}
