`ifndef PCIE_GEN5_6_PIPE_AGENT_SV
`define PCIE_GEN5_6_PIPE_AGENT_SV

class pcie_gen5_6_pipe_agent extends uvm_agent;
  `uvm_component_utils(pcie_gen5_6_pipe_agent)

  uvm_sequencer #(pcie_pipe_symbol_item) sequencer;
  pcie_gen5_6_pipe_driver driver;
  pcie_gen5_6_pipe_monitor monitor;
  uvm_analysis_port #(pcie_pipe_symbol_item) ap;

  function new(string name = "pcie_gen5_6_pipe_agent", uvm_component parent = null);
    super.new(name, parent);
    ap = new("ap", this);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    sequencer = uvm_sequencer #(pcie_pipe_symbol_item)::type_id::create("sequencer", this);
    driver    = pcie_gen5_6_pipe_driver::type_id::create("driver", this);
    monitor   = pcie_gen5_6_pipe_monitor::type_id::create("monitor", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    driver.seq_item_port.connect(sequencer.seq_item_export);
    monitor.ap.connect(ap);
  endfunction
endclass : pcie_gen5_6_pipe_agent

`endif

