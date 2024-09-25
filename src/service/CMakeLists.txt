set(SMARTFIELD_SERVICE_SRCS smartfieldservice.cpp)
set(SMARTFIELD_SERVICE_HDRS smartfieldservice.h)

add_library(smartfield_service STATIC ${SMARTFIELD_SERVICE_SRCS} ${SMARTFIELD_SERVICE_HDRS})

include(GenerateExportHeader)
generate_export_header(smartfield_service)

target_include_directories(smartfield_service SYSTEM
                           PUBLIC ${CMAKE_CURRENT_BINARY_DIR})

target_include_directories(smartfield_service
                           PUBLIC ${CMAKE_SOURCE_DIR}/src/service)

target_compile_features(smartfield_service PUBLIC cxx_std_17)
set_target_properties(smartfield_service PROPERTIES AUTOMOC TRUE)

target_link_libraries(smartfield_service PRIVATE smartfield_core ${QGIS_CORE_LIBRARY})

target_link_libraries(smartfield_service PUBLIC Qt::Core Qt::Positioning
                                            Qt::CorePrivate)

install(FILES ${SMARTFIELD_SERVICE_HDRS} DESTINATION ${SMARTFIELD_INCLUDE_DIR})
install(
  TARGETS smartfield_service
  BUNDLE DESTINATION ${SMARTFIELD_BIN_DIR}
  RUNTIME DESTINATION ${SMARTFIELD_BIN_DIR}
  LIBRARY DESTINATION ${SMARTFIELD_LIB_DIR}
  ARCHIVE DESTINATION ${SMARTFIELD_LIB_DIR}
  FRAMEWORK DESTINATION ${SMARTFIELD_FW_SUBDIR}
  PUBLIC_HEADER DESTINATION ${SMARTFIELD_INCLUDE_DIR})
