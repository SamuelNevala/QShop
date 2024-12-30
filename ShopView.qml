import QtQuick.Controls.Material
import QtQuick
import QDynamics
import QShopper

pragma ComponentBehavior: Bound

ListView {
    id: shopView

    signal openMenu()

    property Dimensions dimensions
    property string fontFamily
    property bool editMode: false
    property var lists: itemModel.lists

    function setEditMode(mode) {
        if (editMode === mode) {
            return;
        }
        editMode = mode;
        if (editMode) {
            itemModel.addEditor();
            return
        }
        itemModel.removeEditor();
    }

    function reset() {
        itemModel.reset()
    }

    function removeChecked() {
        itemModel.removeChecked();
    }

    function removeAll() {
        itemModel.removeAll();
    }

    Pulley {
        anchors { left: parent.left; right: parent.right; bottom: weekdays.top }
        bottomPadding: shopView.dimensions.mm(1)
        dimensions: shopView.dimensions
        editMode: shopView.editMode
        font { family: shopView.fontFamily }
        topPadding: -parent.contentY + parent.originY - weekdays.height
        onAction: shopView.setEditMode(!shopView.editMode)
    }

    Weekdays {
        id: weekdays
        anchors { right: parent.right; left: parent.left }
        dimensions: shopView.dimensions
        y: -parent.contentY - height + parent.originY;
    }

    Rectangle {
        color: Material.backgroundColor
        height: parent.height - y; width: parent.width
        opacity: height <= 0 ? 0.0 : 0.8
        y: Math.max(0, shopView.contentItem.childrenRect.height  - shopView.contentY)
        z: -1
    }

    cacheBuffer: dimensions.mm(9.27) * 20
    currentIndex: -1
    clip: true

    delegate: DelegateChoser {
        id: chooser

        required property bool checked
        required property bool editor
        required property int index
        required property string name

        dropArea {
            enabled: !chooser.checked && shopView.editMode
            onEntered: function(drag) { itemModel.move((drag.source as Delegate).index , chooser.index); }
        }

        input: editor;
        height: shopView.dimensions.mm(9.27); width: shopView.width

        textDelegate: TextDelegate {
            checked: chooser.checked
            dimensions: shopView.dimensions
            dragParent: shopView
            font { family: shopView.fontFamily }
            editMode: shopView.editMode
            index: chooser.index
            name: chooser.name

            onDoubleTapped: {
                if (!shopView.editMode) return;
                const input = ((shopView.itemAtIndex(itemModel.editorIndex) as DelegateChoser).item as InputDelegate);
                input.insert(itemModel.editItem(index));
            }
            onPressed: itemModel.clearUndoStack()
            onSingleTapped: {
                if (checked) return;
                itemModel.moveEditor(index);
            }
            onSwiped: function(direction) {
                if (shopView.editMode && direction === SwipeHandler.Direction.Right) {
                    itemModel.remove(index);
                } else {
                    itemModel.toggleChecked(index)
                }
            }
        }

        inputDelegate: InputDelegate {
            canUndo: itemModel.canUndo
            dimensions: shopView.dimensions
            font { family: shopView.fontFamily }
            editor: chooser.editor
            index: chooser.index

            onAddItem: function(text) {
                itemModel.insert(index, text)
                shopView.positionViewAtIndex(index, ListView.Contain)
            }
            onBarsTapped: shopView.openMenu()
            onTimeout: itemModel.clearUndoStack();
            onUndo: itemModel.undo();
        }
    }

    model: Model {
        id: itemModel;
        activeList: ThemeManager.activeList
        Component.onCompleted: shopView.setEditMode(!itemModel.count)
    }

    add: Transition {
        SequentialAnimation {
            PropertyAction { property: "x"; value: -shopView.width }
            PauseAnimation { duration: 250 }
            ParallelAnimation {
                DefaultAnimation { properties: "x"; to: 0 }
                DefaultAnimation { properties: "opacity"; from: 0.5; to: 1.0 }
            }
        }
    }

    remove: Transition {
        SequentialAnimation {
            ParallelAnimation {
                DefaultAnimation { properties: "x"; from: 0; to: shopView.width }
                DefaultAnimation { properties: "opacity"; from: 1.0; to: 0.5 }
            }
            SequentialAnimation {
                PropertyAction { property: "ListView.delayRemove"; value: true }
                PauseAnimation { duration: 250 }
                PropertyAction { property: "ListView.delayRemove"; value: false }
            }
        }
    }

    displaced: Transition { DefaultAnimation { properties: "y" } }

    removeDisplaced: Transition {
        SequentialAnimation {
            PauseAnimation { duration: 250 }
            DefaultAnimation { properties: "y" }
        }
    }

    move: Transition {
        id: move

        property bool editor: ViewTransition.index == itemModel.editorIndex

        SequentialAnimation {
            SmoothedAnimation { properties: "y"; velocity: 400; duration: move.editor ? 500 : 0 }
            DefaultAnimation { properties: "y"; duration: move.editor ? 0 : 250 }
        }
    }

    TapHandler {
        enabled: itemModel.canUndo
        onGrabChanged: itemModel.clearUndoStack()
    }

    onMovementStarted: {
        if (!itemModel.canUndo) return;
        itemModel.clearUndoStack();
    }
}
