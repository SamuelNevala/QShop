import QtQuick
import QtQuick.Controls.Material as Controls
import QtQuick.Layouts

pragma ComponentBehavior: Bound

ComboBox {
    id: root

    property var colorFunction: ThemeManager.color

    contentItem: Controls.Control {
        bottomPadding: Controls.Material.textFieldVerticalPadding
        contentItem: RowLayout {
            spacing: root.dimensions.mm(1)

            Rectangle {
                color: root.colorFunction(root.currentValue)
                implicitWidth: height
                radius: Controls.Material.FullScale
                Layout.fillHeight: true;
            }

            Text {
                color: Controls.Material.foreground
                font: root.font
                elide: Text.ElideRight
                text: root.currentText
                verticalAlignment: Text.AlignVCenter
                Layout.fillHeight: true; Layout.fillWidth: true
            }

            Layout.margins: root.dimensions.mm(1)
        }
        implicitHeight: Controls.Material.textFieldHeight
        implicitWidth: 120
        topPadding: Controls.Material.textFieldVerticalPadding
    }

    delegate: Controls.ItemDelegate {
        id: delegate

        required property var model
        required property int index

        contentItem: RowLayout {
            spacing: root.dimensions.mm(1)

            Rectangle {
                color: root.colorFunction(delegate.model[root.valueRole])
                implicitHeight: parent.height
                implicitWidth: height
                radius: Controls.Material.FullScale
            }

            Text {
                text: delegate.model[root.textRole]
                color: root.currentIndex === delegate.index ? Controls.Material.accent : Controls.Material.foreground
                font: root.font
                elide: Text.ElideRight
                Layout.fillHeight: true; Layout.fillWidth: true
            }
            Layout.margins: root.dimensions.mm(1)
        }
        highlighted: root.highlightedIndex === index
        width: root.width
    }

    leftPadding: Controls.Material.textFieldVerticalPadding
    model: ColorModel {}
    textRole: "text"
    valueRole: "color"
}
