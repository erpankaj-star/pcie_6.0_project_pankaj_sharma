`ifndef PCIE_GEN5_6_LTSSM_ASSERTIONS_SV
`define PCIE_GEN5_6_LTSSM_ASSERTIONS_SV

module pcie_gen5_6_ltssm_assertions (pcie_pipe_if.monitor pipe);
  import pcie_gen5_6_types_pkg::*;

  property p_detect_to_polling_legal;
    @(posedge pipe.pclk) disable iff (!pipe.reset_n)
      ($past(pipe.cb_mon.ltssm_state) == LTSSM_DETECT_ACTIVE && pipe.cb_mon.ltssm_state != LTSSM_DETECT_ACTIVE) |->
        (pipe.cb_mon.ltssm_state inside {LTSSM_POLLING_ACTIVE, LTSSM_DETECT_QUIET});
  endproperty

  property p_configuration_before_l0;
    @(posedge pipe.pclk) disable iff (!pipe.reset_n)
      (pipe.cb_mon.ltssm_state == LTSSM_L0 && $past(pipe.cb_mon.ltssm_state) != LTSSM_L0) |->
        ($past(pipe.cb_mon.ltssm_state) inside {LTSSM_RECOVERY_IDLE, LTSSM_CONFIGURATION_IDLE});
  endproperty

  property p_hot_reset_not_from_detect;
    @(posedge pipe.pclk) disable iff (!pipe.reset_n)
      (pipe.cb_mon.ltssm_state == LTSSM_HOT_RESET) |-> ($past(pipe.cb_mon.ltssm_state) != LTSSM_DETECT_QUIET);
  endproperty

  a_detect_to_polling_legal: assert property (p_detect_to_polling_legal);
  a_configuration_before_l0: assert property (p_configuration_before_l0);
  a_hot_reset_not_from_detect: assert property (p_hot_reset_not_from_detect);
endmodule : pcie_gen5_6_ltssm_assertions

`endif

