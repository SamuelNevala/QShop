import QtQuick
import QtQuick.Controls.Material as Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

RoundButton {
    id: root

    readonly property bool textUnderIcon: display === Controls.AbstractButton.TextUnderIcon
    readonly property bool circularBackground: textUnderIcon || display
                                               === Controls.AbstractButton.IconOnly
    readonly property real iconDiameter: Theme.pixels(8)
    // Reserve the last caption line even when the layout rounds to whole pixels.
    readonly property real captionHeight: Math.ceil(caption.implicitHeight)

    implicitWidth: circularBackground ? iconDiameter : Math.max(iconDiameter,
                                                                contentItem.implicitWidth)
    implicitHeight: textUnderIcon ? iconDiameter + captionHeight : Math.max(iconDiameter,
                                                                            contentItem.implicitHeight)
    bottomInset: textUnderIcon ? captionHeight : 0
    leftInset: circularBackground ? Math.max(0, (width - iconDiameter) / 2) : 0
    rightInset: leftInset
    topInset: 0
    padding: 0
    spacing: 0
    display: Controls.AbstractButton.TextUnderIcon

    contentItem: FlexboxLayout {
        id: content

        direction: root.display === Controls.AbstractButton.TextBesideIcon ? FlexboxLayout.Row :
                                                                             FlexboxLayout.Column
        alignItems: FlexboxLayout.AlignCenter
        justifyContent: root.textUnderIcon ? FlexboxLayout.JustifyStart :
                                             FlexboxLayout.JustifyCenter
        gap: root.spacing

        TextIcon {
            visible: root.display !== Controls.AbstractButton.TextOnly
            Layout.preferredWidth: Theme.pixels(5.5)
            Layout.preferredHeight: Theme.pixels(5.5)
            Layout.topMargin: Theme.pixels(1.25)
            Layout.bottomMargin: Layout.topMargin
            Layout.leftMargin: content.direction === FlexboxLayout.Row ? Theme.pixels(1.25) : 0
            Layout.rightMargin: Layout.leftMargin
            font.family: root.font.family
            text: root.icon.name
            color: !root.enabled ? Material.hintTextColor : root.flat && root.highlighted
                                   ? Material.accentColor : root.highlighted
                                     ? Material.primaryHighlightedTextColor : Material.foreground
        }

        Text {
            id: caption

            visible: root.display !== Controls.AbstractButton.IconOnly
            Layout.preferredWidth: Math.max(root.textUnderIcon ? root.availableWidth : implicitWidth,
                                            Theme.pixels(14))
            Layout.preferredHeight: root.captionHeight
            Layout.fillWidth: !root.textUnderIcon
            Layout.leftMargin: root.display === Controls.AbstractButton.TextOnly ? Theme.pixels(
                                                                                       1.25) : 0
            Layout.rightMargin: root.textUnderIcon ? 0 : Theme.pixels(1.25)
            text: root.text
            color: Material.foreground
            font.bold: true
            font.pixelSize: Theme.pixels(2.5)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignTop
            lineHeightMode: Text.FixedHeight
            lineHeight: Theme.pixels(3)
            maximumLineCount: 2
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            textFormat: Text.PlainText
        }
    }
}
