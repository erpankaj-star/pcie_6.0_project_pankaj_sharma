`ifndef PCIE_GEN5_6_DL_ASSERTIONS_SV
`define PCIE_GEN5_6_DL_ASSERTIONS_SV

module pcie_gen5_6_dl_assertions (pcie_dl_if.monitor dl);
  import pcie_gen5_6_types_pkg::*;

  property p_ack_nak_exclusive;
    @(posedge dl.clk) disable iff (!dl.reset_n)
      !(dl.ack && dl.nak);
  endproperty

  property p_replay_on_nak;
    @(posedge dl.clk) disable iff (!dl.reset_n)
      dl.nak |-> ##[0:16] dl.replay_req;
  endproperty

  property p_flit_seq_increments_when_active;
    @(posedge dl.clk) disable iff (!dl.reset_n)
      (dl.dl_state == DL_ACTIVE && dl.dl_valid && !dl.nak) |=> (dl.flit_seq_num == $past(dl.flit_seq_num) + 1'b1) or dl.ack;
  endproperty

  property p_active_requires_fc_done;
    @(posedge dl.clk) disable iff (!dl.reset_n)
      (dl.dl_state == DL_ACTIVE) |-> dl.fc_init_done;
  endproperty

  a_ack_nak_exclusive:             assert property (p_ack_nak_exclusive);
  a_replay_on_nak:                 assert property (p_replay_on_nak);
  a_flit_seq_increments_when_active: assert property (p_flit_seq_increments_when_active);
  a_active_requires_fc_done:       assert property (p_active_requires_fc_done);
endmodule : pcie_gen5_6_dl_assertions

`endif

