# AUTO enables the embedded keyboard for desktop Debug builds only.
set(QSHOPPER_DESKTOP_KEYBOARD "AUTO" CACHE STRING "Desktop virtual keyboard: AUTO, ON, or OFF")
set_property(CACHE QSHOPPER_DESKTOP_KEYBOARD PROPERTY STRINGS AUTO ON OFF)
if(NOT QSHOPPER_DESKTOP_KEYBOARD MATCHES "^(AUTO|ON|OFF)$")
    message(FATAL_ERROR "QSHOPPER_DESKTOP_KEYBOARD must be AUTO, ON, or OFF")
endif()
set(qshopper_keyboard_enabled OFF)
if(NOT ANDROID AND
   (QSHOPPER_DESKTOP_KEYBOARD STREQUAL "ON"
    OR (QSHOPPER_DESKTOP_KEYBOARD STREQUAL "AUTO" AND CMAKE_BUILD_TYPE STREQUAL "Debug")))
    set(qshopper_keyboard_enabled ON)
endif()
if(qshopper_keyboard_enabled)
    find_package(Qt6 REQUIRED COMPONENTS VirtualKeyboard)
    set(qshopper_keyboard_url "qrc:/qt/qml/QShopper/DesktopKeyboard.qml.in")
    # Keep the raw resource suffix so scans of other build trees cannot discover its imports.
    set(qshopper_keyboard_resource keyboard/DesktopKeyboard.qml.in)
    set(qshopper_keyboard_dependencies QtQuick.VirtualKeyboard QtQuick.VirtualKeyboard.Settings)
    set_source_files_properties(${qshopper_keyboard_resource} PROPERTIES
        QT_RESOURCE_ALIAS DesktopKeyboard.qml.in)
else()
    set(qshopper_keyboard_url "")
endif()
set(qshopper_keyboard_qml "${CMAKE_CURRENT_BINARY_DIR}/generated/DevelopmentKeyboard.qml")
configure_file(keyboard/DevelopmentKeyboard.qml.in "${qshopper_keyboard_qml}" @ONLY)
set_source_files_properties("${qshopper_keyboard_qml}" PROPERTIES
    QT_RESOURCE_ALIAS DevelopmentKeyboard.qml)

