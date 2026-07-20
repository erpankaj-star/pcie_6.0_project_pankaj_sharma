`ifndef PCIE_GEN5_6_CFG_TEST_SV
`define PCIE_GEN5_6_CFG_TEST_SV

class pcie_gen5_6_cfg_test extends pcie_gen5_6_base_test;
  `uvm_component_utils(pcie_gen5_6_cfg_test)

  function new(string name = "pcie_gen5_6_cfg_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    pcie_gen5_6_link_training_seq    s_link_training;
    pcie_gen5_6_cfg_rd_wr_seq        s_cfg_rd_wr;
    phase.raise_objection(this);
    s_link_training = pcie_gen5_6_link_training_seq::type_id::create("s_link_training");
    s_cfg_rd_wr     = pcie_gen5_6_cfg_rd_wr_seq::type_id::create("s_cfg_rd_wr");
    s_link_training.start(env.vseqr);
    s_cfg_rd_wr.start(env.vseqr);
    phase.drop_objection(this);
  endtask
endclass : pcie_gen5_6_cfg_test

`endif






















