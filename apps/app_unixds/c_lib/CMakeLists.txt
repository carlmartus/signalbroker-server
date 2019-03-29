# Core System Unix Domain Socket sample
# Copyright Volvo Car Corporation 2017

cmake_minimum_required(VERSION "3.0")

project(csunixds C)

# Configuration
# =============

# Get git tag version
execute_process(
	COMMAND git describe "--tags" "--dirty"
	WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
	OUTPUT_STRIP_TRAILING_WHITESPACE
	OUTPUT_VARIABLE GIT_VERSION)

option(CS_FAKE_IO "Use fake IO" OFF)
option(CS_DEBUG "Debug information" OFF)
set(CS_PROTOCOL_VERSION "4" CACHE STRING "Protocol revision")
set(CS_SOCK_DIR "/tmp/signalserver/" CACHE FILEPATH "Unix domain socket dir")
set(CS_SOCK_NAME "cs-unix" CACHE FILEPATH "Unix domain socket name")
set(CS_VERSION_STR ${GIT_VERSION})
set(CS_LIBRARY_TYPE "STATIC" CACHE STRING "Library type (STATIC/SHARED)")
set(CMAKE_C_FLAGS "-std=gnu99" CACHE STRING "" FORCE)

configure_file(
	"${PROJECT_SOURCE_DIR}/csunixds.in.h"
	"${PROJECT_BINARY_DIR}/csunixds.h")

include_directories(${SAMPLE_NAME} PUBLIC ${PROJECT_BINARY_DIR})

# Static library
# ==============
add_library(${CMAKE_PROJECT_NAME} ${CS_LIBRARY_TYPE} csunixds.c)

# Put static lib in /usr/local/lib
install(TARGETS ${CMAKE_PROJECT_NAME}
	ARCHIVE DESTINATION lib
	LIBRARY DESTINATION lib
	DESTINATION include) # Put header in /usr/local/include

# Executable sample
# =================
set(SAMPLE_NAME "sample")
add_executable(${SAMPLE_NAME} sample.c)
target_link_libraries(${SAMPLE_NAME} ${CMAKE_PROJECT_NAME})

# Test unit
# =========
set(TESTUNIT "testunit")
add_executable(${TESTUNIT} testunit.c)
target_link_libraries(${TESTUNIT} ${CMAKE_PROJECT_NAME})

# Executable benchmank (BenchB)
# =============================
set(BENCHB_NAME "benchb")
add_executable(${BENCHB_NAME} benchb.c)
target_link_libraries(${BENCHB_NAME} ${CMAKE_PROJECT_NAME})

# Power train debug application
# =============================
add_executable(powertrain powertrain.c)
target_link_libraries(powertrain ${CMAKE_PROJECT_NAME})

# Installations
# =============
set (CPACK_PACKAGE_VERSION ${GIT_VERSION})
set(CPACK_GENERATOR TGZ)
include (CPack)
