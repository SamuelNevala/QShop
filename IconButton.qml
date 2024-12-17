import QtQuick.Controls.Material
import QtQuick
import QDynamics

AbstractButton {
    id: root

    property Dimensions dimensions

    implicitHeight: dimensions.mm(15)
    implicitWidth: dimensions.mm(15)

    bottomPadding: height * 0.2

    contentItem: Item {
        Rectangle {
            anchors { centerIn: parent }
            height: parent.height * 0.8; width:  parent.height * 0.8
            color: root.checked ? Material.primary: Material.frameColor
            radius: Material.FullScale
            Behavior on color { ColorAnimation {} }

            TextIcon {
                anchors { centerIn: parent }
                color: Material.primaryTextColor
                height: parent.height * 0.8; width: parent.width * 0.8
                font { family: root.font.family }
                text: root.icon.name
            }
        }
    }
    background: TextIcon {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        color: Material.foreground
        height: parent.height * 0.2
        text: root.text
    }
}
