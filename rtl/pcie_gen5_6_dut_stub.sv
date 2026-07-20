`timescale 1ns/1ps
`ifndef PCIE_GEN5_6_DUT_STUB_SV
`define PCIE_GEN5_6_DUT_STUB_SV

module pcie_gen5_6_dut_stub #(
  parameter pcie_gen5_6_types_pkg::pcie_device_mode_e DUT_MODE = pcie_gen5_6_types_pkg::PCIE_MODE_RC,
  parameter pcie_gen5_6_types_pkg::pcie_speed_e       MAX_SPEED = pcie_gen5_6_types_pkg::PCIE_GEN6_64P0,
  parameter pcie_gen5_6_types_pkg::pcie_link_width_e  MAX_WIDTH = pcie_gen5_6_types_pkg::PCIE_X16,
  parameter bit                                      ENABLE_FLIT_MODE = 1'b1
) (
  input  logic            core_clk,
  input  logic            reset_n,
  pcie_pipe_if.dut        pipe,
  pcie_tl_if.dut          tl,
  pcie_dl_if.dut          dl
);
  import pcie_gen5_6_types_pkg::*;

  pcie_ltssm_state_e ltssm_q;
  pcie_dl_state_e    dl_state_q;
  logic [7:0]        train_cnt_q;
  logic [9:0]        flit_seq_q;
  logic [11:0]       tlp_seq_q;

  always_ff @(posedge core_clk or negedge reset_n) begin
    if (!reset_n) begin
      ltssm_q     <= LTSSM_DETECT_QUIET;
      dl_state_q  <= DL_INACTIVE;
      train_cnt_q <= '0;
      flit_seq_q  <= '0;
      tlp_seq_q   <= '0;
    end else begin
      train_cnt_q <= train_cnt_q + 1'b1;

      unique case (ltssm_q)
        LTSSM_DETECT_QUIET:                 ltssm_q <= LTSSM_DETECT_ACTIVE;
        LTSSM_DETECT_ACTIVE:                ltssm_q <= LTSSM_POLLING_ACTIVE;
        LTSSM_POLLING_ACTIVE:               ltssm_q <= LTSSM_POLLING_CONFIGURATION;
        LTSSM_POLLING_CONFIGURATION:        ltssm_q <= LTSSM_CONFIGURATION_LINKWIDTH_START;
        LTSSM_CONFIGURATION_LINKWIDTH_START: ltssm_q <= LTSSM_CONFIGURATION_LINKWIDTH_ACCEPT;
        LTSSM_CONFIGURATION_LINKWIDTH_ACCEPT:ltssm_q <= LTSSM_CONFIGURATION_LANENUM_ACCEPT;
        LTSSM_CONFIGURATION_LANENUM_ACCEPT: ltssm_q <= LTSSM_CONFIGURATION_COMPLETE;
        LTSSM_CONFIGURATION_COMPLETE:       ltssm_q <= LTSSM_CONFIGURATION_IDLE;
        LTSSM_CONFIGURATION_IDLE:           ltssm_q <= (MAX_SPEED >= PCIE_GEN3_8P0) ? LTSSM_RECOVERY_EQUALIZATION : LTSSM_L0;
        LTSSM_RECOVERY_EQUALIZATION:        ltssm_q <= pipe.eq_phase_done ? LTSSM_RECOVERY_SPEED : LTSSM_RECOVERY_EQUALIZATION;
        LTSSM_RECOVERY_SPEED:               ltssm_q <= pipe.rate_change_ack ? LTSSM_RECOVERY_RCVRCFG : LTSSM_RECOVERY_SPEED;
        LTSSM_RECOVERY_RCVRCFG:             ltssm_q <= pipe.deskew_done ? LTSSM_RECOVERY_IDLE : LTSSM_RECOVERY_RCVRCFG;
        LTSSM_RECOVERY_IDLE:                ltssm_q <= LTSSM_L0;
        LTSSM_L0: begin
          if (pipe.injected_error == ERR_LINK_DOWN_ACTIVE) begin
            ltssm_q <= LTSSM_RECOVERY_RCVRLOCK;
          end
        end
        LTSSM_RECOVERY_RCVRLOCK:            ltssm_q <= LTSSM_RECOVERY_RCVRCFG;
        default:                            ltssm_q <= LTSSM_DETECT_QUIET;
      endcase

      unique case (dl_state_q)
        DL_INACTIVE: dl_state_q <= (ltssm_q inside {LTSSM_POLLING_ACTIVE, LTSSM_POLLING_CONFIGURATION}) ? DL_FEATURE : DL_INACTIVE;
        DL_FEATURE:  dl_state_q <= DL_INIT;
        DL_INIT:     dl_state_q <= (ltssm_q == LTSSM_L0) ? DL_ACTIVE : DL_INIT;
        DL_ACTIVE:   dl_state_q <= (ltssm_q == LTSSM_L0) ? DL_ACTIVE : DL_DOWN;
        DL_DOWN:     dl_state_q <= (ltssm_q == LTSSM_L0) ? DL_INIT : DL_DOWN;
        default:     dl_state_q <= DL_INACTIVE;
      endcase

      if (ltssm_q == LTSSM_L0 && ENABLE_FLIT_MODE && MAX_SPEED == PCIE_GEN6_64P0) begin
        flit_seq_q <= flit_seq_q + 1'b1;
      end
      if (tl.tl_valid && tl.tl_ready) begin
        tlp_seq_q <= tlp_seq_q + 1'b1;
      end
    end
  end

  always_comb begin
    pipe.ltssm_state              = ltssm_q;
    pipe.dl_state                 = dl_state_q;
    pipe.negotiated_speed         = MAX_SPEED;
    pipe.negotiated_width         = MAX_WIDTH;
    pipe.link_up                  = (ltssm_q == LTSSM_L0);
    pipe.flit_mode_active         = ENABLE_FLIT_MODE && (MAX_SPEED == PCIE_GEN6_64P0) && (ltssm_q == LTSSM_L0);
    pipe.equalization_in_progress = (ltssm_q == LTSSM_RECOVERY_EQUALIZATION);
    pipe.error_indication         = (pipe.injected_error != ERR_NONE);

    pipe.tx_data                  = '0;
    pipe.tx_datak                 = '0;
    pipe.tx_valid                 = '0;
    pipe.tx_start_block           = '0;
    pipe.tx_sync_header           = '0;
    pipe.tx_elec_idle             = '0;
    pipe.tx_detect_rx_loopback    = '0;
    pipe.tx_compliance            = '0;
    pipe.tx_margin                = '0;
    pipe.tx_deemph                = '0;
    pipe.tx_polarity              = '0;
    pipe.power_down               = 3'b000;
    pipe.rate                     = MAX_SPEED[3:0];
    pipe.width                    = MAX_WIDTH[4:0];
    pipe.phy_mode_flit            = ENABLE_FLIT_MODE;
    pipe.tx_ones_zeroes           = (MAX_SPEED == PCIE_GEN6_64P0);
    pipe.precoding_enable         = (MAX_SPEED >= PCIE_GEN4_16P0);
    pipe.scrambling_enable        = 1'b1;

    if (ltssm_q inside {LTSSM_POLLING_ACTIVE, LTSSM_POLLING_CONFIGURATION}) begin
      pipe.tx_valid       = '1;
      pipe.tx_datak       = '1;
      pipe.tx_data[0]     = 32'h5453_315F; // TS1 abstraction
    end else if (ltssm_q == LTSSM_L0 && ENABLE_FLIT_MODE) begin
      pipe.tx_valid       = '1;
      pipe.tx_start_block = '1;
      pipe.tx_sync_header = '{default:2'b10};
      pipe.tx_data[0]     = {16'hF17A, flit_seq_q, 6'h0};
    end

    tl.tl_valid               = (ltssm_q == LTSSM_L0) && (dl_state_q == DL_ACTIVE);
    tl.tl_type                = TLP_NOP;
    tl.requester_id           = (DUT_MODE == PCIE_MODE_RC) ? 16'h0000 : 16'h0100;
    tl.completer_id           = (DUT_MODE == PCIE_MODE_RC) ? 16'h0100 : 16'h0000;
    tl.tag                    = tlp_seq_q[9:0];
    tl.addr                   = 64'h0;
    tl.length_dw              = 10'd1;
    tl.first_be               = 4'hF;
    tl.last_be                = 4'h0;
    tl.traffic_class          = 3'd0;
    tl.attr                   = 3'd0;
    tl.poisoned               = (pipe.injected_error == ERR_POISONED_TLP);
    tl.ecrc_present           = 1'b0;
    tl.ide_present            = 1'b0;
    tl.pasid                  = '0;
    tl.ohc_vector             = '0;
    tl.completion_timeout     = (pipe.injected_error == ERR_REPLAY_TIMEOUT);
    tl.malformed_tlp          = (pipe.injected_error == ERR_MALFORMED_TLP);
    tl.cfg_side_effect        = 1'b0;

    dl.dl_valid               = (dl_state_q != DL_INACTIVE);
    dl.dlp_type               = (pipe.injected_error == ERR_FORCE_NAK) ? DLP_NAK : DLP_ACK;
    dl.dl_state               = dl_state_q;
    dl.tlp_seq_num            = tlp_seq_q;
    dl.flit_seq_num           = flit_seq_q;
    dl.ack_nak_seq_num        = flit_seq_q;
    dl.ack                    = (dl.dlp_type == DLP_ACK);
    dl.nak                    = (dl.dlp_type == DLP_NAK);
    dl.replay_req             = (pipe.injected_error inside {ERR_FORCE_NAK, ERR_BAD_CRC, ERR_BAD_ECC, ERR_BAD_FLIT_SEQ});
    dl.replay_timer_expired   = (pipe.injected_error == ERR_REPLAY_TIMEOUT);
    dl.lcrc_error             = (pipe.injected_error == ERR_BAD_LCRC);
    dl.dllp_crc_error         = (pipe.injected_error == ERR_BAD_CRC);
    dl.dl_feature_exchange_done = (dl_state_q inside {DL_INIT, DL_ACTIVE});
    dl.fc_init_done           = (dl_state_q == DL_ACTIVE);
    dl.ph_credit              = 12'd64;
    dl.pd_credit              = 12'd256;
    dl.nph_credit             = 12'd64;
    dl.npd_credit             = 12'd256;
    dl.cplh_credit            = 12'd64;
    dl.cpld_credit            = 12'd256;
    dl.optimized_update_fc    = ENABLE_FLIT_MODE;
    dl.scaled_fc_enable       = (MAX_SPEED >= PCIE_GEN5_32P0);
    dl.link_down              = (ltssm_q != LTSSM_L0);
    dl.error_to_tl            = pipe.error_indication;
  end

endmodule : pcie_gen5_6_dut_stub

`endif

