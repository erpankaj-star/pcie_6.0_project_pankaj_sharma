`ifndef PCIE_GEN5_6_ENV_SV
`define PCIE_GEN5_6_ENV_SV

class pcie_gen5_6_env extends uvm_env;
  `uvm_component_utils(pcie_gen5_6_env)

  pcie_gen5_6_cfg cfg;
  pcie_gen5_6_pipe_agent pipe_agent;
  pcie_gen5_6_tl_agent   tl_agent;
  pcie_gen5_6_dl_agent   dl_agent;
  pcie_gen5_6_virtual_sequencer vseqr;
  pcie_gen5_6_scoreboard scoreboard;
  pcie_gen5_6_coverage coverage;
  pcie_gen5_6_ref_model ref_model;

  function new(string name = "pcie_gen5_6_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(pcie_gen5_6_cfg)::get(this, "", "cfg", cfg)) begin
      cfg = pcie_gen5_6_cfg::type_id::create("cfg");
      uvm_config_db#(pcie_gen5_6_cfg)::set(this, "*", "cfg", cfg);
    end
    pipe_agent = pcie_gen5_6_pipe_agent::type_id::create("pipe_agent", this);
    tl_agent   = pcie_gen5_6_tl_agent::type_id::create("tl_agent", this);
    dl_agent   = pcie_gen5_6_dl_agent::type_id::create("dl_agent", this);
    vseqr      = pcie_gen5_6_virtual_sequencer::type_id::create("vseqr", this);
    scoreboard = pcie_gen5_6_scoreboard::type_id::create("scoreboard", this);
    coverage   = pcie_gen5_6_coverage::type_id::create("coverage", this);
    ref_model  = pcie_gen5_6_ref_model::type_id::create("ref_model", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    vseqr.pipe_seqr = pipe_agent.sequencer;
    vseqr.tl_seqr   = tl_agent.sequencer;
    vseqr.dl_seqr   = dl_agent.sequencer;
    vseqr.cfg       = cfg;
    pipe_agent.ap.connect(scoreboard.pipe_imp);
    pipe_agent.ap.connect(coverage.analysis_export);
    tl_agent.ap.connect(scoreboard.tl_imp);
    dl_agent.ap.connect(scoreboard.dl_imp);
  endfunction
endclass : pcie_gen5_6_env

`endif
















































