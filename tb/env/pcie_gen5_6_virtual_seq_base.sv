`ifndef PCIE_GEN5_6_VIRTUAL_SEQ_BASE_SV
`define PCIE_GEN5_6_VIRTUAL_SEQ_BASE_SV

//------------------------------------------------------------------------------
// pcie_gen5_6_virtual_seq_base.sv
// Path: ../sequences/pcie_gen5_6_virtual_seq_base.sv
//
// Parent class for all virtual sequences.
// Binds p_sequencer to pcie_gen5_6_virtual_sequencer.
// Provides start_pipe_seq / start_tl_seq / start_dl_seq helpers.
// Resolves cfg from p_sequencer in pre_body().
//------------------------------------------------------------------------------
class pcie_gen5_6_virtual_seq_base extends uvm_sequence #(uvm_sequence_item);
  `uvm_object_utils(pcie_gen5_6_virtual_seq_base)
  `uvm_declare_p_sequencer(pcie_gen5_6_virtual_sequencer)

  pcie_gen5_6_cfg cfg;

  function new(string name = "pcie_gen5_6_virtual_seq_base");
    super.new(name);
  endfunction

  virtual task pre_body();
    if (p_sequencer == null || p_sequencer.cfg == null) begin
      `uvm_fatal(get_type_name(),
        "pre_body: cfg not set on virtual sequencer. Check env.connect_phase.")
    end
    cfg = p_sequencer.cfg;
    `uvm_info(get_type_name(),
      $sformatf("pre_body: speed=%s width=%s flit=%0b mode=%s",
        cfg.max_speed.name(), cfg.max_width.name(),
        cfg.enable_flit_mode, cfg.agent_mode.name()), UVM_MEDIUM)
  endtask

  virtual task post_body();
    `uvm_info(get_type_name(), "virtual sequence complete", UVM_MEDIUM)
  endtask

  // Start any base_seq-derived sequence on the PIPE sub-sequencer
  task start_pipe_seq(pcie_gen5_6_base_seq seq_h);
    seq_h.start(p_sequencer.pipe_seqr);
  endtask

  // Start any base_seq-derived sequence on the TL sub-sequencer
  task start_tl_seq(pcie_gen5_6_base_seq seq_h);
    seq_h.start(p_sequencer.tl_seqr);
  endtask

  // Start any base_seq-derived sequence on the DL sub-sequencer
  task start_dl_seq(pcie_gen5_6_base_seq seq_h);
    seq_h.start(p_sequencer.dl_seqr);
  endtask

endclass : pcie_gen5_6_virtual_seq_base

`endif
