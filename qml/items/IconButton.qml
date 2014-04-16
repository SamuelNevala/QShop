import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtGraphicalEffects 1.0

Item {
    id: root

    property alias source: button.source

    signal clicked()

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
        opacity: mouseArea.pressed ? 1.0 : 0.0
        visible: opacity > 0.0
        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.InOutQuad } }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
