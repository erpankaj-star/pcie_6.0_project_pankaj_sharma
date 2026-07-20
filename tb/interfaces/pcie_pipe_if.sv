`timescale 1ns/1ps
`ifndef PCIE_PIPE_IF_SV
`define PCIE_PIPE_IF_SV

interface pcie_pipe_if #(
  parameter int LANES  = pcie_gen5_6_types_pkg::PCIE_MAX_LANES,
  parameter int DATA_W = pcie_gen5_6_types_pkg::PCIE_PIPE_DATA_W
) (
  input logic pclk,
  input logic reset_n
);
  import pcie_gen5_6_types_pkg::*;

  // Controller-to-PHY PIPE-style signals.
  logic [LANES-1:0][DATA_W-1:0] tx_data;
  logic [LANES-1:0][DATA_W/8-1:0] tx_datak;
  logic [LANES-1:0] tx_valid;
  logic [LANES-1:0] tx_start_block;
  logic [LANES-1:0][1:0] tx_sync_header;
  logic [LANES-1:0] tx_elec_idle;
  logic [LANES-1:0] tx_detect_rx_loopback;
  logic [LANES-1:0] tx_compliance;
  logic [LANES-1:0][1:0] tx_margin;
  logic [LANES-1:0][1:0] tx_deemph;
  logic [LANES-1:0] tx_polarity;
  logic [2:0] power_down;
  logic [3:0] rate;
  logic [4:0] width;
  logic phy_mode_flit;
  logic tx_ones_zeroes;      // 1b/1b/PAM4 abstraction toggle-pattern hook.
  logic precoding_enable;
  logic scrambling_enable;
  logic pipe_stall;

  // PHY-to-controller PIPE-style signals.
  logic [LANES-1:0][DATA_W-1:0] rx_data;
  logic [LANES-1:0][DATA_W/8-1:0] rx_datak;
  logic [LANES-1:0] rx_valid;
  logic [LANES-1:0] rx_start_block;
  logic [LANES-1:0][1:0] rx_sync_header;
  logic [LANES-1:0] rx_elec_idle;
  logic [LANES-1:0][2:0] rx_status;
  logic [LANES-1:0] rx_polarity_inverted;
  logic [LANES-1:0] rx_block_align;
  logic [LANES-1:0] rx_symbol_lock;
  logic [LANES-1:0] rx_lane_aligned;
  logic [LANES-1:0][5:0] rx_margin_status;
  logic [LANES-1:0][1:0] pam4_symbol;  // abstract Gray-coded PAM4 symbol value.
  logic phy_status;
  logic rate_change_ack;
  logic eq_phase_done;
  logic lane_reversal_detected;
  logic deskew_done;
  logic retimer_present;

  // Verification-only observability/control signals.
  pcie_ltssm_state_e ltssm_state;
  pcie_dl_state_e    dl_state;
  pcie_speed_e       negotiated_speed;
  pcie_link_width_e  negotiated_width;
  logic              link_up;
  logic              flit_mode_active;
  logic              equalization_in_progress;
  logic              error_indication;
  pcie_error_inject_e injected_error;

  clocking cb_drv @(posedge pclk);
    default input #1step output #1step;
    output rx_data, rx_datak, rx_valid, rx_start_block, rx_sync_header;
    output rx_elec_idle, rx_status, rx_polarity_inverted, rx_block_align;
    output rx_symbol_lock, rx_lane_aligned, rx_margin_status, pam4_symbol;
    output phy_status, rate_change_ack, eq_phase_done, lane_reversal_detected;
    output deskew_done, retimer_present, pipe_stall;
    input  tx_data, tx_datak, tx_valid, tx_start_block, tx_sync_header;
    input  tx_elec_idle, tx_detect_rx_loopback, tx_compliance, tx_margin;
    input  tx_deemph, tx_polarity, power_down, rate, width, phy_mode_flit;
    input  tx_ones_zeroes, precoding_enable, scrambling_enable;
  endclocking

  clocking cb_mon @(posedge pclk);
    default input #1step output #1step;
    input tx_data, tx_datak, tx_valid, tx_start_block, tx_sync_header;
    input tx_elec_idle, tx_detect_rx_loopback, tx_compliance, tx_margin;
    input tx_deemph, tx_polarity, power_down, rate, width, phy_mode_flit;
    input tx_ones_zeroes, precoding_enable, scrambling_enable;
    input rx_data, rx_datak, rx_valid, rx_start_block, rx_sync_header;
    input rx_elec_idle, rx_status, rx_polarity_inverted, rx_block_align;
    input rx_symbol_lock, rx_lane_aligned, rx_margin_status, pam4_symbol;
    input phy_status, rate_change_ack, eq_phase_done, lane_reversal_detected;
    input deskew_done, retimer_present, pipe_stall, ltssm_state, dl_state;
    input negotiated_speed, negotiated_width, link_up, flit_mode_active;
    input equalization_in_progress, error_indication, injected_error;
  endclocking

  modport dut (
    input  pclk, reset_n,
    input  rx_data, rx_datak, rx_valid, rx_start_block, rx_sync_header,
    input  rx_elec_idle, rx_status, rx_polarity_inverted, rx_block_align,
    input  rx_symbol_lock, rx_lane_aligned, rx_margin_status, pam4_symbol,
    input  phy_status, rate_change_ack, eq_phase_done, lane_reversal_detected,
    input  deskew_done, retimer_present, pipe_stall,
    output tx_data, tx_datak, tx_valid, tx_start_block, tx_sync_header,
    output tx_elec_idle, tx_detect_rx_loopback, tx_compliance, tx_margin,
    output tx_deemph, tx_polarity, power_down, rate, width, phy_mode_flit,
    output tx_ones_zeroes, precoding_enable, scrambling_enable,
    output ltssm_state, dl_state, negotiated_speed, negotiated_width,
    output link_up, flit_mode_active, equalization_in_progress,
    output error_indication, injected_error
  );

  modport phy_model (clocking cb_drv, clocking cb_mon, input pclk, input reset_n);
  modport monitor   (clocking cb_mon, input pclk, input reset_n);

endinterface : pcie_pipe_if

`endif

