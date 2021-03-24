#
#  CMakeLists.txt
#  Copyright 2021 ItJustWorksTM
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#

cmake_minimum_required (VERSION 3.17)

project (godot-smce VERSION 1.1.3 LANGUAGES CXX)

set (CMAKE_CXX_STANDARD 20)
set (CMAKE_CXX_STANDARD_REQUIRED ON)
set (CMAKE_CXX_EXTENSIONS OFF)
set (CMAKE_POSITION_INDEPENDENT_CODE ON)

include (CheckIPOSupported)
check_ipo_supported (RESULT CMAKE_IPO_SUPPORTED LANGUAGES CXX)
set (CMAKE_INTERPROCEDURAL_OPTIMIZATION ${CMAKE_IPO_SUPPORTED})

list (APPEND CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/CMake/Modules")
set (SMCE_AUTODOWNLOAD True)
include (FetchContent)
include (fmt)
include (SetupSMCE)
list (APPEND GDCPP_NEEDED_CLASSES Reference Node Resource)
include (SetupGodotCpp)

add_library (godot-smce MODULE)
target_sources (godot-smce PRIVATE
        src/lib.cxx
        src/bind/BoardRunner.cxx
        src/bind/ExecutionContext.cxx
        src/bind/BoardView.cxx
        src/bind/UartSlurper.cxx
        src/bind/BoardConfig.cxx)
target_include_directories (godot-smce PRIVATE include)
target_link_libraries (godot-smce PUBLIC godot-cpp SMCE fmt::fmt)
if (NOT CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    set_target_properties (godot-smce PROPERTIES LINK_FLAGS_RELEASE -s)
    if (NOT APPLE AND CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
        target_link_options (godot-smce PRIVATE -static-libstdc++ -static-libgcc)
    endif ()
endif ()

find_program (GODOT_EXECUTABLE NAMES godot3-headless godot3-server godot3 godot REQUIRED)
file (MAKE_DIRECTORY "${PROJECT_SOURCE_DIR}/project/gdnative/lib/RtResources")
add_custom_command (TARGET godot-smce POST_BUILD
        COMMAND "${CMAKE_COMMAND}" -E copy "$<TARGET_FILE:godot-smce>" "${PROJECT_SOURCE_DIR}/project/gdnative/lib/"
        COMMAND "${CMAKE_COMMAND}" -E tar xf "${SMCE_ROOT}/share/SMCE/SMCE_Resources.zip"
        COMMAND "${CMAKE_COMMAND}" -E copy_directory "./RtResources" "${PROJECT_SOURCE_DIR}/project/share/RtResources"
        COMMAND "${CMAKE_COMMAND}" -E rm -rf "./RtResources"
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}"
)

if (NOT SMCE_ARCH)
    set (SMCE_ARCH x86_64)
endif ()
if (CMAKE_CXX_SIMULATE_ID)
    set (SMCE_COMPILER_ID "${CMAKE_CXX_SIMULATE_ID}")
else ()
    set (SMCE_COMPILER_ID "${CMAKE_CXX_COMPILER_ID}")
endif ()
set (CPACK_SYSTEM_NAME "${CMAKE_SYSTEM_NAME}-${SMCE_ARCH}-${SMCE_COMPILER_ID}")
set (CPACK_PACKAGE_NAME "SMCE Godot")
set (CPACK_PACKAGE_FILE_NAME "smce_gd-${PROJECT_VERSION}-${CPACK_SYSTEM_NAME}")
set (CPACK_PACKAGE_VENDOR "ItJustWorksTM")
set (CPACK_PACKAGE_CONTACT "ItJustWorksTM <itjustworkstm@aerostun.dev>")
set (CPACK_PACKAGE_HOMEPAGE_URL "https://github.com/ItJustWorksTM/smce-gd")
set (CPACK_DEBIAN_PACKAGE_NAME "smce_gd")
set (CPACK_DEBIAN_PACKAGE_DESCRIPTION "An emulated environment for Arduino-based vehicles; primarily designed for use with the smartcar_shield library.")
set (CPACK_DEBIAN_PACKAGE_SECTION "embedded")
set (CPACK_DEBIAN_PACKAGE_CONTROL_EXTRA "${PROJECT_SOURCE_DIR}/debian/postinst" "${PROJECT_SOURCE_DIR}/debian/postrm")
set (CPACK_DEBIAN_COMPRESSION_TYPE "xz")
set (CPACK_WIX_UPGRADE_GUID 0602a6db-61aa-4440-80f9-547cec5db5b9)
set (CPACK_WIX_ROOT_FEATURE_TITLE "SMCE Godot")
set (CPACK_WIX_PRODUCT_ICON "${PROJECT_SOURCE_DIR}/project/media/images/icon.png")
set (CPACK_DMG_BACKGROUND_IMAGE "${PROJECT_SOURCE_DIR}/project/media/images/icon.png")
execute_process (COMMAND "${CMAKE_COMMAND}" -E copy "${PROJECT_SOURCE_DIR}/LICENSE" "${PROJECT_BINARY_DIR}/LICENSE.txt")
set (CPACK_RESOURCE_FILE_LICENSE "${PROJECT_BINARY_DIR}/LICENSE.txt")

if (WIN32)
    set (GODOT_PLATFORM windows)
elseif (APPLE)
    set (GODOT_PLATFORM macos)
else ()
    set (GODOT_PLATFORM linux)
endif ()
file (REMOVE_RECURSE "${PROJECT_BINARY_DIR}/export")
file (MAKE_DIRECTORY "${PROJECT_BINARY_DIR}/export")
if (NOT APPLE)
    install (CODE "execute_process (COMMAND \"${GODOT_EXECUTABLE}\" --no-window --export-debug \"${GODOT_PLATFORM}\" \"${PROJECT_BINARY_DIR}/export/smce_gd${CMAKE_EXECUTABLE_SUFFIX}\" WORKING_DIRECTORY \"${CMAKE_SOURCE_DIR}/project\")")
    install (PROGRAMS "${PROJECT_BINARY_DIR}/export/smce_gd${CMAKE_EXECUTABLE_SUFFIX}" DESTINATION "${CMAKE_INSTALL_LIBDIR}/smce")
    set_property (INSTALL "${CMAKE_INSTALL_LIBDIR}/smce/smce_gd${CMAKE_EXECUTABLE_SUFFIX}" PROPERTY CPACK_START_MENU_SHORTCUTS "SMCE Godot")
    install (FILES "${PROJECT_BINARY_DIR}/export/$<TARGET_FILE_NAME:godot-smce>" DESTINATION "${CMAKE_INSTALL_LIBDIR}/smce")
    if (NOT WIN32)
        install (FILES "${PROJECT_SOURCE_DIR}/smce_gd.desktop" DESTINATION "share/applications")
    endif ()
else ()
    install (CODE "
        execute_process (COMMAND \"${GODOT_EXECUTABLE}\" --no-window --export-debug \"${GODOT_PLATFORM}\" \"${PROJECT_BINARY_DIR}/export/SMCE-Godot\"
                         WORKING_DIRECTORY \"${CMAKE_SOURCE_DIR}/project\")
        execute_process (COMMAND \"${CMAKE_COMMAND}\" -E tar xf \"${PROJECT_BINARY_DIR}/export/SMCE-Godot\"
                         WORKING_DIRECTORY \"${PROJECT_BINARY_DIR}/export\")
        execute_process (COMMAND defaults write \"${PROJECT_BINARY_DIR}/export/SMCE-Godot.app/Contents/Info.plist\" LSEnvironment -dict PATH \"/bin:/usr/bin:/usr/local/bin:/opt/homebrew/bin:\")
        file (INSTALL \"${PROJECT_BINARY_DIR}/export/SMCE-Godot.app\" DESTINATION \"\${CMAKE_INSTALL_PREFIX}\" USE_SOURCE_PERMISSIONS)
    ")
endif ()

if (APPLE)
    set (CPACK_GENERATOR DragNDrop)
elseif (WIN32)
    set (CPACK_GENERATOR ZIP 7Z WIX)
else ()
    set (CPACK_GENERATOR TGZ STGZ DEB)
endif ()
include (CPack)
