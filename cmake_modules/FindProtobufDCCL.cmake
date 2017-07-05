# Locate and configure the Google Protocol Buffers library.
# Defines the following variables:
#
#   PROTOBUF_FOUND - Found the Google Protocol Buffers library
#   PROTOBUF_INCLUDE_DIRS - Include directories for Google Protocol Buffers
#   PROTOBUF_LIBRARIES - The protobuf library
#
# The following cache variables are also defined:
#   PROTOBUF_LIBRARY - The protobuf library
#   PROTOBUF_PROTOC_LIBRARY   - The protoc library
#   PROTOBUF_INCLUDE_DIR - The include directory for protocol buffers
#   PROTOBUF_PROTOC_EXECUTABLE - The protoc compiler
#
#  ====================================================================
#  Example:
#
#   find_package(Protobuf REQUIRED)
#   include_directories(${PROTOBUF_INCLUDE_DIRS})
#
#   include_directories(${CMAKE_CURRENT_BINARY_DIR})
#   PROTOBUF_GENERATE_CPP(PROTO_SRCS PROTO_HDRS foo.proto)
#   add_executable(bar bar.cc ${PROTO_SRCS} ${PROTO_HDRS})
#   target_link_libraries(bar ${PROTOBUF_LIBRARY})
#
# NOTE: You may need to link against pthreads, depending
# on the platform.
#  ====================================================================
#
# PROTOBUF_GENERATE_CPP (public function)
#   SRCS = Variable to define with autogenerated
#          source files
#   HDRS = Variable to define with autogenerated
#          header files
#   ARGN = proto files
#
#  ====================================================================


#=============================================================================
# Copyright 2009 Kitware, Inc.
# Copyright 2009 Philip Lowman <philip@yhbt.com>
# Copyright 2008 Esben Mose Hansen, Ange Optimization ApS
# Copyright 2010 Toby Schneider tes@mit.edu
#
# Distributed under the OSI-approved BSD License (the "License");
# see accompanying file Copyright.txt for details.
#
# This software is distributed WITHOUT ANY WARRANTY; without even the
# implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
# See the License for more information.
#=============================================================================
# (To distributed this file outside of CMake, substitute the full
#  License text for the above reference.)

function(PROTOBUF_GENERATE_CPP SRCS HDRS)
  if(enable_units)
    protobuf_generate_cpp_internal("True" PROTO_SRCS PROTO_HDRS ${ARGN})
  else()
    protobuf_generate_cpp_internal("False" PROTO_SRCS PROTO_HDRS ${ARGN})
  endif()
  set(${SRCS} ${PROTO_SRCS} PARENT_SCOPE)
  set(${HDRS} ${PROTO_HDRS} PARENT_SCOPE)
endfunction()

function(PROTOBUF_GENERATE_CPP_NO_DCCL SRCS HDRS)
  protobuf_generate_cpp_internal("False" PROTO_SRCS PROTO_HDRS ${ARGN})
  set(${SRCS} ${PROTO_SRCS} PARENT_SCOPE)
  set(${HDRS} ${PROTO_HDRS} PARENT_SCOPE)
endfunction()

