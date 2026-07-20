`ifndef PCIE_CFG_ITEM_SV
`define PCIE_CFG_ITEM_SV

class pcie_cfg_item extends uvm_sequence_item;
  rand bit        is_write;
  rand bit [7:0]  bus;
  rand bit [4:0]  device;
  rand bit [2:0]  function_num;
  rand bit [11:0] offset;
  rand bit [31:0] data;
  rand bit [3:0]  byte_en;
  rand bit        expect_ur;
  rand bit        expect_ca;
  rand bit        aer_side_effect;
  rand bit        dpc_side_effect;
  rand bit        ide_cap_access;
  rand bit        doe_access;
  rand bit        flit_log_access;
  rand bit        lane_margin_access;

  constraint c_dw_aligned { offset[1:0] == 2'b00; }
  constraint c_be         { byte_en != 4'h0; }

  `uvm_object_utils_begin(pcie_cfg_item)
    `uvm_field_int(is_write, UVM_ALL_ON)
    `uvm_field_int(bus, UVM_ALL_ON)
    `uvm_field_int(device, UVM_ALL_ON)
    `uvm_field_int(function_num, UVM_ALL_ON)
    `uvm_field_int(offset, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(byte_en, UVM_ALL_ON)
    `uvm_field_int(expect_ur, UVM_ALL_ON)
    `uvm_field_int(expect_ca, UVM_ALL_ON)
    `uvm_field_int(aer_side_effect, UVM_ALL_ON)
    `uvm_field_int(dpc_side_effect, UVM_ALL_ON)
    `uvm_field_int(ide_cap_access, UVM_ALL_ON)
    `uvm_field_int(doe_access, UVM_ALL_ON)
    `uvm_field_int(flit_log_access, UVM_ALL_ON)
    `uvm_field_int(lane_margin_access, UVM_ALL_ON)
  `uvm_object_utils_end

  function new(string name = "pcie_cfg_item");
    super.new(name);
  endfunction
endclass : pcie_cfg_item

`endif

