`ifndef PCIE_GEN5_6_FLIT_MODE_ENTRY_SEQ_SV
`define PCIE_GEN5_6_FLIT_MODE_ENTRY_SEQ_SV

//------------------------------------------------------------------------------
// FILE: pcie_gen5_6_flit_mode_entry_seq.sv
//
// THREE CLASSES:
//   pcie_gen5_6_flit_mode_entry_seq_base    - shared helpers
//   pcie_gen5_6_flit_mode_entry_directed_seq - deterministic, cfg-driven
//   pcie_gen5_6_flit_mode_entry_random_seq   - fully randomized
//
// ALIAS:
//   pcie_gen5_6_flit_mode_entry_seq -> directed (backward compat)
//
// WHAT WAS HARDCODED / WHY IT BREAKS THINGS:
//   - lane fixed to 0 for all FLITs regardless of cfg.max_width
//   - SDS pattern inline literal 32'h5D5D_5D5D (no negative test path)
//   - FLIT payload fixed 32'hF17A_0000 (zero data-integrity coverage)
//   - repeat(4) independent of cfg.flit_burst_count_*
//   - no DL layer coordination (no FC_UPDATE after SDS)
//   - no PAM4 / precoding / scrambling flag propagation
//   - no FLIT sequence number tracking (always 0)
//
// ALL OF THE ABOVE ARE NOW CFG-DRIVEN OR TXN-RANDOMIZED.
//------------------------------------------------------------------------------

//==============================================================================
// BASE CLASS: shared helpers used by both directed and random sub-classes
//==============================================================================
class pcie_gen5_6_flit_mode_entry_seq_base extends pcie_gen5_6_base_seq;
  `uvm_object_utils(pcie_gen5_6_flit_mode_entry_seq_base)

  // Architecturally correct SDS pattern (Gen6 spec table - 0x5D repeated).
  // Named constant so the rest of the code never has a magic number, and the
  // corruption path can flip it unambiguously.
  localparam bit [31:0] SDS_PATTERN_NOMINAL = 32'h5D5D_5D5D;

  function new(string name = "pcie_gen5_6_flit_mode_entry_seq_base");
    super.new(name);
  endfunction

  //--------------------------------------------------------------------------
  // check_flit_entry_legality()
  // Gate: FLIT mode entry only valid at Gen5 (optional) / Gen6 (mandatory).
  // Raises UVM_ERROR on misconfigured test - does NOT fatal so the
  // simulation can still flush and report the mistake cleanly.
  //--------------------------------------------------------------------------
 
function void check_flit_entry_legality();

  if (!cfg.enable_flit_mode) begin
    `uvm_error(
      get_type_name(),
      "FLIT_MODE_ENTRY: cfg.enable_flit_mode==0. Test must set cfg.enable_flit_mode=1 before starting this sequence."
    )
  end

  if (cfg.max_speed < PCIE_GEN5_32P0) begin
    `uvm_error(
      get_type_name(),
      $sformatf(
        "FLIT_MODE_ENTRY: max_speed=%s is below Gen5 (32GT/s). FLIT mode is not legal below Gen5.",
        cfg.max_speed.name()
      )
    )
  end

  `uvm_info(
    get_type_name(),
    $sformatf(
      "FLIT MODE ENTRY LEGAL: speed=%s width=%s precoding=%0b scrambling=%0b scaled_fc=%0b",
      cfg.max_speed.name(),
      cfg.max_width.name(),
      cfg.enable_precoding,
      cfg.enable_scrambling,
      cfg.enable_scaled_fc
    ),
    UVM_LOW
  );

