import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1
import QtGraphicalEffects 1.0

Item {
    id: root
    signal clicked()

    ToolButton {
        id: button
        anchors.fill: parent
        iconSource: "qrc:/pic/previous"
        style: ButtonStyle { background: Item {} }
        onClicked: root.clicked()
    }

    ColorOverlay {
        anchors { fill: button }
        color: "#33B5E5"
        source: button
        opacity: button.pressed ? 1.0 : 0.0
        visible: opacity > 0.0
        Behavior on opacity { NumberAnimation {duration: 150; easing.type: Easing.InOutQuad } }
    }
}
