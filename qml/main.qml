import QtQuick 2.4
import QtQuick.Window 2.2
import Shop.models 1.0
import Shop.extra 1.0

Window {
    id: applicationWindow

    property RemorseItem remorse

    height: 960; width: 640
    visible: true

    Rectangle { id: focusHolder; anchors { fill: parent } color: "black" }
    Image {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        source: "qrc:/bg"
        opacity: status == Image.Ready ? 1.0 : 0.0
        visible: opacity > 0.0
        Behavior on opacity { DefaultAnimation{ } }
        Component.onCompleted: height = Screen.height
    }
    Theme { id: theme }
    ItemModel { id: itemModel }

    BackKey {
        onClicked: {
            if (sideBar.x == 0) {
                sideBar.close()
            } else if (view.editMode && itemModel.count > 1) {
                view.setEditMode(false)
            } else {
                Qt.quit()
            }
        }
    }

    View {
        id: view
        anchors {
            fill: parent
            bottomMargin: Qt.inputMethod.visible ? Qt.inputMethod.keyboardRectangle.height : 0
            topMargin: remorse ? theme.heights.large : 0
        }
        model: itemModel
        Behavior on anchors.topMargin { DefaultAnimation { } }
        Component.onCompleted: if (itemModel.count == 0) setEditMode(true)
    }

    SideBar {
        id: sideBar
        enabled: view.editMode
        height: parent.height
        width: theme.constants.menuWidth
        x: -width + theme.margins.medium

        Column {
            anchors { fill: parent }
            Setting {
                enabled: sideBar.opened
                width: parent.width
                source: "qrc:/remove"
                text: qsTr("Remove all items")
                onClicked: {
                    sideBar.close()
                    remorse = removAllComponent.createObject(applicationWindow);
                    remorse.state = "remorse"
                }
            }
            Setting {
                enabled: sideBar.opened
                width: parent.width
                source: "qrc:/remove"
                text: qsTr("Remove shopped items")
                onClicked: {
                    sideBar.close()
                    remorse = removSelectedComponent.createObject(applicationWindow);
                    remorse.state = "remorse"
                }

            }
            Setting {
                enabled: sideBar.opened
                width: parent.width
                source: "qrc:/refresh"
                text: qsTr("Reset shopped items")
                onClicked: {
                    sideBar.close()
                    remorse = resetComponent.createObject(applicationWindow);
                    remorse.state = "remorse"
                }

            }
            Setting {
                enabled: sideBar.opened
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

    Component {
        id: removAllComponent
        RemorseItem {
            title: qsTr("Removing all items")
            cancel: (function() { destroy(theme.time.medium) })
            delay: theme.time.medium
            done: (function() { itemModel.removeAll(); itemModel.addEditor(); destroy(theme.time.medium) })
        }
    }

    Component {
        id: removSelectedComponent
        RemorseItem {
            title: qsTr("Removing shopped items")
            cancel: (function() { destroy(theme.time.medium) })
            delay: theme.time.medium
            done: (function() { itemModel.removeSelected(); destroy(theme.time.medium) })
        }
    }

    Component {
        id: resetComponent
        RemorseItem {
            title: qsTr("Reseting shopped items")
            cancel: (function() { destroy(theme.time.medium) })
            delay: theme.time.medium
            done: (function() { itemModel.reset(); destroy(theme.time.medium) })
        }
    }
}
