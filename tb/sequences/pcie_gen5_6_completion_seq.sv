`ifndef PCIE_GEN5_6_COMPLETION_SEQ_SV
`define PCIE_GEN5_6_COMPLETION_SEQ_SV

//------------------------------------------------------------------------------
// FILE: pcie_gen5_6_completion_seq.sv
//
// TWO CLASSES:
//   pcie_gen5_6_completion_directed_seq - deterministic, cfg-driven
//   pcie_gen5_6_completion_random_seq   - randomized count, status, errors
//
// ALIAS:
//   pcie_gen5_6_completion_seq -> directed (backward compat)
//
// WHAT WAS HARDCODED / WHY IT BREAKS:
//   - repeat(4): fixed, cannot scale
//   - Tag t = $urandom_range(0,1023): not tracked, not pool-managed
//   - 64'h9000_0000 + (t<<2): not from BAR, not legal address derivation
//   - send_tlp(TLP_CPLD, 64'h0, t): CPLD second arg was "addr" (wrong:
//     completions do not carry a target address), third arg was the tag
//     but positional arg was passing it as "length", so the completion
//     length was unpredictably 0..1023 DW
//   - No cpl_status variation (always SC by implicit default)
//   - No cpl_byte_count / cpl_lower_addr variation
//   - No ECRC, IDE, FLIT mode propagation on completions
//   - No CPL (no-data) scenario - only CPLD was issued
//
// ALL FIXED: tag comes from txn constraint pool; completion address field
// is correctly left as 0 (not a target address); cpl_status, byte_count,
// and lower_addr are txn-randomized; IDE/ECRC/FLIT flags from cfg.
//------------------------------------------------------------------------------

