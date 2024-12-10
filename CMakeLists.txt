cmake_minimum_required(VERSION 3.16)

project(QShopper VERSION 0.1 LANGUAGES CXX)

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
# set(QML_IMPORT_PATH "${CMAKE_CURRENT_BINARY_DIR}" CACHE STRING "Qt Creator QML import paths" FORCE)
set(QT_QML_GENERATE_QMLLS_INI ON)
# set(QML_IMPORT_TRACE  1)

find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick Sql)

qt_standard_project_setup(REQUIRES 6.8)

# set(QUICK_DYNAMICS_INSTALL_DIR ${QT6_INSTALL_PREFIX}/${QT6_INSTALL_QML}/QuickDynamics)
# set(QML_INSTALL_DIR ${QT6_INSTALL_PREFIX}/${QT6_INSTALL_QML})
# find_library(QuickDynamics_LIB quickdynamicsplugin PATHS ${QUICK_DYNAMICS_INSTALL_DIR})

# message("QuickDynamics_LIB:", ${QuickDynamics_LIB})

# qt_policy(SET QTP0001 NEW)

# set(QML_IMPORT_PATH "${QUICK_DYNAMICS_INSTALL_DIR}" CACHE STRING "QuickDynamics extension import path")

qt_add_executable(application
    main.cpp
)

# target_compile_definitions(appQShopper PRIVATE QML_IMPORT_PATH="${QUICK_DYNAMICS_INSTALL_DIR}")
# target_link_libraries(MyApp PRIVATE Qt6::Quick)
# # Add the QML import path to the engine in main.cpp
# target_compile_definitions(MyApp PRIVATE QML_IMPORT_PATH="${QML_IMPORT_PATH}")

qt_add_qml_module(application
    URI QShopper
    VERSION 1.0
    QML_FILES
        ArrowIcon.qml
        Background.qml
        BackgroundImage.qml
        CartInIcon.qml
        CartOutIcon.qml
        Delegate.qml
        DelegateChoser.qml
        Icon.qml
        IconChoser.qml
        InputDelegate.qml
        main.qml
        View.qml
        OpacityAnimation.qml
        Pulley.qml
        ShopView.qml
        SwipeHandler.qml
        TextDelegate.qml
        TextIcon.qml
        TextItem.qml
        TrashIcon.qml
        UndoIcon.qml
        Weekdays.qml
        WheelIcon.qml
        YAnimation.qml
    SOURCES
        model.h model.cpp
        undoremove.h undoremove.cpp
        weekmodel.h weekmodel.cpp
    RESOURCES
        background_one.jpg
        background_two.jpg
        background_three.jpg
        background_four.jpg
        background_five.jpg
        fa-solid-900.ttf
    DEPENDENCIES QtCore
)

add_subdirectory(QDynamics)

set_target_properties(application PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER shopper.nevala.com
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(application PRIVATE Qt6::Quick Qt6::Sql Qt6::Core Qt6::Qml)

install(TARGETS application
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})

message("QML_IMPORT_PATH" ${QML_IMPORT_PATH})
