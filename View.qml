import QtQuick
import QtQuick.Controls
import QDynamics

Control {
    id: root

    property Dimensions dimensions

    background: Background {}
    contentItem: ShopView { dimensions: root.dimensions; fontFamily: awsome.name }
        dimensions: root.dimensions
        onOpenMenu: menu.open()
    resources: [ FontLoader { id: awsome; source: Qt.resolvedUrl("fa-solid-900.ttf") } ]

    Menu {
        id: menu
        dimensions: root.dimensions
        height: root.height; width: root.width * 0.66
    }
}
