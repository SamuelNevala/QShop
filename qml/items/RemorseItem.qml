import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.1

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
        id: seconds
        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
        color: "white"
        text: Math.round(root.value)
        font{ pixelSize: height }
        fontSizeMode: Text.Fit
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        width: height
    }

    Text {
        id: title
        property bool fitted: parent.width - (contentWidth + seconds.width*2) < 0
        anchors {
            horizontalCenter: parent.horizontalCenter
            horizontalCenterOffset: fitted ? seconds.width / 2 : 0
            top: parent.top;
            bottom: parent.verticalCenter
            bottomMargin: -(parent.height / 2 * 0.3 / 2)
        }
        color: "white"
        font{ pixelSize: height * 0.7 }
        fontSizeMode: Text.Fit
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        width: parent.width - (fitted ? (seconds.width) : 0)
    }

    Text {
        id: label
        property bool fitted: parent.width - (contentWidth + seconds.width*2) < 0
        anchors {
            horizontalCenter: parent.horizontalCenter
            horizontalCenterOffset: fitted < 0 ? seconds.width / 2 : 0
            topMargin: -(parent.height / 2 * 0.3 / 2)
            top: parent.verticalCenter;
            bottom: parent.bottom
        }
        color: "white"
        font{ pixelSize: height * 0.5 }
        fontSizeMode: Text.Fit
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
        width: parent.width - seconds.width
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