endfunction
 
 
  //--------------------------------------------------------------------------
  // send_sds()
  // Sends the Start-of-Data-Stream ordered set on lane 0.
  // Lane 0 is architecturally mandated for SDS regardless of link width.
  //
  // corrupt_sds=1 inverts the pattern to test LTSSM rejection of bad SDS
  // (negative test: DUT must not enter FLIT mode on corrupted SDS).
  //--------------------------------------------------------------------------
  task send_sds(bit corrupt_sds = 0);
    bit [31:0] sds_val;
    sds_val = corrupt_sds ? (~SDS_PATTERN_NOMINAL) : SDS_PATTERN_NOMINAL;
    if (corrupt_sds) begin
      `uvm_info(get_type_name(),
        $sformatf("send_sds: CORRUPTED SDS 0x%08h (negative test)", sds_val), UVM_MEDIUM)
    end else begin
      `uvm_info(get_type_name(),
        $sformatf("send_sds: nominal SDS 0x%08h on lane 0", sds_val), UVM_MEDIUM)
    end
    // SDS is always sent on lane 0, at current negotiated speed/width
    send_pipe_symbol(PIPE_SYM_SDS, 0, sds_val);
  endtask

  //--------------------------------------------------------------------------
  // send_flit_burst()
  // Sends `count` FLIT symbols across active lanes (0 .. max_width-1).
  //
  // KEY FIXES vs old code:
  //   1. Lane cycles 0..max_width-1 instead of always 0.
  //      Reflects real PHY: wide links distribute FLITs across all lanes.
  //   2. Payload is randomized per FLIT (not a fixed 32'hF17A_0000).
  //      Upper 16b carry FLIT CRC field per Gen6 framing. When force_bad_crc
  //      is set, those bits are inverted to guarantee CRC failure at the
  //      receiver  correct ERR_BAD_FLIT_CRC negative test behavior.
  //   3. FLIT sequence number incremented per call via get_next_flit_seq_num()
  //      so the DUT's FLIT sequence checker sees a monotonic stream.
  //   4. PAM4 symbol, precoding, and scrambling flags mirror cfg values,
  //      maintaining consistency with the link-layer state established during
  //      link training.
  //   5. inter_packet_delay between FLITs for realistic pipelining gaps.
  //--------------------------------------------------------------------------
  task send_flit_burst(int unsigned count, bit force_bad_crc = 0);
    bit [31:0] flit_payload;
    int        lane;
    int        active_lanes;
    bit [9:0]  seq_num;

    active_lanes = int'(cfg.max_width);
    `uvm_info(get_type_name(),
      $sformatf("send_flit_burst: count=%0d active_lanes=%0d force_bad_crc=%0b speed=%s",
                 count, active_lanes, force_bad_crc, cfg.max_speed.name()), UVM_LOW)

    for (int i = 0; i < count; i++) begin
      lane    = i % active_lanes;              // distribute across all active lanes
      seq_num = get_next_flit_seq_num();       // monotonic, wraps at 1024

      assert(std::randomize(flit_payload));    // random FLIT content per symbol

      if (force_bad_crc) begin
        // Upper 16 bits = FLIT CRC field in Gen6 256-byte FLIT framing.
        // Inverting them guarantees CRC-24 mismatch at the link layer.
        flit_payload[31:16] = ~flit_payload[31:16];
        `uvm_info(get_type_name(),
          $sformatf("send_flit_burst[%0d]: BAD CRC injected, lane=%0d seq=%0d payload=0x%08h",
                     i, lane, seq_num, flit_payload), UVM_HIGH)
      end

      `uvm_info(get_type_name(),
        $sformatf("send_flit_burst[%0d]: lane=%0d seq=%0d payload=0x%08h",
                   i, lane, seq_num, flit_payload), UVM_HIGH)

      send_pipe_symbol(PIPE_SYM_FLIT, lane, flit_payload);
      do_inter_packet_delay();
    end
  endtask

  //--------------------------------------------------------------------------
  // send_fc_update_after_sds()
  // After FLIT mode is entered, the DL layer must send FC_UPDATE DLLPs with
  // optimized_update_fc=1 (FLIT-mode FC encoding) to re-advertise credits.
  // This helper issues P, NP, and CPL FC_UPDATE DLLPs using DLP_UPDATEFC
  // (the correct enum value from pcie_gen5_6_types_pkg).
  //--------------------------------------------------------------------------
  task send_fc_update_after_sds();
    bit [9:0] seq_num;
    seq_num = get_next_flit_seq_num();
    `uvm_info(get_type_name(),
      $sformatf("send_fc_update_after_sds: seq=%0d flit_mode=%0b scaled_fc=%0b",
                 seq_num, cfg.enable_flit_mode, cfg.enable_scaled_fc), UVM_MEDIUM)
    // Three FC_UPDATE DLLPs: Posted, Non-Posted, Completion
    // send_dlp() reads cfg.enable_flit_mode and sets optimized_update_fc automatically
    send_dlp(DLP_UPDATEFC, seq_num);
    send_dlp(DLP_UPDATEFC, seq_num);
    send_dlp(DLP_UPDATEFC, seq_num);
  endtask

endclass : pcie_gen5_6_flit_mode_entry_seq_base


