cmake_minimum_required(VERSION 3.25)

project(QShopper VERSION 0.1.0 LANGUAGES CXX)
set(QSHOPPER_ANDROID_VERSION_CODE 2)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(QT_QML_GENERATE_QMLLS_INI ON)

# Android scans app/ recursively; generated output must stay outside it.
set(qshopper_source_dir "${CMAKE_CURRENT_SOURCE_DIR}/app")
cmake_path(IS_PREFIX qshopper_source_dir "${CMAKE_BINARY_DIR}" NORMALIZE build_inside_app)
if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR OR build_inside_app)
    message(FATAL_ERROR "Use an out-of-source build directory outside app/")
endif()

find_package(Qt6 6.12 REQUIRED COMPONENTS Core Qml Quick Sql QuickControls2)

# Qt 6.12 is the validated Windows and Android baseline.
qt_standard_project_setup(REQUIRES 6.12)

include(CTest)
add_subdirectory(app)

if(BUILD_TESTING)
    add_subdirectory(tests)
endif()

install(TARGETS application
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})
