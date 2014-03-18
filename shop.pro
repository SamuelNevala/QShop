QT += qml quick
TARGET = shop
TEMPLATE = app

SOURCES += \
    main.cpp \
    weekmodel.cpp \
    model.cpp

RESOURCES += \
    res.qrc

HEADERS += \
    weekmodel.h \
    model.h

OTHER_FILES += \
    qml/main.qml \
    qml/items/Input.qml \
    qml/items/Pulley.qml \
    qml/items/SelectableItem.qml \
    qml/items/Swipeable.qml \
    qml/items/SelectableItem.qml \
    qml/views/ShopView.qml \
    qml/views/EditView.qml \
    qml/items/Weekdays.qml \
    qml/items/BackgroundItem.qml \
    qml/items/TextItem.qml \
    qml/items/InputItem.qml \
    qml/items/DragableItem.qml \
    qml/styles/TextFieldStyleAndroid.qml \
    qml/items/BackButton.qml
