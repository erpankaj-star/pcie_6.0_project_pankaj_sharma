`ifndef PCIE_GEN5_6_CFG_SV
`define PCIE_GEN5_6_CFG_SV

class pcie_gen5_6_cfg extends uvm_object;
  rand pcie_device_mode_e dut_mode;
  rand pcie_speed_e       max_speed;
  rand pcie_link_width_e  max_width;
  rand bit                enable_gen5;
  rand bit                enable_gen6;
  rand bit                enable_flit_mode;
  rand bit                enable_scaled_fc;
  rand bit                enable_ide;
  rand bit                enable_doe;
  rand bit                enable_aer;
  rand bit                enable_dpc;
  rand bit                enable_lane_margining;
  rand bit                enable_retimer_hooks;
  rand bit                lane_reversal_enable;
  rand bit                polarity_inversion_enable;
  rand bit                deskew_enable;
  rand bit                enable_scrambling;
  rand bit                enable_precoding;
  rand int unsigned       completion_timeout_cycles;
  rand int unsigned       replay_timeout_cycles;
  rand int unsigned       fc_init_timeout_cycles;
  rand int unsigned       ltssm_timeout_cycles;
  rand int unsigned       active_lanes;
  rand pcie_error_inject_e error_kind;
  rand int unsigned flit_burst_count_min;
  rand int unsigned flit_burst_count_max;
  rand bit err_inj_enable;
  constraint c_mode      { dut_mode inside {PCIE_MODE_RC, PCIE_MODE_EP}; }
  constraint c_speed     { max_speed inside {PCIE_GEN1_2P5, PCIE_GEN2_5P0, PCIE_GEN3_8P0,
                                             PCIE_GEN4_16P0, PCIE_GEN5_32P0, PCIE_GEN6_64P0}; }
  constraint c_width     { max_width inside {PCIE_X1, PCIE_X2, PCIE_X4, PCIE_X8, PCIE_X16}; }
  constraint c_gen       { if (max_speed == PCIE_GEN6_64P0) enable_gen6 == 1; }
  constraint c_lanes     { active_lanes inside {1, 2, 4, 8, 16}; active_lanes <= max_width; }

  `uvm_object_utils_begin(pcie_gen5_6_cfg)
    `uvm_field_enum(pcie_device_mode_e, dut_mode, UVM_ALL_ON)
    `uvm_field_enum(pcie_speed_e, max_speed, UVM_ALL_ON)
    `uvm_field_enum(pcie_link_width_e, max_width, UVM_ALL_ON)
    `uvm_field_int(enable_gen5, UVM_ALL_ON)
    `uvm_field_int(enable_gen6, UVM_ALL_ON)
    `uvm_field_int(enable_flit_mode, UVM_ALL_ON)
    `uvm_field_int(enable_scaled_fc, UVM_ALL_ON)
    `uvm_field_int(enable_ide, UVM_ALL_ON)
    `uvm_field_int(enable_doe, UVM_ALL_ON)
    `uvm_field_int(enable_aer, UVM_ALL_ON)
    `uvm_field_int(enable_dpc, UVM_ALL_ON)
    `uvm_field_int(enable_lane_margining, UVM_ALL_ON)
    `uvm_field_int(enable_retimer_hooks, UVM_ALL_ON)
    `uvm_field_int(lane_reversal_enable, UVM_ALL_ON)
    `uvm_field_int(polarity_inversion_enable, UVM_ALL_ON)
    `uvm_field_int(deskew_enable, UVM_ALL_ON)
    `uvm_field_int(enable_scrambling, UVM_ALL_ON)
    `uvm_field_int(enable_precoding, UVM_ALL_ON)
    `uvm_field_int(completion_timeout_cycles, UVM_ALL_ON)
    `uvm_field_int(replay_timeout_cycles, UVM_ALL_ON)
    `uvm_field_int(fc_init_timeout_cycles, UVM_ALL_ON)
    `uvm_field_int(ltssm_timeout_cycles, UVM_ALL_ON)
    `uvm_field_int(active_lanes, UVM_ALL_ON)
    `uvm_field_enum(pcie_error_inject_e, error_kind, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "pcie_gen5_6_cfg");
    super.new(name);
    dut_mode                  = PCIE_MODE_RC;
    max_speed                 = PCIE_GEN6_64P0;
    max_width                 = PCIE_X16;
    enable_gen5               = 1'b1;
    enable_gen6               = 1'b1;
    enable_flit_mode          = 1'b1;
    enable_scaled_fc          = 1'b1;
    enable_ide                = 1'b1;
    enable_doe                = 1'b1;
    enable_aer                = 1'b1;
    enable_dpc                = 1'b1;
    enable_lane_margining     = 1'b1;
    enable_retimer_hooks      = 1'b1;
    lane_reversal_enable      = 1'b0;
    polarity_inversion_enable = 1'b0;
    deskew_enable             = 1'b1;
    enable_scrambling         = 1'b1;
    enable_precoding          = 1'b1;
    completion_timeout_cycles = 10000;
    replay_timeout_cycles     = 2000;
    fc_init_timeout_cycles    = 2000;
    ltssm_timeout_cycles      = 5000;
    active_lanes              = 16;
    error_kind                = ERR_NONE;
    flit_burst_count_min = 4;
    flit_burst_count_max = 16;
    err_inj_enable = 0;
  endfunction

  function pcie_device_mode_e tb_link_partner_mode();
    return (dut_mode == PCIE_MODE_RC) ? PCIE_MODE_EP : PCIE_MODE_RC;
  endfunction
endclass : pcie_gen5_6_cfg

`endif

