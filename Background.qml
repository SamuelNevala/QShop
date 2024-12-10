import QtQuick
import QtQuick.Controls

StackView {
    id: stack

    resources: [
        ObjectModel {
            id: model
            BackgroundImage {
                source: Qt.resolvedUrl("background_one.jpg")
                height: stack.height; width: stack.width
            }
            BackgroundImage {
                source: Qt.resolvedUrl("background_two.jpg")
                height: stack.height; width: stack.width
            }
            BackgroundImage {
                source: Qt.resolvedUrl("background_three.jpg")
                height: stack.height; width: stack.width
            }
            BackgroundImage {
                source: Qt.resolvedUrl("background_four.jpg")
                height: stack.height; width: stack.width
            }
            BackgroundImage {
                source: Qt.resolvedUrl("background_five.jpg")
                height: stack.height; width: stack.width
            }
        },
        Timer {
            property bool push: true

            interval: 7000
            repeat: true; running: true

            onTriggered: {
                if (push) {
                    stack.push(model.get(stack.depth));
                } else {
                    stack.pop();
                }

                if (stack.depth === model.count) {
                    push = false;
                }

                if (!push && stack.depth === 1) {
                    push = true;
                }
            }
        }
    ]

    pushEnter: Transition {
        ParallelAnimation {
            OpacityAnimation { from: 0.2; to: 1 }
            YAnimation { from: -stack.height; to: 0 }
        }
    }
    pushExit: Transition {
        ParallelAnimation {
            OpacityAnimation { from: 1; to: 0.2 }
            YAnimation { from: 0; to: stack.height }
        }
    }
    popEnter: Transition {
        OpacityAnimation { from: 0.2; to: 1 }
        YAnimation { from: stack.height; to: 0 }
    }
    popExit: Transition {
        ParallelAnimation {
            OpacityAnimation { from: 1; to: 0.2 }
            YAnimation { from: 0; to: -stack.height }
        }
    }

    Component.onCompleted: stack.push(model.get(0));
}
