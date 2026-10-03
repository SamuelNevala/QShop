cmake_minimum_required(VERSION 3.22)

find_package(Qt6 REQUIRED COMPONENTS Test QuickTest)

add_executable(qshopper_ui_tests test_ui.cpp)
add_dependencies(qshopper_ui_tests qdynamicspluginplugin)
set_target_properties(qshopper_ui_tests PROPERTIES AUTOMOC ON)
target_link_libraries(qshopper_ui_tests PRIVATE QShopper QShopperplugin Qt6::QuickTest)
target_compile_definitions(qshopper_ui_tests PRIVATE
    QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}/qml")
add_test(NAME qshopper_ui_tests COMMAND qshopper_ui_tests
    -import ${CMAKE_BINARY_DIR} -platform offscreen -o -,txt -o ui-tests.xml,junitxml)
set_tests_properties(qshopper_ui_tests PROPERTIES TIMEOUT 90
    ENVIRONMENT "QT_QUICK_BACKEND=software;QT_FORCE_STDERR_LOGGING=1")
if(WIN32)
    set_tests_properties(qshopper_ui_tests PROPERTIES ENVIRONMENT_MODIFICATION
        "PATH=path_list_prepend:$<TARGET_FILE_DIR:Qt6::Core>")
endif()
option(QSHOPPER_MODEL_COVERAGE "Measure model.h/model.cpp coverage and enforce 80%" OFF)

# The production QML backing library owns Model and UndoRemove. Compile only
# the test source here; the application and tests share the same library.
add_executable(qshopper_tests test_model.cpp)
set_target_properties(qshopper_tests PROPERTIES AUTOMOC ON)
target_link_libraries(qshopper_tests PRIVATE QShopper Qt6::Test)
add_test(NAME qshopper_tests COMMAND qshopper_tests -o -,txt -o model-tests.xml,junitxml)
set_tests_properties(qshopper_tests PROPERTIES ENVIRONMENT "QT_FORCE_STDERR_LOGGING=1" TIMEOUT 30)
if(WIN32)
    set_tests_properties(qshopper_tests PROPERTIES ENVIRONMENT_MODIFICATION
        "PATH=path_list_prepend:$<TARGET_FILE_DIR:Qt6::Core>")
endif()

if(QSHOPPER_MODEL_COVERAGE)
    if(NOT MSVC)
        message(FATAL_ERROR "Model coverage requires the MSVC toolchain")
    endif()
    find_package(Python3 REQUIRED COMPONENTS Interpreter)
    file(GLOB coverage_hints
        "$ENV{ProgramFiles}/Microsoft Visual Studio/*/*/Common7/IDE/Extensions/Microsoft/CodeCoverage.Console")
    find_program(MODEL_COVERAGE_TOOL NAMES Microsoft.CodeCoverage.Console.exe
        HINTS "$ENV{VSINSTALLDIR}/Common7/IDE/Extensions/Microsoft/CodeCoverage.Console"
              "${CMAKE_GENERATOR_INSTANCE}/Common7/IDE/Extensions/Microsoft/CodeCoverage.Console"
              ${coverage_hints} REQUIRED)
    # /PROFILE supplies the relocation and symbol data for native instrumentation.
    target_link_options(qshopper_tests PRIVATE /PROFILE /DEBUG:FULL /INCREMENTAL:NO)
    add_custom_target(model_coverage
        COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/coverage.py
            --build ${CMAKE_BINARY_DIR} --config $<CONFIG>
            --reports ${CMAKE_CURRENT_BINARY_DIR}/coverage
            --source ${PROJECT_SOURCE_DIR}
            --executable $<TARGET_FILE:qshopper_tests>
            --collector ${MODEL_COVERAGE_TOOL} --ctest ${CMAKE_CTEST_COMMAND}
        DEPENDS qshopper_tests
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        VERBATIM USES_TERMINAL)
endif()
