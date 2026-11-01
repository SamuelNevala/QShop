import QtQuick
import QtQuick.Controls.Material

RoundButton {
    id: root

    property alias maximumLineCount: caption.maximumLineCount

    implicitWidth: Theme.pixels(8)
    implicitHeight: Theme.pixels(8) + bottomInset
    bottomInset: caption.height
    leftInset: Math.max(0, (width - Theme.pixels(8)) / 2)
    rightInset: leftInset
    topInset: 0
    padding: 0
    spacing: 0

    contentItem: Item {
        TextIcon {
            x: (parent.width - width) / 2
            y: (Theme.pixels(8) - height) / 2
            height: Theme.pixels(5.5)
            width: Theme.pixels(5.5)
            font.family: root.font.family
            text: root.icon.name
            color: !root.enabled ? Material.hintTextColor : root.flat && root.highlighted
                                   ? Material.accentColor : root.highlighted
                                     ? Material.primaryHighlightedTextColor : Material.foreground
        }

        Text {
            id: caption

            x: (parent.width - width) / 2
            y: Theme.pixels(8)
            width: maximumLineCount > 1 ? root.width : Math.max(root.width, Theme.pixels(14))
            height: Theme.pixels(3 * maximumLineCount)
            text: root.text
            color: Material.foreground
            font.bold: true
            font.pixelSize: Theme.pixels(2.5)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignTop
            lineHeightMode: Text.FixedHeight
            lineHeight: Theme.pixels(3)
            maximumLineCount: 1
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }
    }
}
