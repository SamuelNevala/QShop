import QtQuick
import QtQuick.Controls.Material as Controls
import QtQuick.Layouts

pragma ComponentBehavior: Bound

ComboBox {
    id: root

    property var colorFunction: Theme.color

    contentItem: RowLayout {
        spacing: Theme.pixels(1.5)
        layoutDirection: root.mirrored ? Qt.RightToLeft : Qt.LeftToRight

        Rectangle {
            implicitWidth: Theme.pixels(5)
            implicitHeight: Theme.pixels(5)
            radius: width / 2
            border.width: Theme.pixels(0.2)
            border.color: root.Controls.Material.theme === Controls.Material.Dark ? "#b3ffffff" : "#99000000"
            color: root.colorFunction(root.currentValue)
            Layout.alignment: Qt.AlignVCenter
        }
        Text {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            text: root.currentText
            font: root.font
            color: root.enabled ? root.Controls.Material.foreground
                : root.Controls.Material.hintTextColor
            horizontalAlignment: root.mirrored ? Text.AlignRight : Text.AlignLeft
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }
    }

    delegate: Controls.ItemDelegate {
        id: delegate

        required property var model
        required property int index

        width: ListView.view.width
        implicitHeight: root.rowHeight
        padding: root.padding
        verticalPadding: Theme.pixels(1)
        font: root.font
        text: model[root.textRole]
        highlighted: root.highlightedIndex === index
        hoverEnabled: root.hoverEnabled
        Controls.Material.foreground: root.currentIndex === index
            ? root.Controls.Material.accent : root.Controls.Material.foreground

        contentItem: RowLayout {
            spacing: Theme.pixels(1.5)
            layoutDirection: root.mirrored ? Qt.RightToLeft : Qt.LeftToRight

            Rectangle {
                implicitWidth: Theme.pixels(5)
                implicitHeight: Theme.pixels(5)
                radius: width / 2
                border.width: Theme.pixels(0.2)
                border.color: root.Controls.Material.theme === Controls.Material.Dark ? "#b3ffffff" : "#99000000"
                color: root.colorFunction(delegate.model[root.valueRole])
                Layout.alignment: Qt.AlignVCenter
            }
            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: delegate.text
                font: delegate.font
                color: delegate.enabled ? delegate.Controls.Material.foreground
                    : delegate.Controls.Material.hintTextColor
                horizontalAlignment: root.mirrored ? Text.AlignRight : Text.AlignLeft
                elide: Text.ElideRight
                textFormat: Text.PlainText
            }
        }
    }

    Binding {
        target: root.popup.background
        property: "color"
        value: root.Controls.Material.theme === Controls.Material.Dark
            ? "#202020" : root.Controls.Material.dialogColor
    }

    model: ColorModel {}
    textRole: "text"
    valueRole: "color"
}
