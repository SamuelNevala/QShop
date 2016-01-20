#include <QtQml>
#include <QtGui/QGuiApplication>
#include <QtGui/QStyleHints>
#include <QtQuick/QQuickView>
#include <QtCore/QString>
#include <QDebug>
#include "weekmodel.h"
#include "model.h"
#include "voice.h"
#include "theme.h"
#include "elapsedtimer.h"
#include "backkey.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    app.setApplicationName("Lister");
    app.setOrganizationName("Nevala");

    qmlRegisterType<WeekModel>("Shop.models", 1, 0, "WeekModel");
    qmlRegisterType<Model>("Shop.models", 1, 0, "ItemModel");
    qmlRegisterType<Voice>("Shop.extra", 1, 0, "Voice");
    qmlRegisterType<Theme>("Shop.extra", 1, 0, "Theme");
    qmlRegisterType<BackKey>("Shop.extra", 1, 0, "BackKey");
    qmlRegisterType<ElapsedTimer>("Shop.timer", 1, 0, "ElapsedTimer");

    QQmlApplicationEngine engine;
    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
    return app.exec();
}
