#include <QtGui/QGuiApplication>
#include <QtGui/QStyleHints>
#include <QtQuick/QQuickItem>
#include "qtquick2applicationviewer.h"
#include <QDebug>
#include "weekmodel.h"
#include "model.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    qmlRegisterType<WeekModel>("Shop.models", 1, 0, "WeekModel");
    qmlRegisterType<Model>("Shop.models", 1, 0, "ItemModel");

    QtQuick2ApplicationViewer viewer;
    viewer.setMainQmlFile(QStringLiteral("qml/shop/main.qml"));
    viewer.showExpanded();
    viewer.rootObject()->setProperty("dragDistance", app.styleHints()->startDragDistance());
    return app.exec();
}
