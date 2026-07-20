`ifndef PCIE_GEN5_6_TL_ASSERTIONS_SV
`define PCIE_GEN5_6_TL_ASSERTIONS_SV

module pcie_gen5_6_tl_assertions (pcie_tl_if.monitor tl);
  import pcie_gen5_6_types_pkg::*;

  property p_no_tlp_without_fc;
    @(posedge tl.clk) disable iff (!tl.reset_n)
      (tl.tl_valid && tl.tl_type == TLP_MEM_WR) |-> tl.credit_avail.ph;
  endproperty

  property p_np_requires_nph_credit;
    @(posedge tl.clk) disable iff (!tl.reset_n)
      (tl.tl_valid && tl.tl_type inside {TLP_MEM_RD, TLP_CFG_RD0, TLP_CFG_RD1}) |-> tl.credit_avail.nph;
  endproperty

  property p_cfg_dw_len;
    @(posedge tl.clk) disable iff (!tl.reset_n)
      (tl.tl_valid && tl.tl_type inside {TLP_CFG_RD0, TLP_CFG_WR0, TLP_CFG_RD1, TLP_CFG_WR1}) |-> (tl.length_dw == 10'd1);
  endproperty

  property p_single_dw_last_be_zero;
    @(posedge tl.clk) disable iff (!tl.reset_n)
      (tl.tl_valid && tl.length_dw == 10'd1) |-> (tl.last_be == 4'h0);
  endproperty

  a_no_tlp_without_fc:      assert property (p_no_tlp_without_fc);
  a_np_requires_nph_credit: assert property (p_np_requires_nph_credit);
  a_cfg_dw_len:             assert property (p_cfg_dw_len);
  a_single_dw_last_be_zero: assert property (p_single_dw_last_be_zero);
endmodule : pcie_gen5_6_tl_assertions

`endif

