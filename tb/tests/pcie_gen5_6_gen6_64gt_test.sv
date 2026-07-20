`ifndef PCIE_GEN5_6_GEN6_64GT_TEST_SV
`define PCIE_GEN5_6_GEN6_64GT_TEST_SV

class pcie_gen5_6_gen6_64gt_test extends pcie_gen5_6_base_test;
  `uvm_component_utils(pcie_gen5_6_gen6_64gt_test)

  function new(string name = "pcie_gen5_6_gen6_64gt_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    pcie_gen5_6_link_training_seq   s_pcie_gen5_6_link_training_seq;
    pcie_gen5_6_flit_mode_entry_seq s_pcie_gen5_6_flit_mode_entry_seq;
    pcie_gen5_6_mem_rd_wr_seq       s_pcie_gen5_6_mem_rd_wr_seq;
    cfg.max_speed = PCIE_GEN6_64P0; cfg.enable_flit_mode = 1'b1;
    phase.raise_objection(this);
    s_pcie_gen5_6_link_training_seq = pcie_gen5_6_link_training_seq::type_id::create("s_pcie_gen5_6_link_training_seq");
    s_pcie_gen5_6_link_training_seq.start(env.vseqr);
    s_pcie_gen5_6_flit_mode_entry_seq = pcie_gen5_6_flit_mode_entry_seq::type_id::create("s_pcie_gen5_6_flit_mode_entry_seq");
    s_pcie_gen5_6_flit_mode_entry_seq.start(env.vseqr);
    s_pcie_gen5_6_mem_rd_wr_seq = pcie_gen5_6_mem_rd_wr_seq::type_id::create("s_pcie_gen5_6_mem_rd_wr_seq");
    s_pcie_gen5_6_mem_rd_wr_seq.start(env.vseqr);
    phase.drop_objection(this);
  endtask
endclass : pcie_gen5_6_gen6_64gt_test

`endif
