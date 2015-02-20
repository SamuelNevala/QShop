import QtQuick 2.4
import QtQuick.Window 2.2
import Shop.models 1.0
import Shop.extra 1.0

Window {
    id: applicationWindow

    property int dragDistance
    property bool animate: true
    property bool animateMove: true

    title: theme.title
    height: theme.height; width: theme.width
    visible: true



    QtObject {
        id: constants
        property int mediumTime: animate ? 250 : 0
        property int longTime: animate ? 500 : 0
    }

    Theme { id: theme }

    ItemModel { id: itemModel }

    Rectangle {
        id: focusHolder
        color: "black"
        anchors.fill: parent
        HwKeyWatcher {
            target: focusHolder
            onBackClicked: {
                if (view.editMode && itemModel.count > 1)
                    view.setEditMode(false)
                else
                    Qt.quit()
            }
        }
        Keys.onUpPressed: theme.index--
        Keys.onDownPressed: theme.index++
        Component.onCompleted: forceActiveFocus()
    }

    Image {
        id: bg
        anchors.fill: parent
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        source: "qrc:/bg"
        opacity: status == Image.Ready ? 1.0 : 0.0
        visible: opacity > 0.0
        Behavior on opacity { NumberAnimation { easing.type: Easing.InOutQuad } }
    }

    RemorseItem {
        id: remorse
        height: theme.heights.large
        label: qsTr("Tap to cancel")
        opacity: 0.0
        maximumValue: 6
        visible: opacity > 0.0
        width: parent.width
        x: width

        states: [
            State {
                name: "removeAll"
                StateChangeScript { script: remorse.title = qsTr("Removing all items") }
                PropertyChanges { target: remorse; opacity: 0.8; x: 0;  }
            },
            State {
                name: "removeShopped";
                extend: "removeAll"
                StateChangeScript { script: remorse.title = qsTr("Removing shopped items") }
            },
            State {
                name: "reset";
                extend: "removeAll"
                StateChangeScript { script: remorse.title = qsTr("Reseting shopped items") }
            }
        ]

        transitions: [
            Transition {
                from: ""
                SequentialAnimation {
                    PauseAnimation { duration: constants.mediumTime }
                    ScriptAction { script: view.anchors.topMargin += remorse.height }
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; easing.type: Easing.InOutQuad; duration: constants.longTime }
                        NumberAnimation { property: "x"; easing.type: Easing.InOutQuad; duration: constants.longTime }
                    }
                    ScriptAction { script: remorse.value = 0 }
                }
            },
            Transition {
                to: ""
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; easing.type: Easing.InOutQuad; duration: constants.longTime }
                        NumberAnimation { property: "x"; easing.type: Easing.InOutQuad; duration: constants.longTime }
                    }
                    ScriptAction { script: view.anchors.topMargin = 0 }
                    ScriptAction { script: remorse.reset() }
                }
            }
        ]
        onCancelled: remorse.state = ""
        onDone: {
            if (state == "removeAll") {
                itemModel.removeAll()
                itemModel.addEditor()
            } else if(state == "removeShopped") {
                itemModel.removeSelected()
            } else if(state == "reset") {
                itemModel.reset()
            }
            remorse.state = ""
        }
    }

    View {
        id: view
        anchors {
            fill: parent
            bottomMargin: Qt.inputMethod.visible ? Qt.inputMethod.keyboardRectangle.height : 0
        }
        model: itemModel
        Behavior on anchors.topMargin { NumberAnimation { easing.type: Easing.InOutQuad; duration: constants.longTime } }
        Component.onCompleted: if (itemModel.count == 0) setEditMode(true)
    }

    SideBar {
        id: sideBar
        enabled: view.editMode
        height: parent.height
        width: parent.width * 5 / 6
        x: -width + theme.margins.medium

        Column {
            anchors.fill: parent
            Setting {
                width: parent.width
                source: "qrc:/remove"
                text: qsTr("Remove all items")
                onClicked: {
                    sideBar.close()
                    remorse.state = "removeAll"
                }
            }
            Setting {
                width: parent.width
                source: "qrc:/remove"
                text: qsTr("Remove shopped items")
                onClicked: {
                    sideBar.close()
                    remorse.state = "removeShopped"
                }

            }
            Setting {
                width: parent.width
                source: "qrc:/refresh"
                text: qsTr("Reset shopped items")
                onClicked: {
                    sideBar.close()
                    remorse.state = "reset"
                }

            }
            Setting {
                width: parent.width
                source: "qrc:/back"
                text: qsTr("Continue shopping")
                onClicked: {
                    sideBar.close()
                    view.setEditMode(false)
                }
            }
        }
    }
}
