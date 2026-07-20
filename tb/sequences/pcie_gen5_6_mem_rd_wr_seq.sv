`ifndef PCIE_GEN5_6_MEM_RD_WR_SEQ_SV
`define PCIE_GEN5_6_MEM_RD_WR_SEQ_SV

//------------------------------------------------------------------------------
// FILE: pcie_gen5_6_mem_rd_wr_seq.sv
//
// THREE CLASSES:
//   pcie_gen5_6_mem_rd_wr_seq_base      - shared BAR/txn/atomic helpers
//   pcie_gen5_6_mem_rd_wr_directed_seq  - deterministic, cfg-driven
//   pcie_gen5_6_mem_rd_wr_random_seq    - fully randomized
//
// ALIAS:
//   pcie_gen5_6_mem_rd_wr_seq -> directed (backward compat)
//
// WHAT WAS HARDCODED / WHY IT BREAKS:
//   - Base addr 64'h8000_0000 / 64'h8000_1000 : not from BAR config
//   - repeat(8): no scaling for stress vs smoke tests
//   - $urandom_range(0,1023) as TAG arg: bypasses tag pool, wrong field
//   - length_dw not set (used old send_tlp default 1-16 DW)
//   - No TC/VC, IDE, PASID, OHC, ECRC, poison, atomic variation
//   - No EP-to-RC upstream traffic path (agent_mode awareness)
//   - Reads from different page than writes (no data-integrity check)
//
// ALL FIXED: every address, length, tag, BE, and optional field derives
// from cfg + txn randomization. EP-mode uses cfg.bar_base as the TARGET
// (RC-side memory), not a fixed literal.
//------------------------------------------------------------------------------

//==============================================================================
// BASE CLASS
//==============================================================================
class pcie_gen5_6_mem_rd_wr_seq_base extends pcie_gen5_6_base_seq;
  `uvm_object_utils(pcie_gen5_6_mem_rd_wr_seq_base)

  function new(string name = "pcie_gen5_6_mem_rd_wr_seq_base");
    super.new(name);
  endfunction

  //--------------------------------------------------------------------------
  // pick_bar_offset()
  // Returns a randomized, DW-aligned address within BAR[bar]'s aperture.
  // Replaces fixed 64'h8000_0000 literals with genuinely BAR-derived addrs.
  // Works in both RC mode (BAR = EP's aperture) and EP mode (BAR = RC mem).
  //--------------------------------------------------------------------------
  function bit [63:0] pick_bar_offset(int unsigned bar);
    bit [63:0] base, size, offset;

if (bar >= cfg.num_bars || cfg.bar_size[bar] == 0) begin
  `uvm_error(
    get_type_name(),
    $sformatf(
      "pick_bar_offset: BAR%0d not configured (num_bars=%0d size=0x%0h). Test must set cfg.num_bars and cfg.bar_size[%0d] before running this sequence.",
      bar,
      cfg.num_bars,
      cfg.bar_size[bar],
      bar
    )
  )

  return cfg.bar_base[bar];
