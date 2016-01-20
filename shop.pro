QT += qml quick
TARGET = shop
TEMPLATE = app
 CONFIG += c++11
include(src/src.pri)
include(qml/qml.pri)
include(android.pri)

RESOURCES += qml.qrc
RESOURCES += images.qrc