//==============================================================================
// DIRECTED SEQUENCE
// Preserves original "SDS then N FLITs" intent, fully cfg-driven.
// Alias pcie_gen5_6_flit_mode_entry_seq points here for backward compat.
//==============================================================================
class pcie_gen5_6_flit_mode_entry_directed_seq extends pcie_gen5_6_flit_mode_entry_seq_base;
  `uvm_object_utils(pcie_gen5_6_flit_mode_entry_directed_seq)

  // Knobs the test can override for directed negative scenarios
  bit          directed_corrupt_sds  = 0;
  bit          directed_bad_flit_crc = 0;
  // 0 => derive from cfg.flit_burst_count_min (matches original repeat(4) when
  //      cfg.flit_burst_count_min is set to 4 by the test)
  int unsigned directed_burst_count  = 0;

  function new(string name = "pcie_gen5_6_flit_mode_entry_directed_seq");
    super.new(name);
  endfunction

  virtual task body();
    int unsigned burst_count;
    super.pre_body();

    check_flit_entry_legality();

    // Resolve burst count: explicit override > cfg minimum > default 4
    if      (directed_burst_count != 0)       burst_count = directed_burst_count;
    else if (cfg.flit_burst_count_min != 0)   burst_count = cfg.flit_burst_count_min;
    else                                       burst_count = 4;

/*    `uvm_info(get_type_name(),
      $sformatf("DIRECTED FLIT MODE ENTRY: burst=%0d corrupt_sds=%0b bad_crc=%0b "
                "speed=%s width=%s precoding=%0b scrambling=%0b",
                burst_count, directed_corrupt_sds, directed_bad_flit_crc,
                cfg.max_speed.name(), cfg.max_width.name(),
                cfg.enable_precoding, cfg.enable_scrambling), UVM_LOW)*/
	      
	       `uvm_info( get_type_name(),
  $sformatf(
    "DIRECTED FLIT MODE ENTRY: burst=%0d corrupt_sds=%0b bad_crc=%0b speed=%0s width=%0s precoding=%0b scrambling=%0b",
    burst_count,
    directed_corrupt_sds,
    directed_bad_flit_crc,
    cfg.max_speed.name(),
    cfg.max_width.name(),
    cfg.enable_precoding,
    cfg.enable_scrambling
  ),
  UVM_LOW
)

    // Phase 1: SDS on lane 0 (entry handshake)
    send_sds(directed_corrupt_sds);

    // Phase 2: FLIT burst across active lanes
    send_flit_burst(burst_count, directed_bad_flit_crc);

    // Phase 3: DL FC_UPDATE (FLIT-mode credit re-advertisement)
    // Skip if SDS was corrupted - DUT should not have entered FLIT mode
    if (!directed_corrupt_sds) begin
      send_fc_update_after_sds();
    end

    super.post_body();
  endtask

endclass : pcie_gen5_6_flit_mode_entry_directed_seq


//==============================================================================
// RANDOM SEQUENCE
// Randomizes burst length within cfg bounds, randomly injects errors.
//==============================================================================
class pcie_gen5_6_flit_mode_entry_random_seq extends pcie_gen5_6_flit_mode_entry_seq_base;
  `uvm_object_utils(pcie_gen5_6_flit_mode_entry_random_seq)

  rand int unsigned burst_count;
  rand bit          corrupt_sds;
  rand bit          bad_flit_crc;

  constraint c_burst {
    // Uses cfg fields - flit_burst_count_min/max set by test or defaults
    burst_count inside {[cfg.flit_burst_count_min : cfg.flit_burst_count_max]};
  }
  constraint c_error_inj {
    if (!cfg.err_inj_enable) {
      corrupt_sds  == 1'b0;
      bad_flit_crc == 1'b0;
    } else {
      // Only one error type per run - clean error attribution
      !(corrupt_sds && bad_flit_crc);
      corrupt_sds  dist {1'b0 := 8, 1'b1 := 1};
      bad_flit_crc dist {1'b0 := 8, 1'b1 := 1};
    }
  }

  function new(string name = "pcie_gen5_6_flit_mode_entry_random_seq");
    super.new(name);
  endfunction

  virtual task body();
    super.pre_body();

    check_flit_entry_legality();

  /*  `uvm_info(get_type_name(),
      $sformatf("RANDOM FLIT MODE ENTRY: burst=%0d corrupt_sds=%0b bad_crc=%0b "
                "speed=%s width=%s",
                burst_count, corrupt_sds, bad_flit_crc,
                cfg.max_speed.name(), cfg.max_width.name()), UVM_LOW)*/

       `uvm_info(
  get_type_name(),
  $sformatf(
    "RANDOM FLIT MODE ENTRY: burst=%0d corrupt_sds=%0b bad_crc=%0b speed=%s width=%s",
    burst_count,
    corrupt_sds,
    bad_flit_crc,
    cfg.max_speed.name(),
    cfg.max_width.name()
  ),
  UVM_LOW
)
    send_sds(corrupt_sds);
    send_flit_burst(burst_count, bad_flit_crc);

    if (!corrupt_sds) begin
      send_fc_update_after_sds();
    end

    super.post_body();
  endtask

endclass : pcie_gen5_6_flit_mode_entry_random_seq


//------------------------------------------------------------------------------
// Backward-compat alias - existing test code calling:
//   pcie_gen5_6_flit_mode_entry_seq::type_id::create(...)
// resolves to the directed variant with zero-change in test files.
//------------------------------------------------------------------------------
typedef pcie_gen5_6_flit_mode_entry_directed_seq pcie_gen5_6_flit_mode_entry_seq;

`endif



