end
  
  
  
  
  
    /*  if (bar >= cfg.num_bars || cfg.bar_size[bar] == 0) begin
      `uvm_error(get_type_name(),
        $sformatf("pick_bar_offset: BAR%0d not configured (num_bars=%0d size=0x%0h). "
                  "Test must set cfg.num_bars and cfg.bar_size[%0d] before running this sequence.",
                  bar, cfg.num_bars, cfg.bar_size[bar], bar))
   $sformatf(
  {
    "pick_bar_offset: BAR%0d not configured (num_bars=%0d size=0x%0h). ",
    "Test must set cfg.num_bars and cfg.bar_size[%0d] before running this sequence."
  },
  bar,
  cfg.num_bars,
  cfg.bar_size[bar],
  bar)

      return cfg.bar_base[bar]; // return base to avoid sim crash; error already flagged
    end*/

    base = cfg.bar_base[bar];
    size = cfg.bar_size[bar];

    assert(std::randomize(offset) with {
      offset < size;
      offset[1:0] == 2'b00;   // DW-aligned
    });

    return (base + offset);
  endfunction

  //--------------------------------------------------------------------------
  // pick_random_enabled_bar()
  // Selects a random BAR index among those with non-zero size.
  // Used by random sequence to spread traffic across all configured BARs.
  //--------------------------------------------------------------------------
  function int unsigned pick_random_enabled_bar();
    int unsigned candidates[$];
    int unsigned chosen;

    for (int unsigned b = 0; b < 6; b++) begin
      if (b < cfg.num_bars && cfg.bar_size[b] > 0)
        candidates.push_back(b);
    end

    if (candidates.size() == 0) begin
     /* `uvm_fatal(get_type_name(),
        "pick_random_enabled_bar: no BARs configured with non-zero size. "
        "Set cfg.num_bars >= 1 and cfg.bar_size[0..N] in the test build_phase.")*/
    `uvm_fatal(get_type_name(),
  "pick_random_enabled_bar: no BARs configured with non-zero size. Set cfg.num_bars >= 1 and cfg.bar_size[0..N] in the test build_phase.")


    end

    chosen = candidates[$urandom_range(0, candidates.size()-1)];
    return chosen;
  endfunction

  //--------------------------------------------------------------------------
  // do_mem_write_read_pair()
  // Issues a MEM_WR followed by a MEM_RD.
  //
  // same_address=1 : read targets the exact same address as the write
  //                  (data-integrity scenario - scoreboard can verify payload)
  // same_address=0 : independent addresses within the BAR
  //
  // All txn fields (TC/VC, attrs, IDE, PASID, OHC, ECRC, length, BEs) are
  // randomized within cfg constraints via pcie_gen5_6_txn.  The write and
  // read can independently carry different error kinds.
  //
  // EP-mode awareness: in PCIE_AGENT_EP mode the requester BDF is the EP's
  // own (cfg.default_bus/dev/func) and the target address is in host memory.
  //--------------------------------------------------------------------------
  task do_mem_write_read_pair(int unsigned      bar,
                               bit               same_address,
                               pcie_error_kind_e wr_err = ERR_NONE,
                               pcie_error_kind_e rd_err = ERR_NONE);
    pcie_gen5_6_txn wr_txn, rd_txn;
    bit [63:0]      wr_addr, rd_addr;

    wr_addr = pick_bar_offset(bar);
    rd_addr = same_address ? wr_addr : pick_bar_offset(bar);

    //--- Memory Write ---
    wr_txn = pcie_gen5_6_txn::type_id::create("wr_txn");
    if (!wr_txn.randomize() with {
          tlp_type       == TLP_MEM_WR;
          addr           == wr_addr;
          bar_num        == bar;
          // Requester context from cfg (works for both RC and EP mode)
          requester_bus  == cfg.default_bus_num;
          requester_dev  == cfg.default_dev_num;
          requester_func == cfg.default_func_num;
          // Feature flags all from cfg - no hardcoding
          flit_mode     == cfg.enable_flit_mode;
          ide_tlp       == cfg.ide_enable;
          pasid_present == cfg.pasid_enable;
          ohc_present   == cfg.ohc_enable;
          ecrc_present  == cfg.ecrc_enable;
          error_kind    == wr_err;
          // Keep access within BAR aperture
          (addr + (length_dw * 4)) <= (cfg.bar_base[bar] + cfg.bar_size[bar]);
        }) begin
      `uvm_fatal(get_type_name(),
        $sformatf("do_mem_write_read_pair: MEM_WR randomize failed (bar=%0d addr=0x%0h)", bar, wr_addr))
    end

    check_txn_legality(wr_txn);

    `uvm_info(get_type_name(),
      $sformatf("MEM_WR: bar=%0d addr=0x%016h len_dw=%0d tc=%0d ide=%0b pasid=%0b err=%s",
                 bar, wr_addr, wr_txn.length_dw, wr_txn.tc,
                 wr_txn.ide_tlp, wr_txn.pasid_present, wr_err.name()), UVM_MEDIUM)

    send_tlp(wr_txn);
    do_inter_packet_delay();

    //--- Memory Read ---
    rd_txn = pcie_gen5_6_txn::type_id::create("rd_txn");
    if (!rd_txn.randomize() with {
          tlp_type       == TLP_MEM_RD;
          addr           == rd_addr;
          bar_num        == bar;
          requester_bus  == cfg.default_bus_num;
          requester_dev  == cfg.default_dev_num;
          requester_func == cfg.default_func_num;
          flit_mode     == cfg.enable_flit_mode;
          ide_tlp       == cfg.ide_enable;
          pasid_present == cfg.pasid_enable;
          ohc_present   == cfg.ohc_enable;
          ecrc_present  == cfg.ecrc_enable;
          error_kind    == rd_err;
          (addr + (length_dw * 4)) <= (cfg.bar_base[bar] + cfg.bar_size[bar]);
          // Data-integrity: same length as write so scoreboard can compare
          if (same_address) length_dw == wr_txn.length_dw;
        }) begin
      `uvm_fatal(get_type_name(),
        $sformatf("do_mem_write_read_pair: MEM_RD randomize failed (bar=%0d addr=0x%0h)", bar, rd_addr))
    end

    check_txn_legality(rd_txn);

    `uvm_info(get_type_name(),
      $sformatf("MEM_RD: bar=%0d addr=0x%016h len_dw=%0d same_addr=%0b err=%s",
                 bar, rd_addr, rd_txn.length_dw, same_address, rd_err.name()), UVM_MEDIUM)

    send_tlp(rd_txn);
    do_inter_packet_delay();
  endtask

  //--------------------------------------------------------------------------
  // do_atomic_op()
  // Issues a single AtomicOp TLP (FetchAdd/Swap/CAS) when cfg.atomic_op_enable.
  // Type, operand width (32b/64b/128b), and target address are all randomized.
  //--------------------------------------------------------------------------
  task do_atomic_op(int unsigned bar);
    pcie_gen5_6_txn txn;
    bit [63:0]      a_addr;

    if (!cfg.atomic_op_enable) begin
      `uvm_info(get_type_name(), "do_atomic_op: skipped (cfg.atomic_op_enable==0)", UVM_HIGH)
      return;
    end

    a_addr = pick_bar_offset(bar);
    txn    = pcie_gen5_6_txn::type_id::create("atomic_txn");

    if (!txn.randomize() with {
          tlp_type inside {TLP_ATOMIC_FETCHADD, TLP_ATOMIC_SWAP, TLP_ATOMIC_CAS};
          addr     == a_addr;
          bar_num  == bar;
          requester_bus  == cfg.default_bus_num;
          requester_dev  == cfg.default_dev_num;
          requester_func == cfg.default_func_num;
          flit_mode    == cfg.enable_flit_mode;
          ecrc_present == cfg.ecrc_enable;
          error_kind   == ERR_NONE;
          // AtomicOp must not overrun BAR
          (addr + (length_dw * 4)) <= (cfg.bar_base[bar] + cfg.bar_size[bar]);
        }) begin
      `uvm_fatal(get_type_name(), "do_atomic_op: randomize failed")
    end

    check_txn_legality(txn);

    `uvm_info(get_type_name(),
      $sformatf("ATOMIC: %s bar=%0d addr=0x%016h len_dw=%0d",
                 txn.tlp_type.name(), bar, a_addr, txn.length_dw), UVM_MEDIUM)

    send_tlp(txn);
    do_inter_packet_delay();
  endtask

