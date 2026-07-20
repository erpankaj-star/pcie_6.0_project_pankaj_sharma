`timescale 1ns/1ps
`ifndef PCIE_TL_IF_SV
`define PCIE_TL_IF_SV

interface pcie_tl_if (input logic clk, input logic reset_n);
  import pcie_gen5_6_types_pkg::*;

  logic                 tl_valid;
  logic                 tl_ready;
  pcie_tlp_type_e       tl_type;
  logic [15:0]          requester_id;
  logic [15:0]          completer_id;
  logic [9:0]           tag;
  logic [63:0]          addr;
  logic [9:0]           length_dw;
  logic [3:0]           first_be;
  logic [3:0]           last_be;
  logic [2:0]           traffic_class;
  logic [2:0]           attr;
  logic                 poisoned;
  logic                 ecrc_present;
  logic                 ide_present;
  logic [19:0]          pasid;
  logic [7:0]           ohc_vector;
  logic [31:0]          data_dw[$];
  pcie_credit_avail_s   credit_avail;
  logic                 completion_timeout;
  logic                 malformed_tlp;
  logic                 cfg_side_effect;

  modport dut (
    input  clk, reset_n, tl_ready, credit_avail,
    output tl_valid, tl_type, requester_id, completer_id, tag, addr,
    output length_dw, first_be, last_be, traffic_class, attr, poisoned,
    output ecrc_present, ide_present, pasid, ohc_vector,
    output completion_timeout, malformed_tlp, cfg_side_effect
  );

  modport tb (
    input  clk, reset_n,
    input  tl_valid, tl_type, requester_id, completer_id, tag, addr,
    input  length_dw, first_be, last_be, traffic_class, attr, poisoned,
    input  ecrc_present, ide_present, pasid, ohc_vector,
    input  completion_timeout, malformed_tlp, cfg_side_effect,
    output tl_ready, credit_avail
  );

  modport monitor (input clk, reset_n, tl_valid, tl_ready, tl_type, requester_id,
                   completer_id, tag, addr, length_dw, first_be, last_be,
                   traffic_class, attr, poisoned, ecrc_present, ide_present,
                   pasid, ohc_vector, credit_avail, completion_timeout,
                   malformed_tlp, cfg_side_effect);

endinterface : pcie_tl_if

`endif

