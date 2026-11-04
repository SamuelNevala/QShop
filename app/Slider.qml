pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Material as Controls

Controls.Slider {
    id: root

    implicitWidth: Theme.pixels(horizontal ? 30 : 9.27)
    implicitHeight: Theme.pixels(horizontal ? 9.27 : 30)
    padding: 0

    handle: Rectangle {
        implicitWidth: Theme.pixels(4)
        implicitHeight: Theme.pixels(4)
        x: root.leftPadding + (root.horizontal ? root.visualPosition * (root.availableWidth
                                                                        - width) : (
                                                     root.availableWidth - width) / 2)
        y: root.topPadding + (root.horizontal ? (root.availableHeight - height) / 2 :
                                                root.visualPosition * (root.availableHeight
                                                                       - height))
        radius: width / 2
        color: root.enabled ? root.Controls.Material.accentColor :
                              root.Controls.Material.sliderDisabledColor
        border.width: root.visualFocus ? Theme.pixels(0.4) : 0
        border.color: root.Controls.Material.primaryTextColor
    }
    background: Rectangle {
        x: root.leftPadding + (root.horizontal ? root.handle.width / 2 : (root.availableWidth
                                                                          - width) / 2)
        y: root.topPadding + (root.horizontal ? (root.availableHeight - height) / 2 :
                                                root.handle.height / 2)
        width: root.horizontal ? root.availableWidth - root.handle.width : Theme.pixels(0.8)
        height: root.horizontal ? Theme.pixels(0.8) : root.availableHeight - root.handle.height
        radius: Math.min(width, height) / 2
        color: root.enabled ? Qt.alpha(root.Controls.Material.accentColor, 0.33) :
                              root.Controls.Material.sliderDisabledColor

        Rectangle {
            x: root.horizontal && root.mirrored ? parent.width - width : 0
            y: root.horizontal ? 0 : root.visualPosition * parent.height
            width: root.horizontal ? root.position * parent.width : parent.width
            height: root.horizontal ? parent.height : root.position * parent.height
            radius: parent.radius
            color: root.enabled ? root.Controls.Material.accentColor :
                                  root.Controls.Material.sliderDisabledColor
        }
    }
}
