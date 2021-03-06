import QtQuick 2.6
import QtQuick.Window 2.2
import Shop.models 1.0
import Shop.extra 1.0

Window {
    id: applicationWindow

    property RemorseItem remorse

    color: "black"
    title: theme.title
    height: theme.height; width: theme.width
    visible: true

    FontLoader {
        source: "qrc:/img/fontawesome-webfont.ttf"
    }

    Item {
        id: focusHolder
        anchors { fill: parent }
        focus: true
        Keys.onUpPressed: theme.index--
        Keys.onDownPressed: theme.index++
    }

    Image {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        source: "qrc:/bg"
        opacity: status == Image.Ready ? 1.0 : 0.0
        visible: opacity > 0.0
        Behavior on opacity { DefaultAnimation{ } }
        Component.onCompleted: height = theme.height
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
                source: "\uf1f8"
                text: qsTr("Remove all items")
                width: parent.width
                onClicked: {
                    sideBar.close()
                    remorse = removAllComponent.createObject(applicationWindow);
                    remorse.state = "remorse"
                }
            }
            Setting {
                enabled: sideBar.opened
                source: "\uf1f8"
                text: qsTr("Remove shopped items")
                width: parent.width
                onClicked: {
                    sideBar.close()
                    remorse = removSelectedComponent.createObject(applicationWindow);
                    remorse.state = "remorse"
                }

            }
            Setting {
                enabled: sideBar.opened
                source: "\uf021"
                text: qsTr("Reset shopped items")
                width: parent.width
                onClicked: {
                    sideBar.close()
                    remorse = resetComponent.createObject(applicationWindow);
                    remorse.state = "remorse"
                }

            }
            Setting {
                enabled: sideBar.opened
                source: "\uf053"
                text: qsTr("Continue shopping")
                width: parent.width
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
            done: (function() { itemModel.removeChecked(); destroy(theme.time.medium) })
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
