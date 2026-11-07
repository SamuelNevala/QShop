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
add_test(NAME qshopper_fastundo_tests COMMAND qshopper_ui_tests
    -input ${CMAKE_CURRENT_SOURCE_DIR}/fastundo -import ${CMAKE_BINARY_DIR}
    -platform offscreen -o -,txt -o fastundo-tests.xml,junitxml)
set_tests_properties(qshopper_fastundo_tests PROPERTIES TIMEOUT 100)
list(APPEND qshopper_qml_tests qshopper_fastundo_tests)
add_test(NAME qshopper_arrowfeedback_tests COMMAND qshopper_ui_tests
    -input ${CMAKE_CURRENT_SOURCE_DIR}/arrowfeedback -import ${CMAKE_BINARY_DIR}
    -platform offscreen -o -,txt -o arrowfeedback-tests.xml,junitxml)
set_tests_properties(qshopper_arrowfeedback_tests PROPERTIES TIMEOUT 90)
list(APPEND qshopper_qml_tests qshopper_arrowfeedback_tests)
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
add_test(NAME qshopper_contrast_tests COMMAND qshopper_ui_tests
    -input ${CMAKE_CURRENT_SOURCE_DIR}/contrast -import ${CMAKE_BINARY_DIR}
    -platform offscreen -o -,txt -o contrast-tests.xml,junitxml)
set_tests_properties(qshopper_contrast_tests PROPERTIES TIMEOUT 120)
list(APPEND qshopper_qml_tests qshopper_contrast_tests)
add_test(NAME qshopper_popupcontrast_tests COMMAND qshopper_ui_tests
    -input ${CMAKE_CURRENT_SOURCE_DIR}/popupcontrast -import ${CMAKE_BINARY_DIR}
    -platform offscreen -o -,txt -o popupcontrast-tests.xml,junitxml)
set_tests_properties(qshopper_popupcontrast_tests PROPERTIES TIMEOUT 300)
list(APPEND qshopper_qml_tests qshopper_popupcontrast_tests)
add_test(NAME qshopper_swipecontrast_tests COMMAND qshopper_ui_tests
    -input ${CMAKE_CURRENT_SOURCE_DIR}/swipecontrast -import ${CMAKE_BINARY_DIR}
    -platform offscreen -o -,txt -o swipecontrast-tests.xml,junitxml)
set_tests_properties(qshopper_swipecontrast_tests PROPERTIES TIMEOUT 240)
list(APPEND qshopper_qml_tests qshopper_swipecontrast_tests)
add_test(NAME qshopper_customcolor_tests COMMAND qshopper_ui_tests
    -input ${CMAKE_CURRENT_SOURCE_DIR}/customcolors -import ${CMAKE_BINARY_DIR}
    -platform offscreen -o -,txt -o customcolor-tests.xml,junitxml)