//==============================================================================
// DIRECTED SEQUENCE
// N MEM_RD + matching CPLD pairs. Count, status, and errors all cfg-driven.
//==============================================================================
class pcie_gen5_6_completion_directed_seq extends pcie_gen5_6_base_seq;
  `uvm_object_utils(pcie_gen5_6_completion_directed_seq)

  // Knobs
  int unsigned      directed_pair_count   = 0;     // 0 => defaults to 4
  int unsigned      directed_bar          = 0;     // BAR to target for reads
  pcie_cpl_status_e directed_cpl_status   = CPL_SC; // SC = Successful Completion
  pcie_error_kind_e directed_rd_error     = ERR_NONE;
  pcie_error_kind_e directed_cpl_error    = ERR_NONE;
  // set 1 to also emit a CPL (no data) before the CPLD (split-completion test)
  bit               directed_emit_cpl_nod = 0;

  function new(string name = "pcie_gen5_6_completion_directed_seq");
    super.new(name);
  endfunction

  virtual task body();
    int unsigned      pair_count;
    pcie_gen5_6_txn   rd_txn, cpl_txn;
    bit [63:0]        rd_addr;
    int unsigned      bar;

    super.pre_body();

    // Validate BAR
    bar = directed_bar;
    if (cfg.num_bars == 0 || bar >= cfg.num_bars || cfg.bar_size[bar] == 0) begin
      `uvm_error(get_type_name(),
        $sformatf("DIRECTED completion: BAR%0d not configured. "
                  "Set cfg.num_bars, cfg.bar_base[%0d], cfg.bar_size[%0d] in test build_phase.",
                  bar, bar, bar))
      return;
    end

    pair_count = (directed_pair_count != 0) ? directed_pair_count : 4;

    `uvm_info(get_type_name(),
      $sformatf("DIRECTED COMPLETION: pairs=%0d bar=%0d cpl_status=%s rd_err=%s cpl_err=%s nod=%0b",
                 pair_count, bar, directed_cpl_status.name(),
                 directed_rd_error.name(), directed_cpl_error.name(),
                 directed_emit_cpl_nod), UVM_LOW)

    for (int unsigned i = 0; i < pair_count; i++) begin

      //--- Step 1: Memory Read (non-posted, generates outstanding tag) ---
      rd_addr = cfg.bar_base[bar] +
                (64'(($urandom_range(0, int'(cfg.bar_size[bar]>>2)-1)) << 2));

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
            error_kind    == directed_rd_error;
            // Keep within BAR
            (addr + (length_dw * 4)) <= (cfg.bar_base[bar] + cfg.bar_size[bar]);
          }) begin
        `uvm_fatal(get_type_name(), "DIRECTED completion: MEM_RD randomize failed")
      end

      check_txn_legality(rd_txn);
      `uvm_info(get_type_name(),
        $sformatf("completion[%0d] MEM_RD: addr=0x%016h len_dw=%0d tag=%0d",
                   i, rd_addr, rd_txn.length_dw, rd_txn.tag), UVM_MEDIUM)
      send_tlp(rd_txn);
      do_inter_packet_delay();

      //--- Step 2a (optional): CPL no-data (split-completion first segment) ---
      if (directed_emit_cpl_nod) begin
        cpl_txn = pcie_gen5_6_txn::type_id::create("cpl_nod_txn");
        if (!cpl_txn.randomize() with {
              tlp_type        == TLP_CPL;
              // Tag must match the outstanding read
              tag             == rd_txn.tag;
              requester_bus   == cfg.default_bus_num;
              requester_dev   == cfg.default_dev_num;
              requester_func  == cfg.default_func_num;
              cpl_status      == directed_cpl_status;
              // CPL (no data): byte_count = remaining bytes; lower_addr from read
              cpl_byte_count  == (rd_txn.length_dw * 4);
              cpl_lower_addr  == rd_addr[6:0];
              flit_mode      == cfg.enable_flit_mode;
              ecrc_present   == cfg.ecrc_enable;
              error_kind     == ERR_NONE;
            }) begin
          `uvm_fatal(get_type_name(), "DIRECTED completion: CPL (no-data) randomize failed")
        end
        check_txn_legality(cpl_txn);
        send_tlp(cpl_txn);
        do_inter_packet_delay();
      end

      //--- Step 2b: CPLD (completion with data) ---
      cpl_txn = pcie_gen5_6_txn::type_id::create("cpld_txn");
      if (!cpl_txn.randomize() with {
            tlp_type        == TLP_CPLD;
            // Tag must match the outstanding MEM_RD
            tag             == rd_txn.tag;
            // Completer BDF mirrors our own cfg identity
            requester_bus   == cfg.default_bus_num;
            requester_dev   == cfg.default_dev_num;
            requester_func  == cfg.default_func_num;
            // Length must match what was requested
            length_dw       == rd_txn.length_dw;
            // Completion fields - status, byte_count, lower_addr
            cpl_status      == directed_cpl_status;
            cpl_byte_count  == (rd_txn.length_dw * 4);
            cpl_lower_addr  == rd_addr[6:0];
            flit_mode      == cfg.enable_flit_mode;
            ide_tlp        == cfg.ide_enable;
            ecrc_present   == cfg.ecrc_enable;
            error_kind     == directed_cpl_error;
          }) begin
        `uvm_fatal(get_type_name(), "DIRECTED completion: CPLD randomize failed")
      end

      check_txn_legality(cpl_txn);
      `uvm_info(get_type_name(),
        $sformatf("completion[%0d] CPLD: tag=%0d len_dw=%0d status=%s byte_cnt=%0d err=%s",
                   i, cpl_txn.tag, cpl_txn.length_dw,
                   directed_cpl_status.name(), cpl_txn.cpl_byte_count,
                   directed_cpl_error.name()), UVM_MEDIUM)
      send_tlp(cpl_txn);
      do_inter_packet_delay();
    end

    super.post_body();
  endtask

endclass : pcie_gen5_6_completion_directed_seq


