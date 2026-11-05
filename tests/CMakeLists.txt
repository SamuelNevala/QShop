find_package(Qt6 REQUIRED COMPONENTS Test QuickTest)

add_executable(qshopper_ui_tests test_ui.cpp)
target_link_libraries(qshopper_ui_tests PRIVATE QShopper QShopperplugin Qt6::QuickTest)
target_compile_definitions(qshopper_ui_tests PRIVATE
    QUICK_TEST_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}/qml"
    QSHOPPER_EXPECT_PREVIEW=$<AND:$<NOT:$<BOOL:${ANDROID}>>,$<CONFIG:Debug>>)
add_test(NAME qshopper_ui_tests COMMAND qshopper_ui_tests
    -import ${CMAKE_BINARY_DIR} -platform offscreen -o -,txt -o ui-tests.xml,junitxml)
set_tests_properties(qshopper_ui_tests PROPERTIES TIMEOUT 225)
add_test(NAME qshopper_flow_tests COMMAND qshopper_ui_tests
    -input ${CMAKE_CURRENT_SOURCE_DIR}/flows -import ${CMAKE_BINARY_DIR}
    -platform offscreen -o -,txt -o flow-tests.xml,junitxml)
set_tests_properties(qshopper_flow_tests PROPERTIES TIMEOUT 120)
set(qshopper_qml_tests qshopper_ui_tests qshopper_flow_tests)
add_test(NAME qshopper_about_tests COMMAND qshopper_ui_tests
    -input ${CMAKE_CURRENT_SOURCE_DIR}/about -import ${CMAKE_BINARY_DIR}
    -platform offscreen -o -,txt -o about-tests.xml,junitxml)
set_tests_properties(qshopper_about_tests PROPERTIES TIMEOUT 90)
list(APPEND qshopper_qml_tests qshopper_about_tests)
add_test(NAME qshopper_background_tests COMMAND qshopper_ui_tests
    -input ${CMAKE_CURRENT_SOURCE_DIR}/backgrounds -import ${CMAKE_BINARY_DIR}
    -platform offscreen -o -,txt -o background-tests.xml,junitxml)
set_tests_properties(qshopper_background_tests PROPERTIES TIMEOUT 60)
list(APPEND qshopper_qml_tests qshopper_background_tests)
if(qshopper_keyboard_enabled)
    add_test(NAME qshopper_keyboard_tests COMMAND qshopper_ui_tests
        -input ${CMAKE_CURRENT_SOURCE_DIR}/keyboard -import ${CMAKE_BINARY_DIR}
        -platform offscreen -o -,txt -o keyboard-tests.xml,junitxml)
    set_tests_properties(qshopper_keyboard_tests PROPERTIES TIMEOUT 90)
    list(APPEND qshopper_qml_tests qshopper_keyboard_tests)
endif()
set_tests_properties(${qshopper_qml_tests} PROPERTIES
    ENVIRONMENT "QT_QUICK_BACKEND=software;QT_FORCE_STDERR_LOGGING=1")
if(qshopper_keyboard_enabled)
    set_property(TEST qshopper_keyboard_tests APPEND PROPERTY ENVIRONMENT
        "QT_IM_MODULE=qtvirtualkeyboard" "QT_VIRTUALKEYBOARD_DESKTOP_DISABLE=1")
endif()

# The production QML backing library owns Model and UndoRemove. Compile only
# the test source here; the application and tests share the same library.
add_executable(qshopper_tests test_model.cpp)
target_link_libraries(qshopper_tests PRIVATE QShopper Qt6::Test)
add_test(NAME qshopper_tests COMMAND qshopper_tests -o -,txt -o model-tests.xml,junitxml)
set_tests_properties(qshopper_tests PROPERTIES ENVIRONMENT "QT_FORCE_STDERR_LOGGING=1" TIMEOUT 30)
if(WIN32)
    add_test(NAME qshopper_background_rendering_tests COMMAND qshopper_ui_tests
        -input ${CMAKE_CURRENT_SOURCE_DIR}/backgrounds -import ${CMAKE_BINARY_DIR}
        -platform windows -o -,txt -o background-rendering-tests.xml,junitxml)
    set_tests_properties(qshopper_background_rendering_tests PROPERTIES TIMEOUT 60
        ENVIRONMENT "QT_QUICK_BACKEND=rhi;QSG_RHI_BACKEND=d3d11;QSG_RHI_PREFER_SOFTWARE_RENDERER=1;QT_FORCE_STDERR_LOGGING=1")
    list(APPEND qshopper_qml_tests qshopper_background_rendering_tests)
    add_test(NAME qshopper_about_rendering_tests COMMAND qshopper_ui_tests
        -input ${CMAKE_CURRENT_SOURCE_DIR}/about -import ${CMAKE_BINARY_DIR}
        -platform windows -o -,txt -o about-rendering-tests.xml,junitxml)
    set_tests_properties(qshopper_about_rendering_tests PROPERTIES TIMEOUT 90
        ENVIRONMENT "QT_QUICK_BACKEND=rhi;QSG_RHI_BACKEND=d3d11;QSG_RHI_PREFER_SOFTWARE_RENDERER=1;QT_FORCE_STDERR_LOGGING=1")
    # Verify the floating Undo surface and actual font with native rendering.
    add_test(NAME qshopper_undo_rendering_tests COMMAND qshopper_ui_tests
        -input ${CMAKE_CURRENT_SOURCE_DIR}/rendering -import ${CMAKE_BINARY_DIR}
        -platform windows -o -,txt -o undo-rendering-tests.xml,junitxml)
    set_tests_properties(qshopper_undo_rendering_tests PROPERTIES TIMEOUT 45
        ENVIRONMENT "QT_QUICK_BACKEND=rhi;QSG_RHI_BACKEND=d3d11;QSG_RHI_PREFER_SOFTWARE_RENDERER=1;QT_FORCE_STDERR_LOGGING=1")
    list(APPEND qshopper_qml_tests qshopper_undo_rendering_tests qshopper_about_rendering_tests)
    set_tests_properties(${qshopper_qml_tests} qshopper_tests PROPERTIES ENVIRONMENT_MODIFICATION
        "PATH=path_list_prepend:$<TARGET_FILE_DIR:Qt6::Core>")
endif()

option(QSHOPPER_MODEL_COVERAGE "Measure model.h/model.cpp coverage and enforce 80%" OFF)
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
            --source ${PROJECT_SOURCE_DIR}/app
            --executable $<TARGET_FILE:qshopper_tests>
            --collector ${MODEL_COVERAGE_TOOL} --ctest ${CMAKE_CTEST_COMMAND}
        DEPENDS qshopper_tests
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
        VERBATIM USES_TERMINAL)
endif()
