`ifndef PCIE_GEN5_6_ERROR_AER_DPC_TEST_SV
`define PCIE_GEN5_6_ERROR_AER_DPC_TEST_SV

class pcie_gen5_6_error_aer_dpc_test extends pcie_gen5_6_base_test;
  `uvm_component_utils(pcie_gen5_6_error_aer_dpc_test)

  function new(string name = "pcie_gen5_6_error_aer_dpc_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    pcie_gen5_6_link_training_seq   s_pcie_gen5_6_link_training_seq;
    pcie_gen5_6_error_injection_seq s_pcie_gen5_6_error_injection_seq;
    cfg.enable_aer = 1'b1; cfg.enable_dpc = 1'b1; cfg.error_kind = ERR_MALFORMED_TLP;
    phase.raise_objection(this);
    s_pcie_gen5_6_link_training_seq = pcie_gen5_6_link_training_seq::type_id::create("s_pcie_gen5_6_link_training_seq");
    s_pcie_gen5_6_link_training_seq.start(env.vseqr);
    s_pcie_gen5_6_error_injection_seq = pcie_gen5_6_error_injection_seq::type_id::create("s_pcie_gen5_6_error_injection_seq");
    s_pcie_gen5_6_error_injection_seq.start(env.vseqr);
    phase.drop_objection(this);
  endtask
endclass : pcie_gen5_6_error_aer_dpc_test

`endif
