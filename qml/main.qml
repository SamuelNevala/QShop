import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Window 2.1
import QtGraphicalEffects 1.0
import Shop.models 1.0
import "views"
import "styles"

ApplicationWindow {
    id: applicationWindow

    property int dragDistance
    property bool stopAnimation

    height: 1280; width: 768

    QtObject {
        id: constants
        property int pixelDensity: Screen.pixelDensity > 0 ? Screen.pixelDensity : 332
        property real maxHeight: pixelDensity * 0.37
        property real minHeight: pixelDensity * 0.27
        property int mediumTime: stopAnimation ? 0 : 250
        property int longTime: stopAnimation ? 0 : 500
    }

    ItemModel { id: itemModel }

    Image { anchors.fill: parent; source: "qrc:/pic/bg" }

    StackView {
        id: pageSwitcher
        anchors.fill: parent
        initialItem: {"item": Qt.resolvedUrl("views/ShopView.qml"), properties: {model: itemModel}}
        Component.onCompleted: if (itemModel.count == 1) pageSwitcher.push({
                                                            "item": Qt.resolvedUrl("views/EditView.qml"),
                                                            properties: {model: itemModel},
                                                            immediate: true})
    }
}
