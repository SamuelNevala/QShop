import QtQuick

Loader {
    property bool checked
    property Component checkedIcon
    property bool editMode
    property Component icon
    property Component trashIcon

    sourceComponent: editMode ? trashIcon : checked ? checkedIcon : icon
}