set_source_files_properties(Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

if(ANDROID)
    set(qshopper_qt_notices licenses/Qt-Android.txt)
elseif(qshopper_keyboard_enabled)
    set(qshopper_qt_notices licenses/Qt-Windows-Keyboard.txt)
else()
    set(qshopper_qt_notices licenses/Qt-Windows.txt)
endif()
set_source_files_properties(${qshopper_qt_notices} PROPERTIES QT_RESOURCE_ALIAS licenses/Qt.txt)

qt_add_library(QShopper STATIC)
qt_add_qml_module(QShopper
    URI QShopper
    VERSION 1.0
    OUTPUT_DIRECTORY ${PROJECT_BINARY_DIR}/QShopper
    QML_FILES
        AboutDialog.qml
        ArrowIcon.qml
        Background.qml
        BackgroundImage.qml
        CartInIcon.qml
        CartOutIcon.qml
        ColorComboBox.qml
        ColorModel.qml
        ComboBox.qml
        DefaultAnimation.qml
        Delegate.qml
        DelegateChoser.qml
        GroupBox.qml
        Icon.qml
        IconButton.qml
        IconChoser.qml
        InputDelegate.qml
        "${qshopper_keyboard_qml}"
        LoaderWindow.qml
        main.qml
        Menu.qml
        View.qml
        OpacityAnimation.qml
        Pulley.qml
        ShopView.qml
        Slider.qml
        SwipeHandler.qml
        TextDelegate.qml
        TextIcon.qml
        TextItem.qml
        Theme.qml
        TrashIcon.qml
        UndoBar.qml
        Weekdays.qml
        YAnimation.qml
    SOURCES
        logging.h logging.cpp
        licensenotices.h licensenotices.cpp
        model.h model.cpp
        undoremove.h undoremove.cpp
        weekmodel.h weekmodel.cpp
    RESOURCES
        ${qshopper_qt_notices}
        licenses/FontAwesome.txt
        logos/qt.svg
        logos/font-awesome.svg
        ${qshopper_keyboard_resource}
        backgrounds/01-phone-and-pantry.jpg
        backgrounds/02-produce.jpg
        backgrounds/03-bakery.jpg
        backgrounds/04-dairy.jpg
        backgrounds/05-bulk-goods.jpg
        backgrounds/06-market-hall.jpg
        backgrounds/07-checkout.jpg
        backgrounds/08-qshopper.jpg
        backgrounds/09-stocktaking.jpg
        backgrounds/10-evening-produce.jpg
        fa-solid-900.otf
    DEPENDENCIES QtCore QtQml.Models QtQuick.VectorImage ${qshopper_keyboard_dependencies}
)

target_link_libraries(QShopper PUBLIC Qt6::Quick Qt6::Sql Qt6::Core Qt6::Qml Qt6::QuickControls2)
target_include_directories(QShopper PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_compile_definitions(QShopper PUBLIC
    QSHOPPER_DESKTOP_KEYBOARD=$<BOOL:${qshopper_keyboard_enabled}>)
if(qshopper_keyboard_enabled)
    target_link_libraries(QShopper PRIVATE Qt6::VirtualKeyboard)
endif()

qt_add_executable(application main.cpp)
target_compile_definitions(application PRIVATE QSHOPPER_VERSION="${PROJECT_VERSION}")
target_link_libraries(application PRIVATE QShopper QShopperplugin)
set_target_properties(application PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER shopper.nevala.com
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

if(ANDROID)
    # Qt's deploy tool leaves obsolete native plugins in an existing staging
    # directory. Reconfiguration starts that generated project cleanly.
    set(android_staging_dir "${CMAKE_CURRENT_BINARY_DIR}/android-build")
    if(EXISTS "${android_staging_dir}")
        file(REAL_PATH "${CMAKE_CURRENT_BINARY_DIR}" android_build_root)
        file(REAL_PATH "${android_staging_dir}" android_staging_real)
        set(android_staging_expected "${android_build_root}/android-build")
        if(NOT android_staging_real STREQUAL android_staging_expected
           OR IS_SYMLINK "${android_staging_dir}")
            message(FATAL_ERROR "Refusing to clean Android staging outside the app build directory")
        endif()
        file(REMOVE_RECURSE "${android_staging_dir}")
    endif()

    # App assets are JPEG/PNG (PNG is built into Qt Gui), data is SQLite, and
    # Android supplies the IME. Keep only the native platform and used plugins.
    qt_import_plugins(application
        INCLUDE_BY_TYPE platforms Qt6::QAndroidIntegrationPlugin
        INCLUDE_BY_TYPE imageformats Qt6::QJpegPlugin
        INCLUDE_BY_TYPE sqldrivers Qt6::QSQLiteDriverPlugin
        EXCLUDE_BY_TYPE iconengines vectorimageformats tls networkinformation
        EXCLUDE Qt6::QVirtualKeyboardPlugin Qt6::QQuick3DProfilerAdapterFactoryPlugin)

    # Only an explicit QML-debugging build needs the on-device tooling plugins.
    # Release packages exclude both the plugins and debugging infrastructure.
    if(NOT QT_ENABLE_QML_DEBUG OR CMAKE_BUILD_TYPE MATCHES "^(Release|MinSizeRel)$")
        qt_import_plugins(application EXCLUDE_BY_TYPE qmltooling)
        set_property(TARGET application PROPERTY QT_ENABLE_QML_DEBUG OFF)
    endif()

    # Stage only app customizations; Qt supplies the matching Gradle tooling.
    set(android_package_dir "${CMAKE_CURRENT_BINARY_DIR}/android-package")
    configure_file("${PROJECT_SOURCE_DIR}/android/AndroidManifest.xml"
        "${android_package_dir}/AndroidManifest.xml" COPYONLY)
    file(GLOB android_icon_dirs "${PROJECT_SOURCE_DIR}/android/res/drawable*")
    file(COPY ${android_icon_dirs} DESTINATION "${android_package_dir}/res")
    if(CMAKE_BUILD_TYPE MATCHES "^(Release|MinSizeRel)$")
        # Extend this kit's template rather than maintaining a fork of Qt's Gradle setup.
        file(READ "${Qt6Core_DIR}/../../../src/android/templates/build.gradle" android_gradle)
        file(WRITE "${android_package_dir}/build.gradle"
            "${android_gradle}\napply from: 'release.gradle'\n")
        configure_file("${PROJECT_SOURCE_DIR}/android/release.gradle"
            "${android_package_dir}/release.gradle" COPYONLY)
        configure_file("${PROJECT_SOURCE_DIR}/android/qshopper.pro"
            "${android_package_dir}/qshopper.pro" COPYONLY)
        configure_file("${PROJECT_SOURCE_DIR}/android/res/raw/qshopper_keep.xml"
            "${android_package_dir}/res/raw/qshopper_keep.xml" COPYONLY)
    endif()
    set_target_properties(application PROPERTIES
        QT_ANDROID_PACKAGE_SOURCE_DIR "${android_package_dir}"
        QT_ANDROID_COMPILE_SDK_VERSION 36
        QT_ANDROID_APP_NAME "QShopper"
        QT_ANDROID_PACKAGE_NAME "shopper.nevala.com"
        QT_ANDROID_VERSION_NAME "${PROJECT_VERSION}"
        QT_ANDROID_VERSION_CODE ${QSHOPPER_ANDROID_VERSION_CODE}
    )
endif()

# The root test directory uses the same desktop-keyboard build gate.
set(qshopper_keyboard_enabled ${qshopper_keyboard_enabled} PARENT_SCOPE)
