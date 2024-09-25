find_package(Qt6QuickCompiler QUIET)
find_package(Qt6 COMPONENTS Quick)

file(GLOB_RECURSE QML_SOURCES "${CMAKE_CURRENT_SOURCE_DIR}/*.qml")
if(QtQuickCompiler_FOUND
   AND NOT CMAKE_BUILD_TYPE MATCHES Debug
   AND NOT CMAKE_BUILD_TYPE MATCHES RelWithDebInfo)
  qtquick_compiler_add_resources(QML_SOURCES
                                 ${CMAKE_CURRENT_SOURCE_DIR}/qml.qrc)
else()
  qt_add_resources(QML_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/qml.qrc)
endif()

add_library(smartfield_qml STATIC ${QML_SOURCES})
target_link_libraries(smartfield_qml PRIVATE Qt::Quick)

target_compile_definitions(
  smartfield_qml
  PRIVATE $<$<OR:$<CONFIG:Debug>,$<CONFIG:RelWithDebInfo>>:QT_QML_DEBUG>)
set_target_properties(smartfield_qml PROPERTIES LINKER_LANGUAGE CXX)

# For QtCreator
set(QML_IMPORT_PATH "${CMAKE_CURRENT_SOURCE_DIR}/imports")

file(GLOB smartfield_qmlfiles "${CMAKE_SOURCE_DIR}/src/qml/*.qml")
file(GLOB smartfield_qmlfiles_geometryeditors
     "${CMAKE_SOURCE_DIR}/src/qml/geometry_editors/*.qml")
file(GLOB smartfield_qmlfiles_editorwidgets
     "${CMAKE_SOURCE_DIR}/src/qml/editorwidgets/*.qml")
file(GLOB smartfield_qmlfiles_theme
     "${CMAKE_SOURCE_DIR}/src/qml/imports/Theme/*.qml")

list(APPEND smartfield_qmlfiles ${smartfield_qmlfiles_geometryeditors}
     ${smartfield_qmlfiles_editorwidgets} ${smartfield_qmlfiles_theme}
     ${smartfield_qmlfiles_theme_extra})

set_property(TARGET smartfield_qml PROPERTY QML_FILES ${smartfield_qmlfiles})

qt_import_qml_plugins(smartfield_qml)
