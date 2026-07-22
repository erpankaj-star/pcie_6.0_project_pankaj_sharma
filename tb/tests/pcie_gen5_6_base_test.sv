`ifndef PCIE_GEN5_6_BASE_TEST_SV
`define PCIE_GEN5_6_BASE_TEST_SV

class pcie_gen5_6_base_test extends uvm_test;
  `uvm_component_utils(pcie_gen5_6_base_test)

  pcie_gen5_6_env env;
  pcie_gen5_6_cfg cfg;

  function new(string name = "pcie_gen5_6_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    cfg = pcie_gen5_6_cfg::type_id::create("cfg");
    apply_plusargs();
    uvm_config_db#(pcie_gen5_6_cfg)::set(this, "*", "cfg", cfg);
    env = pcie_gen5_6_env::type_id::create("env", this);
  endfunction

  function void apply_plusargs();
    string mode;
    string err;
    int    speed;
    int    width;
    if ($value$plusargs("PCIE_MODE=%s", mode)) begin
      cfg.dut_mode = (mode == "EP") ? PCIE_AGENT_EP : PCIE_AGENT_RC;
    end
    if ($value$plusargs("PCIE_SPEED=%0d", speed)) begin
      cfg.max_speed = pcie_link_speed_e'(speed);
    end
    if ($value$plusargs("PCIE_WIDTH=%0d", width)) begin
      cfg.max_width    = pcie_link_width_e'(width);
      cfg.active_lanes = width;
    end
    if ($value$plusargs("PCIE_ERROR=%s", err)) begin
      if      (err == "BAD_CRC")   cfg.error_kind = ERR_BAD_CRC;
      else if (err == "BAD_ECC")   cfg.error_kind = ERR_BAD_ECC;
      else if (err == "BAD_SEQ")   cfg.error_kind = ERR_BAD_FLIT_SEQ;
      else if (err == "NAK")       cfg.error_kind = ERR_FORCE_NAK;
      else if (err == "LINK_DOWN") cfg.error_kind = ERR_LINK_DOWN_ACTIVE;
    end
  endfunction

function void end_of_elaboration_phase(uvm_phase phase);
uvm_factory factory = uvm_factory::get();
super.end_of_elaboration_phase(phase);
factory.print();
uvm_top.print_topology();
endfunction


  task run_phase(uvm_phase phase);
    pcie_gen5_6_link_training_seq seq;
    phase.raise_objection(this);
    seq = pcie_gen5_6_link_training_seq::type_id::create("seq");
    seq.start(env.vseqr);
    phase.drop_objection(this);
  endtask
endclass : pcie_gen5_6_base_test

`endif






















































