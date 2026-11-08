import QtQuick
import QtTest

Item {
    id: canvas

    width: 512
    height: 512

    Image {
        id: art

        anchors.fill: parent
        source: "launcher.svg"
        sourceSize: Qt.size(canvas.width, canvas.height)
    }

    TestCase {
        function test_export_data() {
            const result = [];
            for (const entry of [["ldpi", 36], ["mdpi", 48], ["hdpi", 72], ["xhdpi", 96], ["xxhdpi",
                                                                                           144], ["xxxhdpi",
                                                                                                  192]]) {
                result.push({
                                tag: entry[0],
                                size: entry[1],
                                path: "android/res/drawable-" + entry[0] + "/icon.png"
                            });
            }
            result.push({
                            tag: "preview",
                            size: 512,
                            path: "artwork/UX-006/preview.png"
                        });
            return result;
        }

        function test_export(data) {
            canvas.width = data.size;
            canvas.height = data.size;
            tryCompare(art, "status", Image.Ready);
            wait(50);
            let finished = false;
            let saved = false;
            verify(canvas.grabToImage(function (result) {
                saved = result.saveToFile(data.path);
                finished = true;
            }, Qt.size(data.size, data.size)));
            tryVerify(function () {
                return finished;
            });
            verify(saved);
        }

        name: "ExportLauncherIcon"
        when: windowShown
    }
}
