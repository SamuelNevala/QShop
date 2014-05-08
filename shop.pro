QT += qml quick
TARGET = shop
TEMPLATE = app

ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android

SOURCES += \
    main.cpp \
    weekmodel.cpp \
    model.cpp \
    hwkeywatcher.cpp

RESOURCES += \
    res.qrc

HEADERS += \
    weekmodel.h \
    model.h \
    hwkeywatcher.h

OTHER_FILES += \
    qml/main.qml \
    qml/items/Input.qml \
    qml/items/Pulley.qml \
    qml/items/SelectableItem.qml \
    qml/items/Swipeable.qml \
    qml/items/SelectableItem.qml \
    qml/items/Weekdays.qml \
    qml/items/BackgroundItem.qml \
    qml/items/TextItem.qml \
    qml/items/InputItem.qml \
    qml/items/DragableItem.qml \
    qml/styles/TextFieldStyleAndroid.qml \
    qml/items/RemorseItem.qml \
    qml/items/IconButton.qml \
    qml/views/View.qml \
    qml/items/SideBar.qml \
    qml/items/Setting.qml

OTHER_FILES += \
    android/AndroidManifest.xml
