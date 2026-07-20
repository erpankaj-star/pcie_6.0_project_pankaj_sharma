`ifndef PCIE_GEN5_6_FLOW_CONTROL_TEST_SV
`define PCIE_GEN5_6_FLOW_CONTROL_TEST_SV

class pcie_gen5_6_flow_control_test extends pcie_gen5_6_base_test;
  `uvm_component_utils(pcie_gen5_6_flow_control_test)

  function new(string name = "pcie_gen5_6_flow_control_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    pcie_gen5_6_link_training_seq    s_link_training;
    pcie_gen5_6_flow_control_seq     s_flow_control;
    phase.raise_objection(this);
    s_link_training = pcie_gen5_6_link_training_seq::type_id::create("s_link_training");
    s_flow_control  = pcie_gen5_6_flow_control_seq::type_id::create("s_flow_control");
    s_link_training.start(env.vseqr);
    s_flow_control.start(env.vseqr);
    phase.drop_objection(this);
  endtask
endclass : pcie_gen5_6_flow_control_test

`endif