set_tests_properties(qshopper_customcolor_tests PROPERTIES TIMEOUT 360)
list(APPEND qshopper_qml_tests qshopper_customcolor_tests)
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
    add_test(NAME qshopper_fastundo_rendering_tests COMMAND qshopper_ui_tests
        -input ${CMAKE_CURRENT_SOURCE_DIR}/fastundo -import ${CMAKE_BINARY_DIR}
        -platform windows -o -,txt -o fastundo-rendering-tests.xml,junitxml)
    set_tests_properties(qshopper_fastundo_rendering_tests PROPERTIES TIMEOUT 100
        ENVIRONMENT "QT_QUICK_BACKEND=rhi;QSG_RHI_BACKEND=d3d11;QSG_RHI_PREFER_SOFTWARE_RENDERER=1;QT_FORCE_STDERR_LOGGING=1")
    list(APPEND qshopper_qml_tests qshopper_fastundo_rendering_tests)
    add_test(NAME qshopper_arrowfeedback_rendering_tests COMMAND qshopper_ui_tests
        -input ${CMAKE_CURRENT_SOURCE_DIR}/arrowfeedback -import ${CMAKE_BINARY_DIR}
        -platform windows -o -,txt -o arrowfeedback-rendering-tests.xml,junitxml)
    set_tests_properties(qshopper_arrowfeedback_rendering_tests PROPERTIES TIMEOUT 90
        ENVIRONMENT "QT_QUICK_BACKEND=rhi;QSG_RHI_BACKEND=d3d11;QSG_RHI_PREFER_SOFTWARE_RENDERER=1;QT_FORCE_STDERR_LOGGING=1")
    list(APPEND qshopper_qml_tests qshopper_arrowfeedback_rendering_tests)
    set_property(TEST qshopper_customcolor_tests APPEND PROPERTY ENVIRONMENT
        "QT_QPA_FONTDIR=$ENV{WINDIR}/Fonts")
    add_test(NAME qshopper_customcolor_rendering_tests COMMAND qshopper_ui_tests
        -input ${CMAKE_CURRENT_SOURCE_DIR}/customcolors -import ${CMAKE_BINARY_DIR}
        -platform windows -o -,txt -o customcolor-rendering-tests.xml,junitxml)
    set_tests_properties(qshopper_customcolor_rendering_tests PROPERTIES TIMEOUT 360
        ENVIRONMENT "QT_QUICK_BACKEND=rhi;QSG_RHI_BACKEND=d3d11;QSG_RHI_PREFER_SOFTWARE_RENDERER=1;QT_FORCE_STDERR_LOGGING=1")
    list(APPEND qshopper_qml_tests qshopper_customcolor_rendering_tests)
    set_property(TEST qshopper_swipecontrast_tests APPEND PROPERTY ENVIRONMENT
        "QT_QPA_FONTDIR=$ENV{WINDIR}/Fonts")
    add_test(NAME qshopper_swipecontrast_rendering_tests COMMAND qshopper_ui_tests
        -input ${CMAKE_CURRENT_SOURCE_DIR}/swipecontrast -import ${CMAKE_BINARY_DIR}
        -platform windows -o -,txt -o swipecontrast-rendering-tests.xml,junitxml)
    set_tests_properties(qshopper_swipecontrast_rendering_tests PROPERTIES TIMEOUT 240
        ENVIRONMENT "QT_QUICK_BACKEND=rhi;QSG_RHI_BACKEND=d3d11;QSG_RHI_PREFER_SOFTWARE_RENDERER=1;QT_FORCE_STDERR_LOGGING=1")
    list(APPEND qshopper_qml_tests qshopper_swipecontrast_rendering_tests)
    # These checks count actual text glyph pixels, including offscreen rendering.
    set_property(TEST qshopper_contrast_tests APPEND PROPERTY ENVIRONMENT
        "QT_QPA_FONTDIR=$ENV{WINDIR}/Fonts")
    set_property(TEST qshopper_popupcontrast_tests APPEND PROPERTY ENVIRONMENT
        "QT_QPA_FONTDIR=$ENV{WINDIR}/Fonts")
    add_test(NAME qshopper_popupcontrast_rendering_tests COMMAND qshopper_ui_tests
        -input ${CMAKE_CURRENT_SOURCE_DIR}/popupcontrast -import ${CMAKE_BINARY_DIR}
        -platform windows -o -,txt -o popupcontrast-rendering-tests.xml,junitxml)
    set_tests_properties(qshopper_popupcontrast_rendering_tests PROPERTIES TIMEOUT 300
        ENVIRONMENT "QT_QUICK_BACKEND=rhi;QSG_RHI_BACKEND=d3d11;QSG_RHI_PREFER_SOFTWARE_RENDERER=1;QT_FORCE_STDERR_LOGGING=1")
    list(APPEND qshopper_qml_tests qshopper_popupcontrast_rendering_tests)
    add_test(NAME qshopper_contrast_rendering_tests COMMAND qshopper_ui_tests
        -input ${CMAKE_CURRENT_SOURCE_DIR}/contrast -import ${CMAKE_BINARY_DIR}
        -platform windows -o -,txt -o contrast-rendering-tests.xml,junitxml)
    set_tests_properties(qshopper_contrast_rendering_tests PROPERTIES TIMEOUT 120
        ENVIRONMENT "QT_QUICK_BACKEND=rhi;QSG_RHI_BACKEND=d3d11;QSG_RHI_PREFER_SOFTWARE_RENDERER=1;QT_FORCE_STDERR_LOGGING=1")
    list(APPEND qshopper_qml_tests qshopper_contrast_rendering_tests)
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
