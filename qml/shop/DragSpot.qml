import QtQuick 2.0

Item {
    property Item target
    property bool dragEnabled
    property alias dragArea: dragArea
    property alias pressed: dragArea.pressed

    opacity: dragArea.enabled ? 1.0 : 0.0
    visible: opacity > 0.0

    Behavior on opacity { NumberAnimation {} }

    Rectangle {
        id: icon
        anchors.fill: parent
        color: "darkred"
        opacity: 0.8
    }

    MouseArea {
        id: dragArea
        anchors { fill: parent }
        enabled: dragEnabled
        drag { target: target }
        width: height
    }
}
