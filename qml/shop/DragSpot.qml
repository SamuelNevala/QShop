import QtQuick 2.0

Item {
    property Item target
    property bool dragEnabled
    property alias dragArea: dragArea

    opacity: dragArea.enabled //&& !dragArea.drag.active ? 1.0 : 0.0
    visible: opacity > 0.0

    Behavior on opacity { NumberAnimation {} }

    /*Image {
        id: icon
        anchors.fill: parent
        source: "qrc:/pic/drag1"
        smooth: true
        opacity: dragArea.pressed ? 0.0: 1.0
        visible: opacity > 0.0
        Behavior on opacity { NumberAnimation {} }
    }*/

    Rectangle {
        id: icon
        anchors.fill: parent
        color: "darkred"
        smooth: true
        opacity: dragArea.pressed ? 0.0: 0.8
        visible: opacity > 0.0
        Behavior on opacity { NumberAnimation {} }
    }


    MouseArea {
        id: dragArea
        anchors { fill: parent }
        enabled: dragEnabled
        drag { target: target }
        width: height
        /*        Rectangle {
            anchors {
                fill: parent
                //margins: 10
            }
            color: "green"
            opacity: dragArea.enabled && !dragArea.drag.active ? 1.0 : 0.0
            visible: opacity > 0.0
            Behavior on opacity { NumberAnimation {} }
        }*/
    }
}
