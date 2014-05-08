import QtQuick 2.3
import Shop.models 1.0
import "../items"

ListView {
    id: mainView

    function setEditMode(mode) {
        if (editMode === mode) return
        editMode = mode
        if (editMode)
            itemModel.addEditor()
        else {
            itemModel.removeEditor()
            focusHolder.forceActiveFocus()
        }
    }

    property bool editMode: false

    Pulley {
        actionText: editMode ? qsTr("Release to shop") : qsTr("Release to edit")
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: -parent.contentY + parent.originY - weekdays.height
        pullHint: editMode ? qsTr("Pull to shop") : qsTr("Pull to edit")
        onAction: setEditMode(!editMode)
        visible: mainView.count > editMode ? 1 : 0
    }

    Weekdays {
        id: weekdays
        anchors { right: parent.right; left: parent.left }
        visible: mainView.count > editMode ? 1 : 0
        y: -parent.contentY - height + parent.originY - mainView.anchors.topMargin
    }

    Rectangle {
        height: Math.max(mainView.height - mainView.contentHeight, 0)
        color: "black"
        opacity: visible ? 0.8 : 0.0
        y: -mainView.contentY + mainView.contentHeight
        visible: height
        width:  mainView.width
        z: -1
    }

    cacheBuffer: constants.maxHeight * 40
    currentIndex: -1
    delegate: Component {
        Loader {
            width: parent.width
            source: editor ? Qt.resolvedUrl("../items/InputItem.qml")
                           : editMode ? Qt.resolvedUrl("../items/DragableItem.qml")
                                      : Qt.resolvedUrl("../items/SelectableItem.qml")
        }
    }

    add: Transition {
        enabled: applicationWindow.animate
        ParallelAnimation {
            NumberAnimation { properties: "x"; from: -mainView.width; to: 0; easing.type: Easing.InOutQuad; duration: constants.mediumTime }
            NumberAnimation { properties: "opacity"; from: 0.5; to: 1.0; easing.type: Easing.InOutQuad; duration: constants.mediumTime }
        }
    }

    remove: Transition {
        enabled: applicationWindow.animate
        ParallelAnimation {
            NumberAnimation { properties: "x"; from: 0; to: mainView.width; easing.type: Easing.InOutQuad; duration: constants.mediumTime }
            NumberAnimation { properties: "opacity"; from: 1.0; to: 0.5; easing.type: Easing.InOutQuad; duration: constants.mediumTime }
        }
    }

    displaced: Transition {
        enabled: applicationWindow.animate
        NumberAnimation { properties: "y"; easing.type: Easing.InOutQuad; duration: constants.mediumTime }
    }

    move: Transition {
        id: moveTransition
        enabled: applicationWindow.animate
        SequentialAnimation {
            NumberAnimation { properties: "y"; easing.type: Easing.InOutQuad; duration: constants.mediumTime }
            NumberAnimation {
                target: moveTransition.ViewTransition.item.item
                properties: "x"; to: 0
                easing.type: Easing.InOutQuad; duration: constants.mediumTime
            }
        }
    }
}
