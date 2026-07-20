`ifndef PCIE_GEN5_6_COVERAGE_SV
`define PCIE_GEN5_6_COVERAGE_SV

class pcie_gen5_6_coverage extends uvm_subscriber #(pcie_pipe_symbol_item);
  `uvm_component_utils(pcie_gen5_6_coverage)

  pcie_agent_mode_e     cov_mode;
  pcie_link_speed_e     cov_speed;
  pcie_link_width_e     cov_width;
  pcie_pipe_symbol_e    cov_symbol;
  pcie_error_kind_e     cov_error;
  bit                   cov_flit_mode;
  bit                   cov_lane_reversal;
  bit                   cov_polarity;
  bit                   cov_deskew;
  bit                   cov_retimer;
  bit                   cov_precoding;
  bit                   cov_scrambling;
  pcie_gen5_6_cfg       cfg;

  covergroup pcie_pipe_cg;
    option.per_instance = 1;
    cp_mode: coverpoint cov_mode {
      bins rc = {PCIE_AGENT_RC};
      bins ep = {PCIE_AGENT_EP};
    }
    cp_speed: coverpoint cov_speed {
      bins gen1 = {PCIE_GEN1_2P5};
      bins gen2 = {PCIE_GEN2_5P0};
      bins gen3 = {PCIE_GEN3_8P0};
      bins gen4 = {PCIE_GEN4_16P0};
      bins gen5 = {PCIE_GEN5_32P0};
      bins gen6 = {PCIE_GEN6_64P0};
    }
    cp_width: coverpoint cov_width {
      bins x1  = {PCIE_WIDTH_X1};
      bins x2  = {PCIE_WIDTH_X2};
      bins x4  = {PCIE_WIDTH_X4};
      bins x8  = {PCIE_WIDTH_X8};
      bins x16 = {PCIE_WIDTH_X16};
    }
    cp_symbol: coverpoint cov_symbol {
      bins ts[]  = {PIPE_SYM_TS1, PIPE_SYM_TS2};
      bins skp   = {PIPE_SYM_SKP};
      bins sds   = {PIPE_SYM_SDS};
      bins eios[] = {PIPE_SYM_EIOS, PIPE_SYM_EIEOS};
      bins flit  = {PIPE_SYM_FLIT};
    }
    cp_error: coverpoint cov_error {
      bins none    = {ERR_NONE};
      bins crc     = {ERR_BAD_CRC};
      bins ecc     = {ERR_BAD_ECC};
      bins replay[] = {ERR_FORCE_NAK, ERR_REPLAY_TIMEOUT};
      bins link[]  = {ERR_LINK_DOWN_ACTIVE, ERR_LTSSM_TIMEOUT, ERR_EQ_FAILURE, ERR_DESKEW_FAILURE};
    }
    cp_flit: coverpoint cov_flit_mode {
      bins off = {0};
      bins on  = {1};
    }
    cp_lane_features: coverpoint {cov_lane_reversal, cov_polarity, cov_deskew, cov_retimer} {
      bins clean    = {4'b0010};
      bins reversal = {4'b1010};
      bins polarity = {4'b0110};
      bins retimer  = {4'b0011};
    }
    cp_phy_abstraction: coverpoint {cov_precoding, cov_scrambling} {
      bins both         = {2'b11};
      bins scramble_only = {2'b01};
      bins none         = {2'b00};
    }
    cross_speed_width: cross cp_speed, cp_width;
    cross_gen6_flit:   cross cp_speed, cp_flit {
      bins gen6_flit = binsof(cp_speed.gen6) && binsof(cp_flit.on);
    }
    cross_error_speed: cross cp_error, cp_speed;
  endgroup

  function new(string name = "pcie_gen5_6_coverage", uvm_component parent = null);
    super.new(name, parent);
    pcie_pipe_cg = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pcie_gen5_6_cfg)::get(this, "", "cfg", cfg)) begin
      cfg = pcie_gen5_6_cfg::type_id::create("cfg");
    end
  endfunction

  function void write(pcie_pipe_symbol_item t);
    cov_mode          = cfg.dut_mode;
    cov_speed         = t.speed;
    cov_width         = t.width;
    cov_symbol        = t.symbol_type;
    cov_error         = t.error_kind;
    cov_flit_mode     = (t.symbol_type == PIPE_SYM_FLIT);
    cov_lane_reversal = t.lane_reversal;
    cov_polarity      = t.polarity_inverted;
    cov_deskew        = t.deskew_marker;
    cov_retimer       = t.retimer_marker;
    cov_precoding     = t.precoding_enable;
    cov_scrambling    = t.scrambling_enable;
    pcie_pipe_cg.sample();
  endfunction
endclass : pcie_gen5_6_coverage

`endif








































































