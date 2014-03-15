import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Window 2.1
import QtGraphicalEffects 1.0
import Shop.models 1.0
import "views"

ApplicationWindow {
    id: applicationWindow

    property int dragDistance
    property bool skipMoveTransition

    height: 1280; width: 768

    QtObject {
        id: constants
        property int pixelDensity: Screen.pixelDensity > 0 ? Screen.pixelDensity : 332
        property real delegateHeight: pixelDensity * 0.37
    }

    ItemModel { id: itemModel }

    Image { anchors.fill: parent; source: "qrc:/pic/bg" }

    StackView {
        id: pageSwitcher
        anchors.fill: parent
        initialItem: {"item": Qt.resolvedUrl("views/ShopView.qml"), properties: {model: itemModel}}
        Component.onCompleted: if (itemModel.count == 0) pageSwitcher.push({
                                                            "item": Qt.resolvedUrl("views/EditView.qml"),
                                                            properties: {model: itemModel},
                                                            immediate: true})
    }
}
