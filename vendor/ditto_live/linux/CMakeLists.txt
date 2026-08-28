# WARNING - GENERATED FILE - DO NOT EDIT

# The Flutter tooling requires that developers have CMake 3.10 or later
# installed. You should not increase this version, as doing so will cause
# the plugin to fail to compile for some customers of the plugin.
cmake_minimum_required(VERSION 3.10)

# Project-level configuration.
set(PROJECT_NAME "ditto_live")
project(${PROJECT_NAME} LANGUAGES CXX)

# `CMAKE_SYSTEM_PROCESSOR` is the architecture for the host machine, not the
# target machine. However, since Flutter doesn't support cross-compiling
# between different linux archs (despite the CLI having a flag for it :3 ),
# this is effectively the "target architecture" as well
#
# These strings must match the strings in
# `<monorepo>/sdks/flutter/scripts/publish/upload_binaries_step.dart`
if(CMAKE_SYSTEM_PROCESSOR MATCHES "x86_64|AMD64")
  set(ARCH_NAME "x86_64")
elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64|arm64|ARM64")
  set(ARCH_NAME "aarch64")
else()
  message(FATAL_ERROR "Unsupported architecture: ${CMAKE_SYSTEM_PROCESSOR}")
endif()

set(DITTOFFI_LIB_PATH "${CMAKE_CURRENT_SOURCE_DIR}/libdittoffi.so")
set(DITTOFFI_LIB_URL "https://software.ditto.live/flutter/ditto/5.1.0/linux/${ARCH_NAME}/libdittoffi.so")

# First, we check for the env var and skip downloading if it's set. This is
# required for the library to work in certain restricted environments (e.g. a
# nix build, which has no access to the internet)
if (DEFINED ENV{LIBDITTOFFI_PATH})
  message(STATUS "Using libdittoffi.so from `$$LIBDITTOFFI_PATH`: ${LIBDITTOFFI_PATH}")
  set(DITTOFFI_LIB_PATH "$ENV{LIBDITTOFFI_PATH}")
elseif(NOT EXISTS ${DITTOFFI_LIB_PATH})
  message(STATUS "libdittoffi.so does not exist - downloading")

  file(DOWNLOAD
    ${DITTOFFI_LIB_URL}
    ${DITTOFFI_LIB_PATH}
    SHOW_PROGRESS
    STATUS download_status
    TLS_VERIFY ON
  )

  # Check if download was successful
  list(GET download_status 0 status_code)
  list(GET download_status 1 error_message)

  if(NOT status_code EQUAL 0)
    message(FATAL_ERROR "Failed to download libdittoffi.so: ${error_message}")
  endif()

  # Make the library executable
  file(CHMOD ${DITTOFFI_LIB_PATH}
    PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE
                GROUP_READ GROUP_EXECUTE
                WORLD_READ WORLD_EXECUTE)

else()
  message(STATUS "Using local libdittoffi.so")
endif()

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(ditto_live_bundled_libraries
  # Defined in ../src/CMakeLists.txt.
  # This can be changed to accommodate different builds.
  ${DITTOFFI_LIB_PATH}
  PARENT_SCOPE
)