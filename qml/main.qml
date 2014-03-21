import QtQuick 2.0
import QtQuick.Controls 1.1
import QtQuick.Window 2.1
import QtGraphicalEffects 1.0
import Shop.models 1.0
import Shop.extra 1.0
import "views"
import "styles"
import "items"

ApplicationWindow {
    id: applicationWindow

    property int dragDistance
    property bool animate: true
    property bool animateMove: true

    height: 1280; width: 768

    QtObject {
        id: constants
        property int pixelDensity: Screen.pixelDensity > 0 ? Screen.pixelDensity : 332
        property real maxHeight: pixelDensity * 0.37
        property real minHeight: pixelDensity * 0.27
        property int mediumTime:  250
        property int longTime: 500
    }

    ItemModel { id: itemModel }

    Image { anchors.fill: parent; source: "qrc:/pic/bg" }

    RemorseItem {
        id: remorse
        height: constants.maxHeight
        label: qsTr("Tap to cancel")
        opacity: 0.0
        maximumValue: 4
        visible: opacity > 0.0
        width: parent.width
        y: -height

        states: [
            State {
                name: "removeAll"
                StateChangeScript { script: remorse.title = qsTr("Removing all items") }
                PropertyChanges { target: remorse; opacity: 0.8; y: 0;  }
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
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; easing.type: Easing.InOutQuad; duration: 500 }
                        NumberAnimation { property: "y"; easing.type: Easing.InOutQuad; duration: 500 }
                    }
                    ScriptAction { script: remorse.value = 0 }
                }
            },
            Transition {
                to: ""
                SequentialAnimation {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; easing.type: Easing.InOutQuad; duration: 500 }
                        NumberAnimation { property: "y"; easing.type: Easing.InOutQuad; duration: 500 }
                    }
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


    Menu {
        id: menu
        title: qsTr("Choose action")

        MenuItem {
            text: qsTr("Remove all items")
            onTriggered: remorse.state = "removeAll"
        }

        MenuItem {
            text: qsTr("Remove shopped items")
            onTriggered: remorse.state = "removeShopped"
        }

        MenuItem {
            text: qsTr("Reset shopped items")
            onTriggered: remorse.state = "reset"
        }

        MenuItem {
            text: qsTr("To the shop list")
            onTriggered: pageSwitcher.pop()
        }
    }

    HwKeyWatcher {
        target: applicationWindow
        onMenuClicked: {
            if (pageSwitcher.depth == 1)
                return;

            menu.popup()
        }

        onBackClicked: {
            if (pageSwitcher.depth == 1) {
                Qt.quit();
            } else {
                pageSwitcher.pop()
            }
        }
    }

    StackView {
        id: pageSwitcher
        anchors {
            topMargin: remorse.state == "" ? 0 : remorse.height
            fill: parent
        }
        Behavior on anchors.topMargin { NumberAnimation { easing.type: Easing.InOutQuad; duration: 500 } }
        initialItem: {"item": Qt.resolvedUrl("views/ShopView.qml"), properties: {model: itemModel}}
        Component.onCompleted: if (itemModel.count == 0) pageSwitcher.push({ "item": Qt.resolvedUrl("views/EditView.qml"),
                                                                             properties: {model: itemModel},
                                                                             immediate: true})
    }
}
