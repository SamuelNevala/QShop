import QtQuick 2.3
import QtQuick.Controls 1.2
import QtQuick.Window 2.2
import QtGraphicalEffects 1.0
import Shop.models 1.0
import Shop.extra 1.0
import "views"
import "styles"
import "items"

//https://bugreports.qt-project.org/browse/QTBUG-32399

ApplicationWindow {
    id: applicationWindow

    property int dragDistance
    property bool animate: true
    property bool animateMove: true
    property Item previourAcItem

    height: 800; width: 600
    visible: true

    // Disable for now
    //visibility: Qt.platform.os === "android" && !view.editMode ? Window.FullScreen : Window.Maximized

    QtObject {
        id: constants
        property real pixelDensity: Screen.pixelDensity < 3.9 ? 13.1 : Screen.pixelDensity
        property real maxHeight: pixelDensity * 10
        property real minHeight: pixelDensity * 7
        property real largeMargin: pixelDensity * 3
        property real margin: pixelDensity * 1
        property int mediumTime: animate ? 250 : 0
        property int longTime: animate ? 500 : 0
        property real trickerDistance: Math.round(applicationWindow.height / 4)
    }

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
        Component.onCompleted: forceActiveFocus()
    }

    Image {
        id: bg
        anchors.fill: parent
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        source: "qrc:/pic/bg"
        opacity: status == Image.Ready ? 1.0 : 0.0
        visible: opacity > 0.0
        Behavior on opacity { NumberAnimation { easing.type: Easing.InOutQuad } }
    }

    RemorseItem {
        id: remorse
        height: constants.maxHeight
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
                    ScriptAction { script: view.anchors.topMargin = remorse.height }
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
        x: -width + constants.margin

        Column {
            anchors.fill: parent
            Setting {
                width: parent.width
                source: "qrc:/pic/remove"
                text: qsTr("Remove all items")
                onClicked: {
                    sideBar.close()
                    remorse.state = "removeAll"
                }
            }
            Setting {
                width: parent.width
                source: "qrc:/pic/remove"
                text: qsTr("Remove shopped items")
                onClicked: {
                    sideBar.close()
                    remorse.state = "removeShopped"
                }

            }
            Setting {
                width: parent.width
                source: "qrc:/pic/refresh"
                text: qsTr("Reset shopped items")
                onClicked: {
                    sideBar.close()
                    remorse.state = "reset"
                }

            }
            Setting {
                width: parent.width
                source: "qrc:/pic/back"
                text: qsTr("Continue shopping")
                onClicked: {
                    sideBar.close()
                    view.setEditMode(false)
                }
            }
        }
    }
}