endclass : pcie_gen5_6_mem_rd_wr_seq_base


//==============================================================================
// DIRECTED SEQUENCE
// N write/read pairs to a single BAR, all cfg-driven, deterministic.
// Defaults preserve original 8-pair / BAR0 behavior when cfg is default.
//==============================================================================
class pcie_gen5_6_mem_rd_wr_directed_seq extends pcie_gen5_6_mem_rd_wr_seq_base;
  `uvm_object_utils(pcie_gen5_6_mem_rd_wr_directed_seq)

  // Overridable knobs - test sets these directly or leaves at defaults
  int unsigned directed_pair_count       = 0;    // 0 => defaults to 8
  int unsigned directed_bar              = 0;    // default BAR0
  bit          directed_same_address     = 1;    // read-back same addr (data integrity)
  pcie_error_kind_e directed_error_last  = ERR_NONE; // error on final pair only

  function new(string name = "pcie_gen5_6_mem_rd_wr_directed_seq");
    super.new(name);
  endfunction

  virtual task body();
    int unsigned pair_count;
    super.pre_body();

    // Validate BAR is configured
    if (cfg.num_bars == 0 || directed_bar >= cfg.num_bars ||
        cfg.bar_size[directed_bar] == 0) begin
      `uvm_error(get_type_name(),
        $sformatf("DIRECTED mem_rd_wr: BAR%0d not configured. "
                  "Set cfg.num_bars=%0d, cfg.bar_type[%0d], cfg.bar_base[%0d], "
                  "cfg.bar_size[%0d] in test build_phase.",
                  directed_bar, directed_bar+1, directed_bar, directed_bar, directed_bar))
      return;
    end

    pair_count = (directed_pair_count != 0) ? directed_pair_count : 8;

    `uvm_info(get_type_name(),
      $sformatf("DIRECTED MEM RD/WR: pairs=%0d bar=%0d base=0x%016h size=0x%016h "
                "same_addr=%0b mode=%s flit=%0b err_last=%s",
                pair_count, directed_bar,
                cfg.bar_base[directed_bar], cfg.bar_size[directed_bar],
                directed_same_address, cfg.agent_mode.name(),
                cfg.enable_flit_mode, directed_error_last.name()), UVM_LOW)

    for (int unsigned i = 0; i < pair_count; i++) begin
      pcie_error_kind_e this_rd_err;
      // Inject error only on the last pair (clear, attributable negative test)
      this_rd_err = (i == pair_count-1) ? directed_error_last : ERR_NONE;
      do_mem_write_read_pair(
        .bar(directed_bar),
        .same_address(directed_same_address),
        .wr_err(ERR_NONE),
        .rd_err(this_rd_err));
    end

    super.post_body();
  endtask

endclass : pcie_gen5_6_mem_rd_wr_directed_seq


//==============================================================================
// RANDOM SEQUENCE
// Randomizes: pair count, target BAR, same/different address, AtomicOps,
// per-pair error injection (weighted toward legal traffic).
//==============================================================================
class pcie_gen5_6_mem_rd_wr_random_seq extends pcie_gen5_6_mem_rd_wr_seq_base;
  `uvm_object_utils(pcie_gen5_6_mem_rd_wr_random_seq)

  rand int unsigned num_pairs;

  constraint c_num_pairs {
    num_pairs inside {[4:64]};
  }

  function new(string name = "pcie_gen5_6_mem_rd_wr_random_seq");
    super.new(name);
  endfunction

  virtual task body();
    int unsigned      bar;
    bit               same_addr;
    pcie_error_kind_e wr_err, rd_err, cand;

    super.pre_body();

    `uvm_info(get_type_name(),
      $sformatf("RANDOM MEM RD/WR: num_pairs=%0d mode=%s flit=%0b atomic=%0b err_inj=%0b",
                 num_pairs, cfg.agent_mode.name(), cfg.enable_flit_mode,
                 cfg.atomic_op_enable, cfg.err_inj_enable), UVM_LOW)

    repeat (num_pairs) begin
      // Pick a random enabled BAR for each pair
      bar = pick_random_enabled_bar();

      // Randomly decide data-integrity check vs. independent addresses
      assert(std::randomize(same_addr) with { same_addr dist {1'b1 := 6, 1'b0 := 4}; });

      wr_err = ERR_NONE;
      rd_err = ERR_NONE;

      if (cfg.err_inj_enable) begin
        // Choose a random error from the full pcie_error_kind_e menu
        assert(std::randomize(cand) with {
          cand inside {
            ERR_NONE, ERR_BAD_LCRC, ERR_BAD_ECRC,
            ERR_POISONED_TLP, ERR_CREDIT_EXHAUSTION,
            ERR_COMPLETER_ABORT, ERR_UNSUPPORTED_REQUEST,
            ERR_REPLAY_TIMEOUT, ERR_IDE_AUTH_FAIL, ERR_IDE_BAD_MAC,
            ERR_PASID_INVALID, ERR_PASID_PRIV_VIOL,
            ERR_OHC_MALFORMED, ERR_OHC_BAD_VENDOR
          };
          // Weight toward clean traffic (60% chance of ERR_NONE)
          cand dist {
            ERR_NONE             := 60,
            ERR_BAD_LCRC         := 4,
            ERR_BAD_ECRC         := 4,
            ERR_POISONED_TLP     := 4,
            ERR_CREDIT_EXHAUSTION:= 4,
            ERR_COMPLETER_ABORT  := 4,
            ERR_UNSUPPORTED_REQUEST := 4,
            ERR_REPLAY_TIMEOUT   := 4,
            ERR_IDE_AUTH_FAIL    := 2,
            ERR_IDE_BAD_MAC      := 2,
            ERR_PASID_INVALID    := 2,
            ERR_PASID_PRIV_VIOL  := 2,
            ERR_OHC_MALFORMED    := 2,
            ERR_OHC_BAD_VENDOR   := 2
          };
        });

        // Gate feature-specific errors against their cfg enables
        if (cand inside {ERR_IDE_AUTH_FAIL, ERR_IDE_BAD_MAC}      && !cfg.ide_enable)    cand = ERR_NONE;
        if (cand inside {ERR_PASID_INVALID, ERR_PASID_PRIV_VIOL}  && !cfg.pasid_enable)  cand = ERR_NONE;
        if (cand inside {ERR_OHC_MALFORMED, ERR_OHC_BAD_VENDOR}   && !cfg.ohc_enable)    cand = ERR_NONE;
        if (cand == ERR_REPLAY_TIMEOUT                              && !cfg.replay_enable) cand = ERR_NONE;

        // Randomly assign error to write or read leg, not both
        if ($urandom_range(0, 1)) wr_err = cand;
        else                      rd_err = cand;
      end

      do_mem_write_read_pair(.bar(bar), .same_address(same_addr),
                              .wr_err(wr_err), .rd_err(rd_err));

      // Occasionally add an AtomicOp when the feature is enabled
      if (cfg.atomic_op_enable && ($urandom_range(0, 3) == 0)) begin
        do_atomic_op(bar);
      end
    end

    super.post_body();
  endtask

endclass : pcie_gen5_6_mem_rd_wr_random_seq


//------------------------------------------------------------------------------
// Backward-compat alias
//------------------------------------------------------------------------------
typedef pcie_gen5_6_mem_rd_wr_directed_seq pcie_gen5_6_mem_rd_wr_seq;

`endif





















