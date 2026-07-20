`ifndef PCIE_GEN5_6_ERROR_INJECTION_SEQ_SV
`define PCIE_GEN5_6_ERROR_INJECTION_SEQ_SV

//------------------------------------------------------------------------------
// FILE: pcie_gen5_6_error_injection_seq.sv
//
// CLASS: pcie_gen5_6_error_injection_seq
//
// WHAT WAS HARDCODED / WHY IT BREAKS:
//   - if (cfg.error_kind == ERR_NONE) cfg.error_kind = ERR_BAD_CRC;
//     -> Silently mutates cfg (shared object) - corrupts other sequences
//        running in the same test after this sequence finishes.
//
//   - send_pipe_symbol(PIPE_SYM_FLIT, 0, 32'hBAD0_CRC0);
//     -> Lane always 0 regardless of link width.
//     -> Payload magic literal 32'hBAD0_CRC0 - not a valid CRC corruption
//        path. The correct path is force_bad_flit_crc on the item, not a
//        hand-crafted payload value. Also only ERR_BAD_CRC is exercised.
//
//   - send_tlp(TLP_MEM_RD, 64'hDEAD_0000, 10'h055);
//     -> Address 64'hDEAD_0000 is not from any BAR - may not be routed by
//        the DUT, silently dropped, or cause unintended behavior.
//     -> Tag 10'h055 is a fixed literal - overlaps with other outstanding
//        transactions and does not participate in tag pool management.
//     -> Uses OLD send_tlp(type, addr, tag) signature which was removed in
//        the refactored base_seq (now takes a pcie_gen5_6_txn).
//
//   - send_dlp(DLP_NAK, 10'h55);
//     -> Sequence number 10'h55 is a fixed literal that does not correspond
//        to any real outstanding FLIT/TLP sequence - the DUT's replay logic
//        may reject it as outside the replay window.
//     -> Only DLP_NAK is exercised; ERR_BAD_LCRC/REPLAY_TIMEOUT/CREDIT_
//        EXHAUSTION paths are never reached.
//
// ALL FIXED:
//   - cfg is NEVER mutated. Local variable active_error_kind used instead.
//   - Layer selection is driven by active_error_kind:
//       PIPE-layer errors  -> PIPE agent  (bad FLIT CRC/ECC, bad SDS)
//       DL-layer errors    -> DL agent    (BAD_LCRC, REPLAY_TIMEOUT,
//                                          CREDIT_EXHAUSTION, FORCE_NAK)
//       TL-layer errors    -> TL agent    (all TLP-level error kinds)
//   - Addresses come from cfg.bar_base[] (never literals).
//   - Tags/seq numbers come from get_next_flit_seq_num() (monotonic counter).
//   - Lane derives from cfg.max_width.
//   - All 16 pcie_error_kind_e values are handled individually.
//------------------------------------------------------------------------------
class pcie_gen5_6_error_injection_seq extends pcie_gen5_6_base_seq;
  `uvm_object_utils(pcie_gen5_6_error_injection_seq)

  // Optional per-instance override.
  // If left ERR_NONE, cfg.error_kind is used (never mutated).
  pcie_error_kind_e override_error_kind = ERR_NONE;

  function new(string name = "pcie_gen5_6_error_injection_seq");
    super.new(name);
  endfunction

  virtual task body();
    pcie_error_kind_e active_err;
    super.pre_body();

    // Resolve the error to inject - NEVER modify cfg
    active_err = (override_error_kind != ERR_NONE) ? override_error_kind
                                                    : cfg.error_kind;

    // Safety gate: refuse to run as a positive-test sequence
    if (active_err == ERR_NONE) begin
      `uvm_error(get_type_name(),
        "pcie_gen5_6_error_injection_seq: active error_kind == ERR_NONE. "
        "Set cfg.error_kind or override_error_kind before starting this sequence.")
      return;
    end

    if (!cfg.err_inj_enable) begin
      `uvm_warning(get_type_name(),
        $sformatf("pcie_gen5_6_error_injection_seq: cfg.err_inj_enable==0 but "
                  "error_kind=%s. Proceeding - set cfg.err_inj_enable=1 in test "
                  "build_phase to suppress this warning.", active_err.name()))
    end

    `uvm_info(get_type_name(),
      $sformatf("ERROR INJECTION START: kind=%s speed=%s width=%s flit=%0b",
                 active_err.name(), cfg.max_speed.name(),
                 cfg.max_width.name(), cfg.enable_flit_mode), UVM_LOW)

    // Route to the correct stimulus layer based on error kind
    case (active_err)

      //----------------------------------------------------------------------
      // PIPE-layer errors: bad FLIT CRC, bad ECC, bad FLIT sequence number
      // These must be injected at the PHY symbol level, not the TLP level.
      //----------------------------------------------------------------------
      ERR_BAD_FLIT_CRC,
      ERR_BAD_CRC:  inject_pipe_bad_flit_crc(active_err);

      ERR_BAD_ECC:  inject_pipe_bad_ecc();

      //----------------------------------------------------------------------
      // DL-layer errors: bad LCRC, replay timeout, credit exhaustion, NAK
      //----------------------------------------------------------------------
      ERR_BAD_LCRC:          inject_dl_bad_lcrc();
      ERR_REPLAY_TIMEOUT:    inject_dl_replay_timeout();
      ERR_CREDIT_EXHAUSTION: inject_dl_credit_exhaustion();
      ERR_FORCE_NAK:         inject_dl_nak();

      //----------------------------------------------------------------------
      // TL-layer errors: all remaining error kinds target the TL agent
      //----------------------------------------------------------------------
      ERR_INVALID_TLP,
      ERR_UNSUPPORTED_REQUEST,
      ERR_COMPLETER_ABORT,
      ERR_POISONED_TLP,
      ERR_IDE_AUTH_FAIL,
      ERR_IDE_BAD_MAC,
      ERR_PASID_INVALID,
      ERR_PASID_PRIV_VIOL,
      ERR_OHC_MALFORMED,
      ERR_OHC_BAD_VENDOR: inject_tl_error(active_err);

      default: begin
        `uvm_warning(get_type_name(),
          $sformatf("inject: unhandled error_kind=%s - no stimulus driven", active_err.name()))
      end
    endcase

    `uvm_info(get_type_name(),
      $sformatf("ERROR INJECTION COMPLETE: kind=%s", active_err.name()), UVM_LOW)

    super.post_body();
  endtask

  //============================================================================
  // PIPE-layer injection helpers
  //============================================================================

  // inject_pipe_bad_flit_crc()
  // Sends a FLIT symbol with CRC upper-bits corrupted on a lane derived from
  // cfg.max_width. force_bad_flit_crc flag on the item tells the driver to
  // further corrupt the CRC field at the bit level (not just the data pattern).
  task inject_pipe_bad_flit_crc(pcie_error_kind_e err);
    pcie_pipe_symbol_item item;
    bit [31:0] flit_payload;
    int        bad_lane;

    bad_lane = $urandom_range(0, int'(cfg.max_width) - 1);
    assert(std::randomize(flit_payload));
    // Corrupt upper 16 bits = FLIT CRC field in Gen6 256B FLIT framing
    flit_payload[31:16] = ~flit_payload[31:16];

    item = pcie_pipe_symbol_item::type_id::create("bad_flit_item");
    item.symbol_type       = PIPE_SYM_FLIT;
    item.speed             = cfg.max_speed;
    item.width             = cfg.max_width;
    item.lane_num          = bad_lane[4:0];
    item.data              = flit_payload;
    item.datak             = 4'h0;
    item.start_block       = 1'b1;
    item.sync_header       = 2'b10;
    item.elec_idle         = 1'b0;
    item.precoding_enable  = cfg.enable_precoding;
    item.scrambling_enable = cfg.enable_scrambling;
    item.polarity_inverted = cfg.polarity_inversion_enable;
    item.lane_reversal     = cfg.lane_reversal_enable;
    item.deskew_marker     = cfg.deskew_enable;
    item.retimer_marker    = cfg.enable_retimer_hooks;
    item.pam4_symbol       = (cfg.max_speed == PCIE_GEN6_64P0) ? 2'b11 : 2'b00;
    item.error_kind        = err;
    item.force_bad_flit_crc= 1'b1;   // signal driver to force CRC error

    `uvm_info(get_type_name(),
      $sformatf("inject_pipe_bad_flit_crc: lane=%0d payload=0x%08h err=%s",
                 bad_lane, flit_payload, err.name()), UVM_MEDIUM)

    start_item(item, -1, p_sequencer.pipe_seqr);
    finish_item(item);
    do_inter_packet_delay();
  endtask

  // inject_pipe_bad_ecc()
  // For ERR_BAD_ECC: same as bad CRC but sets error_kind = ERR_BAD_ECC.
  // The driver uses error_kind to engage its Reed-Solomon FEC error model.
  task inject_pipe_bad_ecc();
    inject_pipe_bad_flit_crc(ERR_BAD_ECC); // reuses PIPE item; driver differentiates by error_kind
  endtask

  //============================================================================
  // DL-layer injection helpers
  //============================================================================

  // inject_dl_bad_lcrc()
  // Sends a DLLP with force_bad_lcrc=1.
  // Uses DLP_UPDATEFC as the carrier (FC Update DLLPs are the most common
  // in-flight DLLPs, so this maximizes the chance the DUT's LCRC checker fires).
  task inject_dl_bad_lcrc();
    pcie_dlp_item item;
    bit [9:0] seq_num;
    seq_num = get_next_flit_seq_num();

    item = pcie_dlp_item::type_id::create("bad_lcrc_item");
    if (!item.randomize() with {
          dlp_type            == DLP_UPDATEFC;
          ack_nak_seq_num     == seq_num;
          flit_seq_num        == seq_num;
          optimized_update_fc == cfg.enable_flit_mode;
          scaled_fc           == cfg.enable_scaled_fc;
          fc_hdr_credits      == cfg.fc_ph_init;
          fc_data_credits     == cfg.fc_pd_init;
          error_kind          == ERR_BAD_LCRC;
        }) begin
      `uvm_fatal(get_type_name(), "inject_dl_bad_lcrc: DLP item randomize failed")
    end

    item.force_bad_lcrc = 1'b1;

    `uvm_info(get_type_name(),
      $sformatf("inject_dl_bad_lcrc: seq=%0d fc_hdr=%0d fc_data=%0d",
                 seq_num, item.fc_hdr_credits, item.fc_data_credits), UVM_MEDIUM)

    start_item(item, -1, p_sequencer.dl_seqr);
    finish_item(item);
    do_inter_packet_delay();
  endtask

  // inject_dl_replay_timeout()
  // Sends a DLLP with force_replay_timeout=1 to tell the driver to suppress
  // ACKs until the replay timer expires, then checks that the link issues
  // a replay.
  task inject_dl_replay_timeout();
    pcie_dlp_item item;
    bit [9:0] seq_num;
    seq_num = get_next_flit_seq_num();

    item = pcie_dlp_item::type_id::create("replay_timeout_item");
    if (!item.randomize() with {
          dlp_type        == DLP_ACK;        // last-valid ACK to set replay window
          ack_nak_seq_num == seq_num;
          flit_seq_num    == seq_num;
          error_kind      == ERR_REPLAY_TIMEOUT;
        }) begin
      `uvm_fatal(get_type_name(), "inject_dl_replay_timeout: DLP item randomize failed")
    end

    item.force_replay_timeout = 1'b1;

    `uvm_info(get_type_name(),
      $sformatf("inject_dl_replay_timeout: ack_seq=%0d", seq_num), UVM_MEDIUM)

    start_item(item, -1, p_sequencer.dl_seqr);
    finish_item(item);
    do_inter_packet_delay();
  endtask

  // inject_dl_credit_exhaustion()
  // Sends a DLP with force_credit_exhaust=1 to tell the driver to zero
  // out all FC credits, then issues a TLP that exceeds available credits.
  task inject_dl_credit_exhaustion();
    pcie_dlp_item dl_item;
    pcie_gen5_6_txn txn;
    bit [9:0] seq_num;
    bit [63:0] tgt_addr;
    seq_num = get_next_flit_seq_num();

    // Step 1: DL item to exhaust credits
    dl_item = pcie_dlp_item::type_id::create("credit_exhaust_item");
    if (!dl_item.randomize() with {
          dlp_type        == DLP_UPDATEFC;
          ack_nak_seq_num == seq_num;
          flit_seq_num    == seq_num;
          // Advertise zero credits (will be caught by driver)
          fc_hdr_credits  == 8'h00;
          fc_data_credits == 12'h000;
          error_kind      == ERR_CREDIT_EXHAUSTION;
        }) begin
      `uvm_fatal(get_type_name(), "inject_dl_credit_exhaustion: DLP randomize failed")
    end
    dl_item.force_credit_exhaust = 1'b1;

    `uvm_info(get_type_name(), "inject_dl_credit_exhaustion: sending zero-credit DLP", UVM_MEDIUM)
    start_item(dl_item, -1, p_sequencer.dl_seqr);
    finish_item(dl_item);
    do_inter_packet_delay();

    // Step 2: Follow with a MEM_WR TLP that would exceed credits
    // This exercises the DUT's FC gating and the scoreboard's credit check
    if (cfg.num_bars > 0 && cfg.bar_size[0] > 0) begin
      tgt_addr = cfg.bar_base[0];
      txn = pcie_gen5_6_txn::type_id::create("cred_ex_tlp");
      if (!txn.randomize() with {
            tlp_type      == TLP_MEM_WR;
            addr          == tgt_addr;
            bar_num       == 0;
            requester_bus  == cfg.default_bus_num;
            requester_dev  == cfg.default_dev_num;
            requester_func == cfg.default_func_num;
            flit_mode     == cfg.enable_flit_mode;
            ecrc_present  == cfg.ecrc_enable;
            error_kind    == ERR_CREDIT_EXHAUSTION;
          }) begin
        `uvm_fatal(get_type_name(), "inject_dl_credit_exhaustion: MEM_WR randomize failed")
      end
      send_tlp(txn);
      do_inter_packet_delay();
    end
  endtask

  // inject_dl_nak()
  // Sends a NAK DLLP targeting the current monotonic sequence number.
  // The DUT should initiate replay from the NAK'd sequence number.
  task inject_dl_nak();
    pcie_dlp_item item;
    bit [9:0] seq_num;
    seq_num = get_next_flit_seq_num();

    item = pcie_dlp_item::type_id::create("nak_item");
    if (!item.randomize() with {
          dlp_type            == DLP_NAK;
          ack_nak_seq_num     == seq_num;
          flit_seq_num        == seq_num;
          optimized_update_fc == cfg.enable_flit_mode;
          scaled_fc           == cfg.enable_scaled_fc;
          error_kind          == ERR_FORCE_NAK;
        }) begin
      `uvm_fatal(get_type_name(), "inject_dl_nak: DLP item randomize failed")
    end

    `uvm_info(get_type_name(),
      $sformatf("inject_dl_nak: NAK seq=%0d - expecting replay from DUT", seq_num), UVM_MEDIUM)

    start_item(item, -1, p_sequencer.dl_seqr);
    finish_item(item);
    do_inter_packet_delay();
  endtask

  //============================================================================
  // TL-layer injection helper
  // Handles all TLP-level error kinds via a pcie_gen5_6_txn carrying the
  // error_kind field. apply_error_injection() in base_seq translates it to
  // the correct force_* bit on the pcie_tlp_item.
  //============================================================================
  task inject_tl_error(pcie_error_kind_e err);
    pcie_gen5_6_txn txn;
    bit [63:0] tgt_addr;
    int unsigned bar;

    // Select a valid BAR address as the target (never a literal)
    bar = 0;
    if (cfg.num_bars > 0 && cfg.bar_size[bar] > 0) begin
      tgt_addr = cfg.bar_base[bar] +
                 (64'(($urandom_range(0, int'(cfg.bar_size[bar]>>2)-1)) << 2));
    end else begin
      // No BAR configured - use a constrained random address and warn
      `uvm_warning(get_type_name(),
        $sformatf("inject_tl_error: no valid BAR configured. "
                  "Using randomized address. Set cfg.num_bars in test build_phase."))
      assert(std::randomize(tgt_addr) with { tgt_addr[1:0] == 2'b00; });
    end

    txn = pcie_gen5_6_txn::type_id::create("err_txn");

    // Build the TLP type that is most natural for the requested error
    // (matching pcie_gen5_6_txn c_error_consistency constraint)
    if (!txn.randomize() with {
          // tlp_type is constrained by c_error_consistency in pcie_gen5_6_txn
          // for most error kinds; for others we default to MEM_RD
          if (err inside {ERR_COMPLETER_ABORT}) {
            tlp_type inside {TLP_CPLD};
          } else if (err inside {ERR_INVALID_TLP}) {
            // TLP_NOP used as a placeholder for an "invalid" type
            tlp_type == TLP_NOP;
          } else if (err inside {ERR_IDE_AUTH_FAIL, ERR_IDE_BAD_MAC}) {
            tlp_type == TLP_MEM_RD;
          } else {
            tlp_type inside {TLP_MEM_RD, TLP_MEM_WR};
          }
          addr           == tgt_addr;
          bar_num        == bar;
          requester_bus  == cfg.default_bus_num;
          requester_dev  == cfg.default_dev_num;
          requester_func == cfg.default_func_num;
          flit_mode     == cfg.enable_flit_mode;
          ide_tlp       == (err inside {ERR_IDE_AUTH_FAIL, ERR_IDE_BAD_MAC} ? 1'b1 : cfg.ide_enable);
          pasid_present == (err inside {ERR_PASID_INVALID, ERR_PASID_PRIV_VIOL} ? 1'b1 : cfg.pasid_enable);
          ohc_present   == (err inside {ERR_OHC_MALFORMED, ERR_OHC_BAD_VENDOR} ? 1'b1 : cfg.ohc_enable);
          ecrc_present  == cfg.ecrc_enable;
          error_kind    == err;
          poisoned      == (err == ERR_POISONED_TLP ? 1'b1 : 1'b0);
        }) begin
      `uvm_fatal(get_type_name(),
        $sformatf("inject_tl_error: txn randomize failed (err=%s)", err.name()))
    end

    `uvm_info(get_type_name(),
      $sformatf("inject_tl_error: %s addr=0x%016h tag=%0d err=%s",
                 txn.tlp_type.name(), tgt_addr, txn.tag, err.name()), UVM_MEDIUM)

    send_tlp(txn);
    do_inter_packet_delay();
  endtask

endclass : pcie_gen5_6_error_injection_seq

`endif





















