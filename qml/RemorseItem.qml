import QtQuick 2.4
import QtQuick.Controls 1.3
import QtQuick.Controls.Styles 1.3

ProgressBar {
    id: root

    function reset() {
        animation.skip = true
        value = maximumValue
        animation.skip = false
    }

    property alias title: title.text
    property alias label: label.text

    signal cancelled()
    signal done()

    value: maximumValue

    style: ProgressBarStyle {
        background: Rectangle { color: "#0099CC" }
        progress:  Rectangle { color: "#33B5E5" }
    }

    Text {
        id: title
        anchors {
            top: parent.top;bottom: parent.verticalCenter
            bottomMargin: -theme.margins.medium
            left: parent.left; right: parent.right
        }
        color: "white"
        font{ pixelSize: theme.fonts.medium }
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    Text {
        id: label
        anchors {
            top: parent.verticalCenter; bottom: parent.bottom
            topMargin: -theme.margins.medium
            left: parent.left; right: parent.right
        }
        color: "white"
        font{ pixelSize: theme.fonts.small }
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter

    }

    MouseArea {
        anchors.fill: parent
        enabled: root.visible
        onClicked: {
            root.value = root.value
            root.cancelled()
        }
    }

    onValueChanged: if (value == 0) root.done()

    Behavior on value {
        NumberAnimation {
            id: animation
            property bool skip
            duration: skip ? 0: maximumValue * 1000
        }
    }
}
