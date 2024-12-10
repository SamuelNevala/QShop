import QtQuick
import QtQuick.Controls
import QDynamics

Control {
    id: root

    property Dimensions dimensions

    background: Background {}
    contentItem: ShopView { dimensions: root.dimensions; fontFamily: awsome.name }
    resources: [ FontLoader { id: awsome; source: Qt.resolvedUrl("fa-solid-900.ttf") } ]
}
