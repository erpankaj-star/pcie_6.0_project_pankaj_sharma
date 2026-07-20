`ifndef PCIE_GEN5_6_POWER_L0S_L1_L2_TEST_SV
`define PCIE_GEN5_6_POWER_L0S_L1_L2_TEST_SV

class pcie_gen5_6_power_l0s_l1_l2_test extends pcie_gen5_6_base_test;
  `uvm_component_utils(pcie_gen5_6_power_l0s_l1_l2_test)

  function new(string name = "pcie_gen5_6_power_l0s_l1_l2_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    pcie_gen5_6_link_training_seq s_pcie_gen5_6_link_training_seq;
    pcie_gen5_6_power_mgmt_seq    s_pcie_gen5_6_power_mgmt_seq;
    phase.raise_objection(this);
    s_pcie_gen5_6_link_training_seq = pcie_gen5_6_link_training_seq::type_id::create("s_pcie_gen5_6_link_training_seq");
    s_pcie_gen5_6_link_training_seq.start(env.vseqr);
    s_pcie_gen5_6_power_mgmt_seq = pcie_gen5_6_power_mgmt_seq::type_id::create("s_pcie_gen5_6_power_mgmt_seq");
    s_pcie_gen5_6_power_mgmt_seq.start(env.vseqr);
    phase.drop_objection(this);
  endtask
endclass : pcie_gen5_6_power_l0s_l1_l2_test

`endif
