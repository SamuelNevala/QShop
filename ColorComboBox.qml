pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Material as Controls
import QtQuick.Layouts

ComboBox {
    id: root

    property var colorFunction: Theme.color

    textRole: "text"
    valueRole: "color"

    contentItem: ColorContent {
        swatchColor: root.colorFunction(root.currentValue)
        text: root.currentText
        font: root.font
        textColor: root.enabled ? root.Controls.Material.foreground :
                                  root.Controls.Material.hintTextColor
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
        Controls.Material.foreground: root.currentIndex === index ? root.Controls.Material.accent :
                                                                    root.Controls.Material.foreground

        contentItem: ColorContent {
            swatchColor: root.colorFunction(delegate.model[root.valueRole])
            text: delegate.text
            font: delegate.font
            textColor: delegate.enabled ? delegate.Controls.Material.foreground :
                                          delegate.Controls.Material.hintTextColor
        }
    }
    model: ColorModel {}

    Binding {
        target: root.popup.background
        property: "color"
        value: root.Controls.Material.theme === Controls.Material.Dark ? "#202020" :
                                                                         root.Controls.Material.dialogColor
    }

    component ColorContent: RowLayout {
        property alias swatchColor: swatch.color
        property alias text: caption.text
        property alias font: caption.font
        property alias textColor: caption.color

        spacing: Theme.pixels(1.5)
        layoutDirection: root.mirrored ? Qt.RightToLeft : Qt.LeftToRight

        Rectangle {
            id: swatch

            implicitWidth: Theme.pixels(5)
            implicitHeight: Theme.pixels(5)
            radius: width / 2
            border.width: Theme.pixels(0.2)
            border.color: root.Controls.Material.theme === Controls.Material.Dark ? "#b3ffffff" :
                                                                                    "#99000000"
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            id: caption

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            horizontalAlignment: root.mirrored ? Text.AlignRight : Text.AlignLeft
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }
    }
}
