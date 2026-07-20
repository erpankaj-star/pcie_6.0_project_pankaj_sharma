`ifndef PCIE_GEN5_6_FLIT_MODE_VSEQ_SV
`define PCIE_GEN5_6_FLIT_MODE_VSEQ_SV

//------------------------------------------------------------------------------
// pcie_gen5_6_flit_mode_vseq.sv
// Path: ../sequences/pcie_gen5_6_flit_mode_vseq.sv
//
// Virtual sequence coordinating FLIT mode stimulus across PIPE and DL layers.
//   Step 1: PIPE - SDS + FLIT burst (FLIT mode entry handshake)
//   Step 2: DL   - FC_UPDATE DLLPs with DLP_OPT_UPDATEFC (optimized FC)
//   Step 3: PIPE - Additional FLIT data bursts
//------------------------------------------------------------------------------

//==============================================================================
// DL FC Update sub-sequence (used by flit mode and mem_rd_wr vseqs)
//==============================================================================
class pcie_gen5_6_dl_fc_update_seq extends pcie_gen5_6_base_seq;
  `uvm_object_utils(pcie_gen5_6_dl_fc_update_seq)

  function new(string name = "pcie_gen5_6_dl_fc_update_seq");
    super.new(name);
  endfunction

  virtual task body();
    bit [9:0] seq_num;
    super.pre_body();
    seq_num = get_next_flit_seq_num();
    // DLP_UPDATEFC is the correct enum value from pcie_gen5_6_types_pkg
    send_dlp(DLP_UPDATEFC, seq_num);
    send_dlp(DLP_UPDATEFC, seq_num);
    send_dlp(DLP_UPDATEFC, seq_num);
  endtask
endclass : pcie_gen5_6_dl_fc_update_seq


//==============================================================================
// PIPE FLIT burst sub-sequence
//==============================================================================
class pcie_gen5_6_flit_burst_seq extends pcie_gen5_6_base_seq;
  `uvm_object_utils(pcie_gen5_6_flit_burst_seq)

  function new(string name = "pcie_gen5_6_flit_burst_seq");
    super.new(name);
  endfunction

  virtual task body();
    int unsigned burst_len;
    bit [31:0]   flit_data;
    super.pre_body();
    assert(std::randomize(burst_len) with {
      burst_len inside {[cfg.flit_burst_count_min : cfg.flit_burst_count_max]};
    });
    repeat (burst_len) begin
      assert(std::randomize(flit_data));
      send_pipe_symbol(PIPE_SYM_FLIT, 0, flit_data);
    end
  endtask
endclass : pcie_gen5_6_flit_burst_seq


//==============================================================================
// Virtual sequence
//==============================================================================
class pcie_gen5_6_flit_mode_vseq extends pcie_gen5_6_virtual_seq_base;
  `uvm_object_utils(pcie_gen5_6_flit_mode_vseq)

  function new(string name = "pcie_gen5_6_flit_mode_vseq");
    super.new(name);
  endfunction

  virtual task body();
    pcie_gen5_6_pipe_sds_seq      s_sds;
    pcie_gen5_6_flit_burst_seq    s_flit;
    pcie_gen5_6_dl_fc_update_seq  s_fc;
    int unsigned                  burst_count;

    super.pre_body();

    if (!cfg.enable_flit_mode) begin
      `uvm_warning(get_type_name(),
        "flit_mode_vseq: cfg.enable_flit_mode==0, skipping")
      return;
    end

    `uvm_info(get_type_name(), "FLIT MODE VSEQ START", UVM_LOW)

    // Step 1: PIPE SDS + initial FLIT burst
    s_sds = pcie_gen5_6_pipe_sds_seq::type_id::create("s_sds");
    start_pipe_seq(s_sds);

    // Step 2: DL FC Update (FLIT-mode optimized FC signaling)
    s_fc = pcie_gen5_6_dl_fc_update_seq::type_id::create("s_fc");
    start_dl_seq(s_fc);

    // Step 3: Additional FLIT data bursts
    assert(std::randomize(burst_count) with {
      burst_count inside {[cfg.flit_burst_count_min : cfg.flit_burst_count_max]};
    });
    repeat (burst_count) begin
      s_flit = pcie_gen5_6_flit_burst_seq::type_id::create("s_flit");
      start_pipe_seq(s_flit);
    end

    `uvm_info(get_type_name(), "FLIT MODE VSEQ COMPLETE", UVM_LOW)
    super.post_body();
  endtask
endclass : pcie_gen5_6_flit_mode_vseq

`endif



























































































































