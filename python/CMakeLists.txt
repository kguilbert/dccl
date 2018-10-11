find_program(PYTHON "python")

if (PYTHON)
    protobuf_generate_python(PROTO_PY ${dccl_INC_DIR}/dccl/option_extensions.proto)

    add_custom_command(OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/dccl/option_extensions_pb2.py
                       COMMAND ${CMAKE_COMMAND} -E copy ${PROTO_PY} ${CMAKE_CURRENT_SOURCE_DIR}/dccl/
                       DEPENDS ${PROTO_PY})
    
    add_custom_target(pydccl ALL DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/dccl/option_extensions_pb2.py)
endif()
