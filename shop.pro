QT += qml quick
TARGET = shop
TEMPLATE = app
 CONFIG += c++11
include(src/src.pri)
include(qml/qml.pri)
include(android.pri)

debug: RESOURCES += qml_debug.qrc
release: RESOURCES += qml.qrc
RESOURCES += images.qrc
