import QtQuick
import QtQuick.Controls.Material as Controls
import QtQuick.Layouts

pragma ComponentBehavior: Bound

ComboBox {
    id: root

    property var colorFunction: ThemeManager.color

    contentItem: Controls.Control {
        bottomPadding: Controls.Material.textFieldVerticalPadding
        contentItem: FlexboxLayout {
            direction: FlexboxLayout.Row
            gap: root.dimensions.mm(1)
            justifyContent: FlexboxLayout.JustifySpaceBetween

            Rectangle {
                color: root.colorFunction(root.currentValue)
                implicitWidth: height
                radius: Controls.Material.FullScale
                Layout.fillHeight: true;
            }
            TextItem {
                color: Controls.Material.foreground
                font: root.font
                text: root.currentText
                Layout.fillHeight: true; Layout.fillWidth: true
            }
        }

        implicitHeight: Controls.Material.textFieldHeight
        topPadding: Controls.Material.textFieldVerticalPadding
    }

    delegate: Controls.ItemDelegate {
        id: delegate

        required property var model
        required property int index

        contentItem: FlexboxLayout {
            direction: FlexboxLayout.Row
            gap: root.dimensions.mm(1)
            justifyContent: FlexboxLayout.JustifySpaceBetween

            Rectangle {
                color: root.colorFunction(delegate.model[root.valueRole])
                implicitHeight: parent.height
                implicitWidth: height
                radius: Controls.Material.FullScale
            }
            TextItem {
                color: root.currentIndex === delegate.index ? Controls.Material.accent : Controls.Material.foreground
                font: root.font
                text: delegate.model[root.textRole]
                Layout.fillHeight: true; Layout.fillWidth: true
            }
        }

        highlighted: root.highlightedIndex === index
        width: root.width
    }

    leftPadding: Controls.Material.textFieldVerticalPadding
    model: ColorModel {}
    textRole: "text"
    valueRole: "color"
}
