import QtQuick

Loader {
    property alias dropArea: dropArea
    property bool input
    property Component inputDelegate
    property Component textDelegate

    sourceComponent: input ? inputDelegate : textDelegate

    DropArea { id: dropArea; anchors { fill: parent } }
}
