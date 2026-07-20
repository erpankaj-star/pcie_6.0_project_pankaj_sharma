`ifndef PCIE_GEN5_6_BASE_SEQ_SV
`define PCIE_GEN5_6_BASE_SEQ_SV

class pcie_gen5_6_base_seq extends uvm_sequence;
  `uvm_object_utils(pcie_gen5_6_base_seq)
  `uvm_declare_p_sequencer(pcie_gen5_6_virtual_sequencer)

  pcie_gen5_6_cfg cfg;
  int unsigned flit_seq_counter = 0;

  function new(string name = "pcie_gen5_6_base_seq");
    super.new(name);
  endfunction

  function int unsigned get_next_flit_seq_num();
    get_next_flit_seq_num = flit_seq_counter;
    flit_seq_counter = (flit_seq_counter + 1) % 1024;
  endfunction

  virtual task pre_body();
    if (p_sequencer != null) begin
      cfg = p_sequencer.cfg;
    end
    if (cfg == null) begin
      cfg = pcie_gen5_6_cfg::type_id::create("cfg");
    end
  endtask

  task send_pipe_symbol(pcie_pipe_symbol_e sym, int lane = 0, bit [31:0] data = 32'h0);
    pcie_pipe_symbol_item item;
    item = pcie_pipe_symbol_item::type_id::create("item");
    item.symbol_type       = sym;
    item.speed             = cfg.max_speed;
    item.width             = cfg.max_width;
    item.lane_num          = lane[4:0];
    item.data              = data;
    item.datak             = (sym inside {PIPE_SYM_TS1, PIPE_SYM_TS2, PIPE_SYM_SKP, PIPE_SYM_SDS, PIPE_SYM_EIOS, PIPE_SYM_EIEOS}) ? 4'hF : 4'h0;
    item.start_block       = (sym inside {PIPE_SYM_SDS, PIPE_SYM_FLIT});
    item.sync_header       = (sym == PIPE_SYM_FLIT) ? 2'b10 : 2'b01;
    item.elec_idle         = (sym == PIPE_SYM_IDLE);
    item.polarity_inverted = cfg.polarity_inversion_enable;
    item.lane_reversal     = cfg.lane_reversal_enable;
    item.deskew_marker     = cfg.deskew_enable;
    item.retimer_marker    = cfg.enable_retimer_hooks;
    item.pam4_symbol       = (cfg.max_speed == PCIE_GEN6_64P0) ? 2'b11 : 2'b00;
    item.precoding_enable  = cfg.enable_precoding;
    item.scrambling_enable = cfg.enable_scrambling;
    item.error_kind        = cfg.error_kind;
    start_item(item, -1, p_sequencer.pipe_seqr);
    finish_item(item);
  endtask

  task send_tlp(pcie_tlp_type_e typ, bit [63:0] addr = 64'h1000, bit [9:0] tag = 0);
    pcie_tlp_item item;
    item = pcie_tlp_item::type_id::create("item");
    assert(item.randomize() with {
      tlp_type == typ;
      this.addr == addr;
      this.tag == tag;
      length_dw inside {[1:16]};
      first_be == 4'hF;
    });
    item.error_kind = cfg.error_kind;
    start_item(item, -1, p_sequencer.tl_seqr);
    finish_item(item);
  endtask

  task send_dlp(pcie_dlp_type_e typ, bit [9:0] seq = 0);
    pcie_dlp_item item;
    item = pcie_dlp_item::type_id::create("item");
    assert(item.randomize() with {
      dlp_type == typ;
      ack_nak_seq_num == seq;
      flit_seq_num == seq;
      optimized_update_fc == cfg.enable_flit_mode;
      scaled_fc == cfg.enable_scaled_fc;
    });
    start_item(item, -1, p_sequencer.dl_seqr);
    finish_item(item);
  endtask
   task do_inter_packet_delay();
   #(10ns);
   endtask
endclass : pcie_gen5_6_base_seq

`endif

