import QtQuick.Controls.Material
import QtQuick
import QDynamics

RoundButton {
    id: root

    property Dimensions dimensions

    bottomInset: dimensions.mm(3)
    contentItem: Item {
        TextIcon {
            anchors { centerIn: parent; verticalCenterOffset: -root.dimensions.mm(1.5) }
            height: parent.height * 0.5; width: parent.width * 0.5
            font { family: root.font.family }
            text: root.icon.name
            color: !root.enabled ? Material.hintTextColor :
                root.flat && root.highlighted ? Material.accentColor :
                root.highlighted ? Material.primaryHighlightedTextColor : Material.foreground
        }
        TextItem {
            anchors { centerIn: parent; verticalCenterOffset: root.dimensions.mm(4) }
            dimensions: root.dimensions
            color: Material.foreground
            height: root.dimensions.mm(3)
            text: root.text
        }
    }
    implicitWidth: Math.max(dimensions.mm(8) + leftInset + rightInset, dimensions.mm(8) + leftPadding + rightPadding)
    implicitHeight: Math.max(dimensions.mm(8) + topInset + bottomInset, dimensions.mm(8) + topPadding + bottomPadding)
    leftInset: 0
    padding: 0
    rightInset: 0
    spacing: 0
    topInset: 0
}
