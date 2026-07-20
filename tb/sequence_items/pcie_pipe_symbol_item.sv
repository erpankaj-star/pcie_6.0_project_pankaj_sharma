




`ifndef PCIE_PIPE_SYMBOL_ITEM_SV
`define PCIE_PIPE_SYMBOL_ITEM_SV

class pcie_pipe_symbol_item extends uvm_sequence_item;
//  `uvm_object_utils(pcie_pipe_symbol_item)

  //--------------------------------------------------------------------------
  // Existing PIPE symbol fields
  // pcie_speed_e renamed to pcie_link_speed_e (Step 1 + Step 4)
  //--------------------------------------------------------------------------
  rand pcie_pipe_symbol_e  symbol_type;
  rand pcie_link_speed_e   speed;
  rand pcie_link_width_e   width;
  rand bit [4:0]           lane_num;
  rand bit [31:0]          data;
  rand bit [3:0]           datak;
  rand bit                 start_block;
  rand bit [1:0]           sync_header;
  rand bit                 elec_idle;
  rand bit                 polarity_inverted;
  rand bit                 lane_reversal;
  rand bit                 deskew_marker;
  rand bit                 retimer_marker;
  rand bit [1:0]           pam4_symbol;
  rand bit                 precoding_enable;
  rand bit                 scrambling_enable;

  //--------------------------------------------------------------------------
  // error_kind: renamed from pcie_error_inject_e to pcie_error_kind_e (Step 1)
  //--------------------------------------------------------------------------
  rand pcie_error_kind_e   error_kind;

  //--------------------------------------------------------------------------
  // Step 4 addition: force bit consumed by send_pipe_symbol() in base seq
  //--------------------------------------------------------------------------
  bit                      force_bad_flit_crc;

  //--------------------------------------------------------------------------
  // Constraints
  //--------------------------------------------------------------------------
  constraint c_lane        { lane_num < PCIE_MAX_LANES; }
  constraint c_error_default { soft error_kind == ERR_NONE; }

  `uvm_object_utils_begin(pcie_pipe_symbol_item)
    `uvm_field_enum(pcie_pipe_symbol_e,  symbol_type,        UVM_ALL_ON)
    `uvm_field_enum(pcie_link_speed_e,   speed,              UVM_ALL_ON)
    `uvm_field_enum(pcie_link_width_e,   width,              UVM_ALL_ON)
    `uvm_field_int(lane_num,                                  UVM_ALL_ON)
    `uvm_field_int(data,                                      UVM_ALL_ON)
    `uvm_field_int(datak,                                     UVM_ALL_ON)
    `uvm_field_int(start_block,                               UVM_ALL_ON)
    `uvm_field_int(sync_header,                               UVM_ALL_ON)
    `uvm_field_int(elec_idle,                                 UVM_ALL_ON)
    `uvm_field_int(polarity_inverted,                         UVM_ALL_ON)
    `uvm_field_int(lane_reversal,                             UVM_ALL_ON)
    `uvm_field_int(deskew_marker,                             UVM_ALL_ON)
    `uvm_field_int(retimer_marker,                            UVM_ALL_ON)
    `uvm_field_int(pam4_symbol,                               UVM_ALL_ON)
    `uvm_field_int(precoding_enable,                          UVM_ALL_ON)
    `uvm_field_int(scrambling_enable,                         UVM_ALL_ON)
    `uvm_field_enum(pcie_error_kind_e,   error_kind,          UVM_ALL_ON)
    `uvm_field_int(force_bad_flit_crc,                        UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "pcie_pipe_symbol_item");
    super.new(name);
    error_kind = ERR_NONE;
  endfunction
endclass : pcie_pipe_symbol_item

`endif














































