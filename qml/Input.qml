import QtQuick 2.4
import QtQuick.Controls 1.3
import Shop.extra 1.0

FocusScope {
    id: root

    property alias text: input.text

    property string placeholderText
    property string placeholderTextFocus
    property int padding

    signal accepted()
    signal dropAreaEntered(Item dragSource)

    height: theme.heights.large

    BackgroundItem {
        id: background
        anchors { fill: parent }
        color: "white"
        TextField {
            id: input
            focus: true
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: root.padding; rightMargin: root.padding }
            horizontalAlignment: Text.AlignHCenter
            placeholderText: activeFocus && displayText == "" ? root.placeholderTextFocus : root.placeholderText
            z: 1

            onAccepted: root.accepted()
            Keys.onReturnPressed: {
                Qt.inputMethod.commit()
                root.accepted()
            }
        }

        Voice {
            onAdd: {
                input.text = text
                Qt.inputMethod.commit()
                root.accepted()
            }
            onClear: input.text = ""
            onRemove: itemModel.remove(index -1)

        }

        // https://bugreports.qt.io/browse/QTBUG-42444
        //Connections {
        //    target: Qt.inputMethod
        //    onVisibleChanged: if (!Qt.inputMethod.visible && input.activeFocus) focusHolder.forceActiveFocus()
        //}
    }

    DropArea {
        anchors { fill: parent }
        onEntered: root.dropAreaEntered(drag.source)
        enabled: true
    }
}