function(PROTOBUF_GENERATE_CPP_INTERNAL USE_DCCL SRCS HDRS)
  if(NOT ARGN)
    message(SEND_ERROR "Error: PROTOBUF_GENERATE_CPP() called without any proto files")
    return()
  endif(NOT ARGN)

  set(${SRCS})
  set(${HDRS})
  foreach(FIL ${ARGN})
    # /home/toby/dccl/src/core/proto/foo.proto
    get_filename_component(ABS_FIL ${FIL} ABSOLUTE)
    # foo
    get_filename_component(FIL_WE ${FIL} NAME_WE)
    # core/proto/foo.proto
    file(RELATIVE_PATH REL_FIL ${dccl_SRC_DIR} ${ABS_FIL})
    # /home/toby/dccl/include/dccl/core/proto/foo.proto
    set(ABS_BUILT_FIL "${dccl_INC_DIR}/dccl/${REL_FIL}")
    # /home/toby/dccl/include/dccl/core/proto
    get_filename_component(FIL_PATH ${ABS_BUILT_FIL} PATH)

    # message(STATUS ${ABS_FIL})
    # message(STATUS ${FIL_WE})
    # message(STATUS ${REL_FIL})
    # message(STATUS ${FIL_PATH})

    include_directories(${FIL_PATH})

    list(APPEND ${SRCS} "${FIL_PATH}/${FIL_WE}.pb.cc")
    list(APPEND ${HDRS} "${FIL_PATH}/${FIL_WE}.pb.h")

    if(USE_DCCL)
      set(DCCL_PROTOC_ARGS --dccl_out ${dccl_INC_DIR} --plugin ${dccl_BIN_DIR}/protoc-gen-dccl)
    endif()

    add_custom_command(
      OUTPUT "${FIL_PATH}/${FIL_WE}.pb.cc"
             "${FIL_PATH}/${FIL_WE}.pb.h"
      COMMAND  ${PROTOBUF_PROTOC_EXECUTABLE}
      ARGS --cpp_out ${dccl_INC_DIR} --proto_path ${dccl_INC_DIR} ${dccl_INC_DIR}/dccl/${REL_FIL} -I ${PROTOBUF_INCLUDE_DIRS} -I ${dccl_INC_DIR} ${DCCL_PROTOC_ARGS}
      DEPENDS ${ABS_FIL}
      COMMENT "Running C++ protocol buffer compiler on ${FIL}"
      VERBATIM )
  endforeach()

  # copy headers for generated headers
  file(GLOB_RECURSE INCLUDE_FILES RELATIVE ${dccl_BUILD_DIR}/proto build/proto/*.h)
  foreach(I ${INCLUDE_FILES})
    configure_file(${dccl_BUILD_DIR}/proto/${I} ${dccl_INC_DIR}/${I} COPYONLY)
  endforeach()
  
  set_source_files_properties(${${SRCS}} ${${HDRS}} PROPERTIES GENERATED TRUE)
  set(${SRCS} ${${SRCS}} PARENT_SCOPE)
  set(${HDRS} ${${HDRS}} PARENT_SCOPE)
endfunction()


find_path(PROTOBUF_INCLUDE_DIR google/protobuf/service.h)

# Support preference of static libs by adjusting CMAKE_FIND_LIBRARY_SUFFIXES
if( BUILD_SHARED_LIBS )
  set( _protobuf_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_FIND_LIBRARY_SUFFIXES})
  if(WIN32)
    set(CMAKE_FIND_LIBRARY_SUFFIXES .lib .a ${CMAKE_FIND_LIBRARY_SUFFIXES})
  else()
    set(CMAKE_FIND_LIBRARY_SUFFIXES .a )
  endif()
endif()

# Google's provided vcproj files generate libraries with a "lib"
# prefix on Windows
if(WIN32)
    set(PROTOBUF_ORIG_FIND_LIBRARY_PREFIXES "${CMAKE_FIND_LIBRARY_PREFIXES}")
    set(CMAKE_FIND_LIBRARY_PREFIXES "lib" "")
endif()

find_library(PROTOBUF_LIBRARY NAMES protobuf
  DOC "The Google Protocol Buffers Library"
)
find_library(PROTOBUF_PROTOC_LIBRARY NAMES protoc
             DOC "The Google Protocol Buffers Compiler Library"
)
find_program(PROTOBUF_PROTOC_EXECUTABLE NAMES protoc
             DOC "The Google Protocol Buffers Compiler"
)

mark_as_advanced(PROTOBUF_INCLUDE_DIR
                 PROTOBUF_LIBRARY
                 PROTOBUF_PROTOC_LIBRARY
                 PROTOBUF_PROTOC_EXECUTABLE)

# Restore original find library prefixes
if(WIN32)
    set(CMAKE_FIND_LIBRARY_PREFIXES "${PROTOBUF_ORIG_FIND_LIBRARY_PREFIXES}")
endif()

# Restore the original find library ordering
if( Protobuf_USE_STATIC_LIBS )
  set(CMAKE_FIND_LIBRARY_SUFFIXES ${_protobuf_ORIG_CMAKE_FIND_LIBRARY_SUFFIXES})
endif()

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(ProtobufDCCL DEFAULT_MSG
    PROTOBUF_LIBRARY PROTOBUF_INCLUDE_DIR PROTOBUF_PROTOC_EXECUTABLE)

if(PROTOBUFDCCL_FOUND)
    set(PROTOBUF_INCLUDE_DIRS ${PROTOBUF_INCLUDE_DIR})
    set(PROTOBUF_LIBRARIES    ${PROTOBUF_LIBRARY})

    execute_process(COMMAND ${PROTOBUF_PROTOC_EXECUTABLE} --version
      OUTPUT_VARIABLE PROTOC_VERSION_STRING)
    string(REPLACE "libprotoc "
      "" PROTOC_VERSION ${PROTOC_VERSION_STRING})


endif()

