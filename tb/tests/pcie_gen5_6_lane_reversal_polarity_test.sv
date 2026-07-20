`ifndef PCIE_GEN5_6_LANE_REVERSAL_POLARITY_TEST_SV
`define PCIE_GEN5_6_LANE_REVERSAL_POLARITY_TEST_SV

class pcie_gen5_6_lane_reversal_polarity_test extends pcie_gen5_6_base_test;
  `uvm_component_utils(pcie_gen5_6_lane_reversal_polarity_test)

  function new(string name = "pcie_gen5_6_lane_reversal_polarity_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    pcie_gen5_6_link_training_seq  s_pcie_gen5_6_link_training_seq;
    pcie_gen5_6_lane_margining_seq s_pcie_gen5_6_lane_margining_seq;
    cfg.lane_reversal_enable = 1'b1; cfg.polarity_inversion_enable = 1'b1;
    phase.raise_objection(this);
    s_pcie_gen5_6_link_training_seq = pcie_gen5_6_link_training_seq::type_id::create("s_pcie_gen5_6_link_training_seq");
    s_pcie_gen5_6_link_training_seq.start(env.vseqr);
    s_pcie_gen5_6_lane_margining_seq = pcie_gen5_6_lane_margining_seq::type_id::create("s_pcie_gen5_6_lane_margining_seq");
    s_pcie_gen5_6_lane_margining_seq.start(env.vseqr);
    phase.drop_objection(this);
  endtask
endclass : pcie_gen5_6_lane_reversal_polarity_test

`endif
