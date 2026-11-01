cmake_minimum_required(VERSION 3.25)

project(QShopper VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(QT_QML_GENERATE_QMLLS_INI ON)

find_package(Qt6 6.10 REQUIRED COMPONENTS Core Qml Quick Sql QuickControls2)

# View.qml uses FlexboxLayout, introduced in Qt 6.10.
qt_standard_project_setup(REQUIRES 6.10)

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

qt_add_library(QShopper STATIC)
qt_add_qml_module(QShopper
    URI QShopper
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/QShopper
    QML_FILES
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
        UndoIcon.qml
        Weekdays.qml
        WheelIcon.qml
        YAnimation.qml
    SOURCES
        model.h model.cpp
        sortfilterproxymodel.h sortfilterproxymodel.cpp
        undoremove.h undoremove.cpp
        weekmodel.h weekmodel.cpp
    RESOURCES
        ${qshopper_keyboard_resource}
        background_one.jpg
        background_two.jpg
        background_three.jpg
        background_four.jpg
        background_five.jpg
        fa-solid-900.ttf
    DEPENDENCIES QtCore ${qshopper_keyboard_dependencies}
)

target_link_libraries(QShopper PUBLIC Qt6::Quick Qt6::Sql Qt6::Core Qt6::Qml Qt6::QuickControls2)
target_include_directories(QShopper PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
target_compile_definitions(QShopper PUBLIC
    QSHOPPER_DESKTOP_KEYBOARD=$<BOOL:${qshopper_keyboard_enabled}>)
if(qshopper_keyboard_enabled)
    target_link_libraries(QShopper PRIVATE Qt6::VirtualKeyboard)
endif()

qt_add_executable(application main.cpp)
target_link_libraries(application PRIVATE QShopper QShopperplugin)
set_target_properties(application PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER shopper.nevala.com
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

if(ANDROID)
    # Stage only app customizations; Qt supplies the matching Gradle tooling.
    set(android_package_dir "${CMAKE_CURRENT_BINARY_DIR}/android-package")
    configure_file(android/AndroidManifest.xml
        "${android_package_dir}/AndroidManifest.xml" COPYONLY)
    file(GLOB android_icon_dirs "${CMAKE_CURRENT_SOURCE_DIR}/android/res/drawable-*")
    file(COPY ${android_icon_dirs} DESTINATION "${android_package_dir}/res")
    set_target_properties(application PROPERTIES
        QT_ANDROID_PACKAGE_SOURCE_DIR "${android_package_dir}"
        QT_ANDROID_COMPILE_SDK_VERSION 36
        QT_ANDROID_APP_NAME "QShopper"
        QT_ANDROID_PACKAGE_NAME "shopper.nevala.com"
        QT_ANDROID_VERSION_NAME "${PROJECT_VERSION}"
        QT_ANDROID_VERSION_CODE 1
    )
endif()

include(CTest)
if(BUILD_TESTING)
    add_subdirectory(tests)
endif()

install(TARGETS application
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})
