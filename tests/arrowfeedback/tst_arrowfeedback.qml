pragma ComponentBehavior: Bound
import QShopper
import QtQuick
import QtQuick.Controls.Material
import QtTest

Item {
    id: scene

    width: 800
    height: 500
    Material.theme: Theme.theme

    Binding {
        target: Theme
        property: "parent"
        value: scene
    }

    Rectangle {
        anchors.fill: parent
        color: scene.Material.backgroundColor
    }

    FontLoader {
        id: icons

        source: "qrc:/qt/qml/QShopper/fa-solid-900.ttf"
    }

    Component {
        id: spyComponent

        SignalSpy {}
    }

    Component {
        id: rowComponent

        TextDelegate {
            y: 150
            width: 720
            height: Theme.pixels(9.27)
            name: "Milk"
            font.family: icons.name
            dragParent: scene
        }
    }

    TestCase {
        id: test

        property var pointer
        property var row
        property var actions
        property point origin

        function cases() {
            const result = [];
            for (const dark of [false, true]) {
                for (const variant of ["in", "out", "trash"]) {
                    result.push({
                                    tag: (dark ? "dark-" : "light-") + variant,
                                    dark: dark,
                                    variant: variant
                                });
                }
            }
            return result;
        }

        function init() {
            failOnWarning(/.*/);
            Theme.scale = 2;
            Theme.swipeSensitivity = 0;
            tryCompare(icons, "status", FontLoader.Ready);
        }

        function cleanup() {
            if (pointer) {
                pointer.release(0, scene, origin.x, origin.y).commit();
                pointer = null;
            }
        }

        function makeRow(data) {
            Theme.theme = data.dark ? Material.Dark : Material.Light;
            row = createTemporaryObject(rowComponent, scene, {
                                            checked: data.variant === "out",
                                            editMode: data.variant === "trash"
                                        });
            verify(row !== null);
            actions = createTemporaryObject(spyComponent, scene, {
                                                target: row,
                                                signalName: "swiped"
                                            });
            wait(50);
            return row.background.children.filter(child => child instanceof IconChoser)[0].item;
        }

        function pull(distance) {
            origin = row.mapToItem(scene, 100, row.height / 2);
            pointer = touchEvent(scene);
            pointer.press(0, scene, origin.x, origin.y).commit();
            for (let step = 1; step <= 4; ++step) {
                pointer.move(0, scene, origin.x + distance * step / 4, origin.y).commit();
                wait(15);
            }
        }

        function returnAndRelease() {
            pointer.move(0, scene, origin.x, origin.y).commit();
            pointer.release(0, scene, origin.x, origin.y).commit();
            pointer = null;
            tryCompare(row, "x", 0, 400);
            wait(270);
        }

        function test_rapid_second_swipe_data() {
            return cases();
        }

        function test_rapid_second_swipe(data) {
            const icon = makeRow(data);
            pull(row.height * 1.6);
            wait(180);
            verify(icon.ratio > 1 && icon.opacity > .5, "x=" + row.x + " ratio=" + icon.ratio
                   + " opacity=" + icon.opacity + " height=" + row.height);

            const first = icon.arrow.y / icon.height;
            grabImage(scene).save("arrow-" + data.tag + "-first.png");
            returnAndRelease();
            pull(row.height * 1.6);
            wait(180);
            verify(icon.ratio > 1 && icon.opacity > .5, "x=" + row.x + " ratio=" + icon.ratio
                   + " opacity=" + icon.opacity + " height=" + row.height);

            grabImage(scene).save("arrow-" + data.tag + "-second.png");
            fuzzyCompare(icon.arrow.y / icon.height, first, .09,
                         "A new visible swipe must replay the same arrow trajectory");
            returnAndRelease();
            compare(actions.count, 0, "Pullback must not perform a check/delete action");
        }

        function test_resized_idle_feedback_data() {
            return cases();
        }

        function test_resized_idle_feedback(data) {
            const icon = makeRow(data);
            const starts = createTemporaryObject(spyComponent, scene, {
                                                     target: icon.animation,
                                                     signalName: "started"
                                                 });
            pull(row.height * 1.6);
            compare(starts.count, 1);
            wait(850);
            pointer.move(0, scene, origin.x + row.height * .8, origin.y).commit();
            wait(30);
            pointer.move(0, scene, origin.x + row.height * 1.6, origin.y).commit();
            wait(30);
            compare(starts.count, 1, "Recrossing without returning to zero is the same excursion");
            returnAndRelease();
            Theme.scale = 3;
            wait(50);
            pull(row.height * .8);
            wait(270);
            verify(icon.ratio > .4 && icon.ratio < 1 && icon.opacity > .4,
                   "Expose resized feedback x=" + row.x + " ratio=" + icon.ratio + " opacity="
                   + icon.opacity);
            grabImage(scene).save("arrow-" + data.tag + "-resized.png");
            fuzzyCompare(icon.arrow.y, icon.animation.from, .1,
                         "Visible pre-threshold arrow must use the current icon size");
            returnAndRelease();
            compare(actions.count, 0);
        }

        name: "ArrowFeedback"
        when: windowShown
    }
}
