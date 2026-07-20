`ifndef PCIE_GEN5_6_PIPE_ASSERTIONS_SV
`define PCIE_GEN5_6_PIPE_ASSERTIONS_SV

module pcie_gen5_6_pipe_assertions (pcie_pipe_if.monitor pipe);
  import pcie_gen5_6_types_pkg::*;

  property p_pipe_stable_during_stall;
    @(posedge pipe.pclk) disable iff (!pipe.reset_n)
      pipe.cb_mon.pipe_stall |=> $stable(pipe.cb_mon.tx_data) and
                                $stable(pipe.cb_mon.tx_valid) and
                                $stable(pipe.cb_mon.tx_start_block);
  endproperty

  property p_gen6_requires_flit_mode;
    @(posedge pipe.pclk) disable iff (!pipe.reset_n)
      (pipe.cb_mon.negotiated_speed == PCIE_GEN6_64P0 && pipe.cb_mon.link_up) |-> pipe.cb_mon.flit_mode_active;
  endproperty

  property p_no_l0_before_training;
    @(posedge pipe.pclk) disable iff (!pipe.reset_n)
      (pipe.cb_mon.ltssm_state == LTSSM_L0) |-> (pipe.cb_mon.deskew_done && !pipe.cb_mon.equalization_in_progress);
  endproperty

  property p_flit_valid_has_start_block;
    @(posedge pipe.pclk) disable iff (!pipe.reset_n)
      (pipe.cb_mon.flit_mode_active && pipe.cb_mon.tx_valid[0]) |-> pipe.cb_mon.tx_start_block[0];
  endproperty

  a_pipe_stable_during_stall: assert property (p_pipe_stable_during_stall);
  a_gen6_requires_flit_mode:   assert property (p_gen6_requires_flit_mode);
  a_no_l0_before_training:     assert property (p_no_l0_before_training);
  a_flit_valid_has_start_blk:  assert property (p_flit_valid_has_start_block);
endmodule : pcie_gen5_6_pipe_assertions

`endif

