import QShopper
import QtQuick
import QtTest

Item {
    id: scene

    width: 100
    height: 100

    Component {
        id: modelComponent

        Model {
            activeList: "default"
        }
    }

    Component {
        id: observerComponent

        QtObject {
            required property var source
            property bool available: source.canUndo
        }
    }

    Component {
        id: spyComponent

        SignalSpy {}
    }

    TestCase {
        function init() {
            failOnWarning(/.*/);
            uiSetup.resetDatabase();
        }

        function test_readonly_updates_undo_binding_data() {
            return [
                        {
                            tag: "undo-become-readonly",
                            hasUndo: true,
                            initialReadOnly: false
                        },
                        {
                            tag: "undo-become-writable",
                            hasUndo: true,
                            initialReadOnly: true
                        },
                        {
                            tag: "empty-become-readonly",
                            hasUndo: false,
                            initialReadOnly: false
                        },
                        {
                            tag: "empty-become-writable",
                            hasUndo: false,
                            initialReadOnly: true
                        }
                    ];
        }

        function test_readonly_updates_undo_binding(data) {
            const model = createTemporaryObject(modelComponent, scene);
            verify(model !== null);
            if (data.hasUndo) {
                model.insert(0, "Milk");
                model.remove(0);
            }
            compare(model.canUndo, data.hasUndo);
            model.readOnly = data.initialReadOnly;
            const observer = createTemporaryObject(observerComponent, scene, {
                                                       source: model
                                                   });
            verify(observer !== null);
            const undoSpy = createTemporaryObject(spyComponent, scene, {
                                                      target: model,
                                                      signalName: "canUndoChanged"
                                                  });
            const readOnlySpy = createTemporaryObject(spyComponent, scene, {
                                                          target: model,
                                                          signalName: "readOnlyChanged"
                                                      });
            verify(undoSpy.valid);
            verify(readOnlySpy.valid);
            compare(observer.available, data.hasUndo && !data.initialReadOnly);

            model.readOnly = data.initialReadOnly;
            compare(undoSpy.count, 0);
            compare(readOnlySpy.count, 0);

            model.readOnly = !data.initialReadOnly;
            compare(model.canUndo, data.hasUndo && data.initialReadOnly);
            compare(observer.available, data.hasUndo && data.initialReadOnly);
            compare(undoSpy.count, data.hasUndo ? 1 : 0);
            compare(readOnlySpy.count, 1);

            model.readOnly = data.initialReadOnly;
            compare(model.canUndo, data.hasUndo && !data.initialReadOnly);
            compare(observer.available, data.hasUndo && !data.initialReadOnly);
            compare(undoSpy.count, data.hasUndo ? 2 : 0);
            compare(readOnlySpy.count, 2);
            model.readOnly = data.initialReadOnly;
            compare(undoSpy.count, data.hasUndo ? 2 : 0);
            compare(readOnlySpy.count, 2);

            // Read-only changes must preserve the command for later use.
            model.readOnly = false;
            model.undo();
            compare(model.rowCount(), data.hasUndo ? 1 : 0);
            compare(model.canUndo, false);
            compare(observer.available, false);
        }

        name: "ModelProperties"
        when: windowShown
    }
}
