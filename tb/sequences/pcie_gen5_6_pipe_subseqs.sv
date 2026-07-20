`ifndef PCIE_GEN5_6_PIPE_SUBSEQS_SV
`define PCIE_GEN5_6_PIPE_SUBSEQS_SV

//------------------------------------------------------------------------------
// pcie_gen5_6_pipe_subseqs.sv
// Path: ../sequences/pcie_gen5_6_pipe_subseqs.sv
//
// PIPE-layer sub-sequences used by pcie_gen5_6_link_training_seq.
// All run on p_sequencer.pipe_seqr.
//
// Classes:
//   pcie_gen5_6_pipe_ts_seq    - TS1 or TS2 ordered sets (N times)
//   pcie_gen5_6_pipe_eieos_seq - EIEOS ordered set (Gen3+ speed change)
//   pcie_gen5_6_pipe_sds_seq   - SDS + 4 FLITs (FLIT mode entry)
//   pcie_gen5_6_pipe_skp_seq   - SKP ordered sets (L0 clock compensation)
//------------------------------------------------------------------------------

//==============================================================================
// CLASS: pcie_gen5_6_pipe_ts_seq
//==============================================================================
class pcie_gen5_6_pipe_ts_seq extends pcie_gen5_6_base_seq;
  `uvm_object_utils(pcie_gen5_6_pipe_ts_seq)

  pcie_pipe_symbol_e  sym       = PIPE_SYM_TS1;
  int unsigned        count     = 8;
  pcie_link_speed_e   use_speed;
  pcie_link_width_e   use_width;

  function new(string name = "pcie_gen5_6_pipe_ts_seq");
    super.new(name);
  endfunction

  virtual task body();
    pcie_pipe_symbol_item item;
    super.pre_body();

    if (use_speed == pcie_link_speed_e'(0)) use_speed = cfg.max_speed;
    if (use_width == pcie_link_width_e'(0)) use_width = cfg.max_width;

    repeat (count) begin
      item = pcie_pipe_symbol_item::type_id::create("item");
      item.symbol_type       = sym;
      item.speed             = use_speed;
      item.width             = use_width;
      item.lane_num          = 0;
      item.data              = (sym == PIPE_SYM_TS1) ? 32'h1010_1010 : 32'h4545_4545;
      item.datak             = 4'hF;
      item.start_block       = 1'b0;
      item.sync_header       = 2'b01;
      item.elec_idle         = 1'b0;
      item.precoding_enable  = cfg.enable_precoding;
      item.scrambling_enable = cfg.enable_scrambling;
      item.error_kind        = ERR_NONE;
      start_item(item, -1, p_sequencer.pipe_seqr);
      finish_item(item);
    end
  endtask
endclass : pcie_gen5_6_pipe_ts_seq


//==============================================================================
// CLASS: pcie_gen5_6_pipe_eieos_seq
//==============================================================================
class pcie_gen5_6_pipe_eieos_seq extends pcie_gen5_6_base_seq;
  `uvm_object_utils(pcie_gen5_6_pipe_eieos_seq)

  function new(string name = "pcie_gen5_6_pipe_eieos_seq");
    super.new(name);
  endfunction

  virtual task body();
    super.pre_body();
    send_pipe_symbol(PIPE_SYM_EIEOS, 0, 32'h0000_0000);
  endtask
endclass : pcie_gen5_6_pipe_eieos_seq


//==============================================================================
// CLASS: pcie_gen5_6_pipe_sds_seq
//==============================================================================
class pcie_gen5_6_pipe_sds_seq extends pcie_gen5_6_base_seq;
  `uvm_object_utils(pcie_gen5_6_pipe_sds_seq)

  function new(string name = "pcie_gen5_6_pipe_sds_seq");
    super.new(name);
  endfunction

  virtual task body();
    super.pre_body();
    send_pipe_symbol(PIPE_SYM_SDS,  0, 32'h5D5D_5D5D);
    repeat (4) send_pipe_symbol(PIPE_SYM_FLIT, 0, 32'hF17A_0000);
  endtask
endclass : pcie_gen5_6_pipe_sds_seq


//==============================================================================
// CLASS: pcie_gen5_6_pipe_skp_seq
//==============================================================================
class pcie_gen5_6_pipe_skp_seq extends pcie_gen5_6_base_seq;
  `uvm_object_utils(pcie_gen5_6_pipe_skp_seq)

  function new(string name = "pcie_gen5_6_pipe_skp_seq");
    super.new(name);
  endfunction

  virtual task body();
    super.pre_body();
    repeat (cfg.ts_ordered_set_count) begin
      send_pipe_symbol(PIPE_SYM_SKP, 0, 32'hBCBC_BCBC);
    end
  endtask
endclass : pcie_gen5_6_pipe_skp_seq

`endif
