include(install.cmake)

function(ADD_XC_ARCH_DEFINE)
  # ~~~
  # ADD_XC_ARCH_DEFINE(
  #   FAMILY <family>
  #   PRJRAY_DIR <documentation project dir>
  #   PRJRAY_DB_DIR <documentation project database dir>
  #   ARCH <arch>
  #   PRJRAY_ARCH <prjray_arch>
  #   PROTOTYPE_PART <prototype_part>
  #   YOSYS_SYNTH_SCRIPT <yosys_script>
  #   YOSYS_CONV_SCRIPT <yosys_script>
  #   )
  #
  # FAMILY: The family the architecture is belonging to (e.g. xc7).
  #
  # ARCH: The architecture to add (e.g. artix7).
  #
  # PRJRAY_ARCH: The architecture in PRJRAY that holds all the part data that need to be imported.
  #
  # PROTOTYPE_PART: The PART that is valid for all the different PARTs having the same ARCH.
  set(options)
  set(oneValueArgs
        FAMILY
        ARCH
        PRJRAY_ARCH
        PRJRAY_DIR
        PRJRAY_DB_DIR
        PRJRAY_NAME
        PROTOTYPE_PART
        YOSYS_SYNTH_SCRIPT
        YOSYS_CONV_SCRIPT)
  set(multiValueArgs)
  cmake_parse_arguments(
    ADD_XC_ARCH_DEFINE
    "${options}"
    "${oneValueArgs}"
    "${multiValueArgs}"
    ${ARGN}
  )

  # The default IOSTANDARD and DRIVE to use in fasm2bels
  set(DEFAULT_IOSTANDARD "LVCMOS33")
  set(DEFAULT_DRIVE 12)

  set(FAMILY ${ADD_XC_ARCH_DEFINE_FAMILY})
  set(ARCH ${ADD_XC_ARCH_DEFINE_ARCH})
  if("${ADD_XC_ARCH_DEFINE_PRJRAY_ARCH}" STREQUAL "")
      set(PRJRAY_ARCH "${ARCH}")
  else()
      set(PRJRAY_ARCH "${ADD_XC_ARCH_DEFINE_PRJRAY_ARCH}")
  endif()
  set(PRJRAY_DIR ${ADD_XC_ARCH_DEFINE_PRJRAY_DIR})
  set(PRJRAY_DB_DIR ${ADD_XC_ARCH_DEFINE_PRJRAY_DB_DIR})
  set(PRJRAY_NAME ${ADD_XC_ARCH_DEFINE_PRJRAY_NAME})
  set(PROTOTYPE_PART ${ADD_XC_ARCH_DEFINE_PROTOTYPE_PART})
  set(YOSYS_SYNTH_SCRIPT ${ADD_XC_ARCH_DEFINE_YOSYS_SYNTH_SCRIPT})
  set(YOSYS_CONV_SCRIPT ${ADD_XC_ARCH_DEFINE_YOSYS_CONV_SCRIPT})
  set(YOSYS_TECHMAP ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/techmap)
  set(VPR_ARCH_ARGS "\
      --router_heap bucket \
      --clock_modeling route \
      --place_delay_model delta_override \
      --router_lookahead connection_box_map \
      --quick_check_route on \
      --strict_checks off \
      --allow_dangling_combinational_nodes on \
      --disable_errors check_unbuffered_edges:check_route \
      --congested_routing_iteration_threshold 0.8 \
      --incremental_reroute_delay_ripup off \
      --base_cost_type delay_normalized_length_bounded \
      --bb_factor 10 \
      --initial_pres_fac 4.0 \
      --check_rr_graph off \
      --suppress_warnings \${OUT_NOISY_WARNINGS},sum_pin_class:check_unbuffered_edges:load_rr_indexed_data_T_values:check_rr_node:trans_per_R:check_route"
      )

  set(YOSYS_CELLS_SIM ${YOSYS_DATADIR}/xilinx/cells_sim.v) 
  set(VPR_CELLS_SIM ${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}/techmap/cells_sim.v)

  get_file_target(YOSYS_CELLS_SIM_TARGET ${YOSYS_CELLS_SIM})
  if (NOT TARGET ${YOSYS_CELLS_SIM_TARGET})
    add_file_target(FILE ${YOSYS_CELLS_SIM} ABSOLUTE)
  endif ()

  get_file_target(VPR_CELLS_SIM_TARGET ${VPR_CELLS_SIM})
  if (NOT TARGET ${VPR_CELLS_SIM_TARGET})
      add_file_target(FILE ${VPR_CELLS_SIM} ABSOLUTE)
  endif ()

  define_arch(
    ARCH ${ARCH}
    FAMILY ${FAMILY}
    DOC_PRJ ${PRJRAY_DIR}
    DOC_PRJ_DB ${PRJRAY_DB_DIR}
    DOC_PRJ_NAME ${PRJRAY_NAME}
    PROTOTYPE_PART ${PROTOTYPE_PART}
    YOSYS_SYNTH_SCRIPT ${YOSYS_SYNTH_SCRIPT}
    YOSYS_TECHMAP ${YOSYS_TECHMAP}
    YOSYS_CONV_SCRIPT ${YOSYS_CONV_SCRIPT}
    DEVICE_FULL_TEMPLATE \${DEVICE}-\${PACKAGE}
    CELLS_SIM ${YOSYS_CELLS_SIM} ${VPR_CELLS_SIM}
    VPR_ARCH_ARGS ${VPR_ARCH_ARGS}
    RR_PATCH_TOOL
      ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/prjxray_routing_import.py
    RR_PATCH_CMD "${CMAKE_COMMAND} -E env \
    PYTHONPATH=${PRJRAY_DIR}:${symbiflow-arch-defs_SOURCE_DIR}/utils:${symbiflow-arch-defs_BINARY_DIR}/utils \
        \${PYTHON3} \${RR_PATCH_TOOL} \
        --db_root ${PRJRAY_DB_DIR}/${PRJRAY_ARCH} \
        --part \${PART} \
        --read_rr_graph \${OUT_RRXML_VIRT} \
        --write_rr_graph \${OUT_RRXML_REAL} \
        --write_rr_node_map \${OUT_RRXML_REAL}.node_map.pickle \
        --vpr_capnp_schema_dir ${VPR_CAPNP_SCHEMA_DIR}
        "
    PLACE_TOOL
      ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/prjxray_create_ioplace.py
    PLACE_TOOL_CMD "${CMAKE_COMMAND} -E env \
    PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/utils \
    \${PYTHON3} \${PLACE_TOOL} \
        --map \${PINMAP} \
        --blif \${OUT_EBLIF} \
        --pcf \${INPUT_IO_FILE} \
        --net \${OUT_NET}"
    PLACE_CONSTR_TOOL
      ${symbiflow-arch-defs_SOURCE_DIR}/xc/common/utils/prjxray_create_place_constraints.py
    PLACE_CONSTR_TOOL_CMD "${CMAKE_COMMAND} -E env \
    PYTHONPATH=${symbiflow-arch-defs_SOURCE_DIR}/utils \
    \${PYTHON3} \${PLACE_CONSTR_TOOL} \
        --net \${OUT_NET} \
        --arch \${DEVICE_MERGED_FILE_LOCATION} \
        --blif \${OUT_EBLIF} \
        --input /dev/stdin \
        --output /dev/stdout \
        \${PLACE_CONSTR_TOOL_EXTRA_ARGS}"
    BITSTREAM_EXTENSION frames
    BIN_EXTENSION bit
    FASM_TO_BIT ${PRJRAY_DIR}/utils/fasm2frames.py
    FASM_TO_BIT_CMD "${CMAKE_COMMAND} -E env \
    PYTHONPATH=${symbiflow-arch-defs_BINARY_DIR}/env/conda/lib/python3.7/site-packages:${PRJRAY_DIR}:${PRJRAY_DIR}/third_party/fasm \
    \${PYTHON3} \${FASM_TO_BIT} \
        --db-root ${PRJRAY_DB_DIR}/${PRJRAY_ARCH} \
        --sparse \
        --emit_pudc_b_pullup \
        \${FASM_TO_BIT_EXTRA_ARGS} \
    \${OUT_FASM} \${OUT_BITSTREAM}"
    BIT_TO_BIN xc7frames2bit
    BIT_TO_BIN_CMD "xc7frames2bit \
        --frm_file \${OUT_BITSTREAM} \
        --output_file \${OUT_BIN} \
        \${BIT_TO_BIN_EXTRA_ARGS}"
    BIT_TO_V bitread
    BIT_TO_V_CMD "${CMAKE_COMMAND} -E env \
    PYTHONPATH=${symbiflow-arch-defs_BINARY_DIR}/env/conda/lib/python3.7/site-packages:${PRJRAY_DIR}:${PRJRAY_DIR}/third_party/fasm:${symbiflow-arch-defs_SOURCE_DIR}/xc/${FAMILY}:${symbiflow-arch-defs_SOURCE_DIR}/utils \
        \${PYTHON3} -mfasm2bels \
        \${BIT_TO_V_EXTRA_ARGS} \
        --db_root ${PRJRAY_DB_DIR}/${PRJRAY_ARCH} \
        --rr_graph \${OUT_RRBIN_REAL_LOCATION} \
        --vpr_capnp_schema_dir ${VPR_CAPNP_SCHEMA_DIR} \
        --route \${OUT_ROUTE} \
        --bitread $<TARGET_FILE:bitread> \
        --bit_file \${OUT_BIN} \
        --fasm_file \${OUT_BIN}.fasm \
        --iostandard ${DEFAULT_IOSTANDARD} \
        --drive ${DEFAULT_DRIVE} \
        --pcf \${INPUT_IO_FILE} \
        --eblif \${OUT_EBLIF} \
        --top \${TOP} \
        \${OUT_BIT_VERILOG} \${OUT_BIT_VERILOG}.tcl"

    NO_BIT_TIME
    USE_FASM
    RR_GRAPH_EXT ".bin"
    ROUTE_CHAN_WIDTH 500
  )

  set_target_properties(${ARCH} PROPERTIES PRJRAY_ARCH ${PRJRAY_ARCH})
  add_custom_target(all_${ARCH}_diff_fasm)
  define_xc_toolchain_target(
      ARCH ${ARCH}
      PRJRAY_NAME ${PRJRAY_NAME}
      ROUTE_CHAN_WIDTH 500
      VPR_ARCH_ARGS ${VPR_ARCH_ARGS}
      BIT_TO_BIN xc7frames2bit
      CONV_SCRIPT ${YOSYS_CONV_SCRIPT}
      SYNTH_SCRIPT ${YOSYS_SYNTH_SCRIPT})

endfunction()
