`ifndef PCIE_GEN5_6_GEN5_32GT_TEST_SV
`define PCIE_GEN5_6_GEN5_32GT_TEST_SV

class pcie_gen5_6_gen5_32gt_test extends pcie_gen5_6_base_test;
  `uvm_component_utils(pcie_gen5_6_gen5_32gt_test)

  function new(string name = "pcie_gen5_6_gen5_32gt_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // Override build_phase to apply speed/flit knobs BEFORE env construction
  // so that all agents and drivers see the correct configuration.
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg.max_speed        = PCIE_GEN5_32P0;
    cfg.enable_flit_mode = 1'b0;
  endfunction

  task run_phase(uvm_phase phase);
    pcie_gen5_6_link_training_seq    s_link_training;
    pcie_gen5_6_mem_rd_wr_seq        s_mem_rd_wr;
    phase.raise_objection(this);
    s_link_training = pcie_gen5_6_link_training_seq::type_id::create("s_link_training");
    s_mem_rd_wr     = pcie_gen5_6_mem_rd_wr_seq::type_id::create("s_mem_rd_wr");
    s_link_training.start(env.vseqr);
    s_mem_rd_wr.start(env.vseqr);
    phase.drop_objection(this);
  endtask
endclass : pcie_gen5_6_gen5_32gt_test

`endif























