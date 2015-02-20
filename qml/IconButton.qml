import QtQuick 2.4
import QtQuick.Controls 1.3
import QtGraphicalEffects 1.0

Item {
    id: root

    property alias source: button.source
    property alias drag: mouseArea.drag
    property alias pressed: mouseArea.pressed
    property bool overlayVisible: false

    signal clicked(QtObject mouse)

    visible: enabled

    Image {
        id: button
        anchors.fill: parent
        asynchronous: true
        opacity: status == Image.Ready ? 1.0 : 0.0
        visible: opacity > 0.0
        Behavior on opacity { NumberAnimation { easing.type: Easing.InOutQuad } }
    }

    ColorOverlay {
        anchors { fill: button }
        color: "#33B5E5"
        source: button
        opacity: mouseArea.pressed || overlayVisible ? 1.0 : 0.0
        visible: opacity > 0.0
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.enabled
        onClicked: root.clicked(mouse)
    }
}
