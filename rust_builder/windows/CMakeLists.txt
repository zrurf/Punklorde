# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "rust_lib_punklorde")
project(${PROJECT_NAME} LANGUAGES CXX)

include("../cargokit/cmake/cargokit.cmake")
apply_cargokit(${PROJECT_NAME} ../../../../../../rust rust_lib_punklorde "")

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(TUNNEL_DLL "${CMAKE_CURRENT_BINARY_DIR}/$<CONFIG>/tunnel.dll")
# tunnel.dll is built by Cargo build.rs and placed alongside rust_lib_punklorde.dll
# in the cargo target dir. Copy it to the CMake output dir so it gets bundled.
add_custom_command(
  OUTPUT ${TUNNEL_DLL}
  COMMAND ${CMAKE_COMMAND} -E copy_if_different
    "${CMAKE_CURRENT_BINARY_DIR}/cargokit_build/x86_64-pc-windows-msvc/$<CONFIG>/tunnel.dll"
    ${TUNNEL_DLL}
  DEPENDS "${${PROJECT_NAME}_cargokit_lib}"
  COMMENT "Copying tunnel.dll for bundling"
)
add_custom_target(${PROJECT_NAME}_copy_tunnel ALL DEPENDS ${TUNNEL_DLL})
add_dependencies(${PROJECT_NAME}_cargokit ${PROJECT_NAME}_copy_tunnel)

set(rust_lib_punklorde_bundled_libraries
  "${${PROJECT_NAME}_cargokit_lib}"
  ${TUNNEL_DLL}
  PARENT_SCOPE
)