//==============================================================================
// RANDOM SEQUENCE
// Randomized pair count, completion status, errors, CPL vs CPLD mix.
//==============================================================================
class pcie_gen5_6_completion_random_seq extends pcie_gen5_6_base_seq;
  `uvm_object_utils(pcie_gen5_6_completion_random_seq)

  rand int unsigned num_pairs;

  constraint c_num_pairs {
    num_pairs inside {[2:16]};
  }

  function new(string name = "pcie_gen5_6_completion_random_seq");
    super.new(name);
  endfunction

  virtual task body();
    pcie_gen5_6_txn   rd_txn, cpl_txn;
    bit [63:0]        rd_addr;
    pcie_cpl_status_e cpl_status;
    pcie_error_kind_e cpl_err;
    bit               emit_cpl_nod;
    int unsigned      bar;

    super.pre_body();

    if (cfg.num_bars == 0) begin
      `uvm_fatal(get_type_name(),
        "RANDOM completion: cfg.num_bars == 0. Configure at least one BAR in test build_phase.")
    end

    `uvm_info(get_type_name(),
      $sformatf("RANDOM COMPLETION: num_pairs=%0d err_inj=%0b flit=%0b",
                 num_pairs, cfg.err_inj_enable, cfg.enable_flit_mode), UVM_LOW)

    repeat (num_pairs) begin
      // Pick a random configured BAR
      bar = $urandom_range(0, cfg.num_bars-1);
      while (cfg.bar_size[bar] == 0) bar = $urandom_range(0, cfg.num_bars-1);

      // Random address within BAR
      rd_addr = cfg.bar_base[bar] +
                (64'(($urandom_range(0, int'(cfg.bar_size[bar]>>2)-1)) << 2));

      //--- MEM_RD ---
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
            ecrc_present  == cfg.ecrc_enable;
            error_kind    == ERR_NONE;
            (addr + (length_dw * 4)) <= (cfg.bar_base[bar] + cfg.bar_size[bar]);
          }) begin
        `uvm_fatal(get_type_name(), "RANDOM completion: MEM_RD randomize failed")
      end

      check_txn_legality(rd_txn);
      send_tlp(rd_txn);
      do_inter_packet_delay();

      //--- Randomize completion status and errors ---
      assert(std::randomize(cpl_status) with {
        cpl_status inside {CPL_SC, CPL_UR, CPL_CA};
        // Weight toward SC (legal) traffic
        cpl_status dist {CPL_SC := 80, CPL_UR := 10, CPL_CA := 10};
      });

      cpl_err = ERR_NONE;
      if (cfg.err_inj_enable) begin
        assert(std::randomize(cpl_err) with {
          cpl_err inside {ERR_NONE, ERR_BAD_ECRC, ERR_BAD_LCRC,
                          ERR_IDE_AUTH_FAIL, ERR_IDE_BAD_MAC};
          cpl_err dist {
            ERR_NONE         := 70,
            ERR_BAD_ECRC     := 10,
            ERR_BAD_LCRC     := 10,
            ERR_IDE_AUTH_FAIL:= 5,
            ERR_IDE_BAD_MAC  := 5
          };
        });
        if (cpl_err inside {ERR_IDE_AUTH_FAIL, ERR_IDE_BAD_MAC} && !cfg.ide_enable)
          cpl_err = ERR_NONE;
      end

      // Randomly emit CPL (no-data) before CPLD (split-completion scenario)
      assert(std::randomize(emit_cpl_nod) with {
        emit_cpl_nod dist {1'b0 := 8, 1'b1 := 2};
      });

      if (emit_cpl_nod) begin
        cpl_txn = pcie_gen5_6_txn::type_id::create("cpl_nod_txn");
        if (!cpl_txn.randomize() with {
              tlp_type       == TLP_CPL;
              tag            == rd_txn.tag;
              requester_bus  == cfg.default_bus_num;
              requester_dev  == cfg.default_dev_num;
              requester_func == cfg.default_func_num;
              cpl_status     == CPL_SC;
              cpl_byte_count == (rd_txn.length_dw * 4);
              cpl_lower_addr == rd_addr[6:0];
              flit_mode     == cfg.enable_flit_mode;
              ecrc_present  == cfg.ecrc_enable;
              error_kind    == ERR_NONE;
            }) begin
          `uvm_fatal(get_type_name(), "RANDOM completion: CPL no-data randomize failed")
        end
        check_txn_legality(cpl_txn);
        send_tlp(cpl_txn);
        do_inter_packet_delay();
      end

      //--- CPLD ---
      cpl_txn = pcie_gen5_6_txn::type_id::create("cpld_txn");
      if (!cpl_txn.randomize() with {
            tlp_type       == TLP_CPLD;
            tag            == rd_txn.tag;
            requester_bus  == cfg.default_bus_num;
            requester_dev  == cfg.default_dev_num;
            requester_func == cfg.default_func_num;
            length_dw      == rd_txn.length_dw;
            cpl_status     == cpl_status;
            cpl_byte_count == (rd_txn.length_dw * 4);
            cpl_lower_addr == rd_addr[6:0];
            flit_mode     == cfg.enable_flit_mode;
            ide_tlp       == cfg.ide_enable;
            ecrc_present  == cfg.ecrc_enable;
            error_kind    == cpl_err;
          }) begin
        `uvm_fatal(get_type_name(), "RANDOM completion: CPLD randomize failed")
      end

      check_txn_legality(cpl_txn);
      send_tlp(cpl_txn);
      do_inter_packet_delay();
    end

    super.post_body();
  endtask

endclass : pcie_gen5_6_completion_random_seq


//------------------------------------------------------------------------------
// Backward-compat alias
//------------------------------------------------------------------------------
typedef pcie_gen5_6_completion_directed_seq pcie_gen5_6_completion_seq;

`endif






















