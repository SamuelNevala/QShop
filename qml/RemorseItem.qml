import QtQuick 2.4
import QtQuick.Controls 1.3
import QtQuick.Controls.Styles 1.3
import QtQuick.Layouts 1.1

ProgressBar {
    id: root

    function reset()
    {
        animation.skip = true
        value = maximumValue
        animation.skip = false
    }

    property alias title: title.text
    property string label: qsTr("Tap to cancel")
    property var done
    property var cancel
    property int delay

    implicitHeight: theme.heights.large
    maximumValue: 6
    opacity: 0.0
    style: ProgressBarStyle {
        background: Rectangle { color: "#0099CC" }
        progress:  Rectangle { color: "#33B5E5" }
    }

    states: State {
        name: "remorse"
        PropertyChanges { target: root; opacity: 0.8; x: 0 }
    }

    transitions: [
        Transition {
            to: "remorse"
            SequentialAnimation {
                PauseAnimation { duration: root.delay }
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; easing.type: Easing.InOutQuad; duration: theme.time.long }
                    NumberAnimation { property: "x"; easing.type: Easing.InOutQuad; duration: theme.time.long }
                }
                ScriptAction { script: root.value = 0 }
            }
        },
        Transition {
            from: "remorse"
            SequentialAnimation {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; easing.type: Easing.InOutQuad; duration: theme.time.long }
                    NumberAnimation { property: "x"; easing.type: Easing.InOutQuad; duration: theme.time.long }
                }
                ScriptAction { script: root.reset() }
            }
        }
    ]

    value: maximumValue
    visible: opacity > 0.0
    width: parent.width
    x: parent.width

    RowLayout {
        id: row
        anchors { fill: parent; margins: theme.margins.medium }
        spacing: theme.margins.medium

        Text {
            id: tick
            color: "white"
            font{ pixelSize: theme.fonts.large }
            fontSizeMode: Text.Fit
            text: Math.ceil(value)
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignLeft
        }

        ColumnLayout {
            Text {
                id: title
                color: "white"
                font{ pixelSize: theme.fonts.medium }
                elide: Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: root.width - theme.margins.medium * 3 - tick.width - (truncated ? 0 : tick.width + theme.margins.medium * 2)
                Layout.alignment: Qt.AlignLeft
            }

            Text {
                id: label
                color: "white"
                font{ pixelSize: theme.fonts.small }
                text: root.label
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                Layout.preferredWidth: root.width - theme.margins.medium * 3 - tick.width - (truncated ? 0 : tick.width + theme.margins.medium * 2)
                Layout.alignment: Qt.AlignLeft
            }
        }
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignLeft
    }

    MouseArea {
        anchors { fill: parent }
        enabled: root.visible
        onClicked: {
            root.value = root.value
            root.state = ""
            if (root.cancel !== undefined) {
                root.cancel()
            }
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
