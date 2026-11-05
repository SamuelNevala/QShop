import QtQuick
import QtQuick.Controls.Material

StackView {
    id: stack

    resources: [
        ObjectModel {
            id: model

            BackgroundImage {
                source: Qt.resolvedUrl("backgrounds/01-phone-and-pantry.jpg")
                height: stack.height
                width: stack.width
            }

            BackgroundImage {
                source: Qt.resolvedUrl("backgrounds/02-produce.jpg")
                height: stack.height
                width: stack.width
            }

            BackgroundImage {
                source: Qt.resolvedUrl("backgrounds/03-bakery.jpg")
                height: stack.height
                width: stack.width
            }

            BackgroundImage {
                source: Qt.resolvedUrl("backgrounds/04-dairy.jpg")
                height: stack.height
                width: stack.width
            }

            BackgroundImage {
                source: Qt.resolvedUrl("backgrounds/05-bulk-goods.jpg")
                height: stack.height
                width: stack.width
            }

            BackgroundImage {
                source: Qt.resolvedUrl("backgrounds/06-market-hall.jpg")
                height: stack.height
                width: stack.width
            }

            BackgroundImage {
                source: Qt.resolvedUrl("backgrounds/07-checkout.jpg")
                height: stack.height
                width: stack.width
            }

            BackgroundImage {
                source: Qt.resolvedUrl("backgrounds/08-qshopper.jpg")
                height: stack.height
                width: stack.width
            }

            BackgroundImage {
                source: Qt.resolvedUrl("backgrounds/09-stocktaking.jpg")
                height: stack.height
                width: stack.width
            }

            BackgroundImage {
                source: Qt.resolvedUrl("backgrounds/10-evening-produce.jpg")
                height: stack.height
                width: stack.width
            }
        },
        Timer {
            property bool push: true

            interval: 7000
            repeat: true
            running: true

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
        OpacityAnimation {
            from: 0.2
            to: 1
        }

        YAnimation {
            from: -stack.height
            to: 0
        }
    }
    pushExit: Transition {
        OpacityAnimation {
            from: 1
            to: 0.2
        }

        YAnimation {
            from: 0
            to: stack.height
        }
    }
    popEnter: Transition {
        OpacityAnimation {
            from: 0.2
            to: 1
        }

        YAnimation {
            from: stack.height
            to: 0
        }
    }
    popExit: Transition {
        OpacityAnimation {
            from: 1
            to: 0.2
        }

        YAnimation {
            from: 0
            to: -stack.height
        }
    }

    Component.onCompleted: stack.push(model.get(0))
}
