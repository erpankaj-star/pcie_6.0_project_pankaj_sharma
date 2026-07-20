`ifndef PCIE_GEN5_6_VIRTUAL_SEQUENCER_SV
`define PCIE_GEN5_6_VIRTUAL_SEQUENCER_SV

class pcie_gen5_6_virtual_sequencer extends uvm_sequencer;
  `uvm_component_utils(pcie_gen5_6_virtual_sequencer)

  uvm_sequencer #(pcie_pipe_symbol_item) pipe_seqr;
  uvm_sequencer #(pcie_tlp_item)         tl_seqr;
  uvm_sequencer #(pcie_dlp_item)         dl_seqr;
  pcie_gen5_6_cfg cfg;

  function new(string name = "pcie_gen5_6_virtual_sequencer", uvm_component parent = null);
    super.new(name, parent);
  endfunction
endclass : pcie_gen5_6_virtual_sequencer

`endif

