`timescale 1ns/1ps
`ifndef PCIE_DL_IF_SV
`define PCIE_DL_IF_SV

interface pcie_dl_if (input logic clk, input logic reset_n);
  import pcie_gen5_6_types_pkg::*;

  logic           dl_valid;
  logic           dl_ready;
  pcie_dlp_type_e dlp_type;
  pcie_dl_state_e dl_state;
  logic [11:0]    tlp_seq_num;
  logic [9:0]     flit_seq_num;
  logic [9:0]     ack_nak_seq_num;
  logic           ack;
  logic           nak;
  logic           replay_req;
  logic           replay_timer_expired;
  logic           lcrc_error;
  logic           dllp_crc_error;
  logic           dl_feature_exchange_done;
  logic           fc_init_done;
  logic [11:0]    ph_credit;
  logic [11:0]    pd_credit;
  logic [11:0]    nph_credit;
  logic [11:0]    npd_credit;
  logic [11:0]    cplh_credit;
  logic [11:0]    cpld_credit;
  logic           optimized_update_fc;
  logic           scaled_fc_enable;
  logic           link_down;
  logic           error_to_tl;

  modport dut (
    input  clk, reset_n, dl_ready,
    output dl_valid, dlp_type, dl_state, tlp_seq_num, flit_seq_num,
    output ack_nak_seq_num, ack, nak, replay_req, replay_timer_expired,
    output lcrc_error, dllp_crc_error, dl_feature_exchange_done,
    output fc_init_done, ph_credit, pd_credit, nph_credit, npd_credit,
    output cplh_credit, cpld_credit, optimized_update_fc,
    output scaled_fc_enable, link_down, error_to_tl
  );

  modport tb (
    input  clk, reset_n,
    input  dl_valid, dlp_type, dl_state, tlp_seq_num, flit_seq_num,
    input  ack_nak_seq_num, ack, nak, replay_req, replay_timer_expired,
    input  lcrc_error, dllp_crc_error, dl_feature_exchange_done,
    input  fc_init_done, ph_credit, pd_credit, nph_credit, npd_credit,
    input  cplh_credit, cpld_credit, optimized_update_fc,
    input  scaled_fc_enable, link_down, error_to_tl,
    output dl_ready
  );

  modport monitor (input clk, reset_n, dl_valid, dl_ready, dlp_type, dl_state,
                   tlp_seq_num, flit_seq_num, ack_nak_seq_num, ack, nak,
                   replay_req, replay_timer_expired, lcrc_error,
                   dllp_crc_error, dl_feature_exchange_done, fc_init_done,
                   ph_credit, pd_credit, nph_credit, npd_credit,
                   cplh_credit, cpld_credit, optimized_update_fc,
                   scaled_fc_enable, link_down, error_to_tl);

endinterface : pcie_dl_if

`endif

