pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Material as Controls
import QtQuick.Shapes
import QtQuick.Templates as Templates
import QtQuick.Window

Controls.ComboBox {
    id: root

    property alias label: caption.text
    readonly property real rowHeight: Theme.pixels(9.27)

    font.pixelSize: Theme.pixels(3.5)
    implicitWidth: Math.max(Theme.pixels(30), implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: rowHeight + topInset

    // Leave room above the field for its caption.
    topInset: caption.height + Theme.pixels(1)
    padding: Theme.pixels(4)
    topPadding: topInset + Theme.pixels(1)
    bottomPadding: Theme.pixels(1)
    spacing: Theme.pixels(1)

    // Android Back starts with an outside press, then cancels that touch.
    // Wait for a real outside release so one gesture dismisses only this popup.
    popup.modal: true
    popup.closePolicy: Templates.Popup.CloseOnEscape | Templates.Popup.CloseOnReleaseOutsideParent

    // Avoid feeding ListView's viewport-dependent contentHeight back into its height.
    popup.height: Math.min(root.count * rowHeight + root.popup.topPadding + root.popup.bottomPadding,
                           Math.max(0, root.Window.height - root.popup.topMargin
                                    - root.popup.bottomMargin))
    // Popups live in the window overlay, outside the drawer's safe-area padding.
    popup.topMargin: Theme.pixels(2) + (root.Window.contentItem
                                        ? root.Window.contentItem.SafeArea.margins.top : 0)
    popup.bottomMargin: Theme.pixels(2) + (root.Window.contentItem
                                           ? root.Window.contentItem.SafeArea.margins.bottom : 0)
    popup.leftMargin: Theme.pixels(2) + (root.Window.contentItem
                                         ? root.Window.contentItem.SafeArea.margins.left : 0)
    popup.rightMargin: Theme.pixels(2) + (root.Window.contentItem
                                          ? root.Window.contentItem.SafeArea.margins.right : 0)
    popup.verticalPadding: Theme.pixels(1)

    background: Rectangle {
        radius: Theme.pixels(1)
        color: "transparent"
        visible: !root.flat
        border.width: Theme.pixels(0.4)
        border.color: root.activeFocus ? root.Controls.Material.accentColor : root.enabled && root.hovered
                                         ? root.Controls.Material.primaryTextColor :
                                           root.Controls.Material.hintTextColor
    }
    indicator: Shape {
        id: arrow

        width: Theme.pixels(2.5)
        height: Theme.pixels(1.5)
        x: root.mirrored ? root.padding : root.width - width - root.padding
        y: root.topPadding + (root.availableHeight - height) / 2

        ShapePath {
            strokeWidth: -1
            fillColor: root.enabled ? root.Controls.Material.foreground :
                                      root.Controls.Material.hintTextColor
            startX: 0
            startY: 0

            PathLine {
                x: arrow.width
                y: 0
            }

            PathLine {
                x: arrow.width / 2
                y: arrow.height
            }

            PathLine {
                x: 0
                y: 0
            }
        }
    }
    delegate: Controls.MenuItem {
        required property var model
        required property int index

        width: ListView.view.width
        implicitHeight: root.rowHeight
        font: root.font
        text: model[root.textRole]
        padding: Theme.pixels(2)
        verticalPadding: Theme.pixels(1)
        spacing: Theme.pixels(1)
        highlighted: root.highlightedIndex === index
        hoverEnabled: root.hoverEnabled
        Controls.Material.foreground: root.currentIndex === index ? root.Controls.Material.accent :
                                                                    root.Controls.Material.foreground
    }

    // Remove padding from the default Material text field only.
    Binding {
        target: root.contentItem as Templates.TextField
        property: "leftPadding"
        value: 0
    }

    Binding {
        target: root.contentItem as Templates.TextField
        property: "rightPadding"
        value: 0
    }

    Binding {
        target: root.contentItem as Templates.TextField
        property: "topPadding"
        value: 0
    }

    Binding {
        target: root.contentItem as Templates.TextField
        property: "bottomPadding"
        value: 0
    }

    Text {
        id: caption

        x: root.padding
        width: root.availableWidth
        color: root.Controls.Material.primaryTextColor
        font.pixelSize: Theme.pixels(3)
        elide: Text.ElideRight
    }
}
