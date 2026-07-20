`ifndef PCIE_GEN5_6_MEM_RD_WR_DIRECTED_TEST_SV
`define PCIE_GEN5_6_MEM_RD_WR_DIRECTED_TEST_SV

// =============================================================================
// TEST: pcie_gen5_6_mem_rd_wr_directed_test
//
// PURPOSE:
//   RC initiates 8 deterministic MEM_WR + MEM_RD pairs to BAR0 of the EP.
//   Each read targets the same DW-aligned address as the preceding write
//   (data-integrity read-back). No errors injected.
//
// SEQUENCE USED:
//   pcie_gen5_6_link_training_seq  - bring link to L0 at Gen5 x16
//   pcie_gen5_6_mem_rd_wr_directed_seq - 8 directed write/read pairs to BAR0
//
// KEY CFG KNOBS SET HERE:
//   agent_mode              = PCIE_AGENT_RC  (TB is RC, DUT is EP)
//   max_speed               = PCIE_GEN5_32P0
//   max_width               = PCIE_WIDTH_X16
//   enable_flit_mode        = 0              (non-FLIT, TLP mode)
//   num_bars                = 1
//   bar_type[0]             = BAR_MEM64      (64-bit prefetchable memory BAR)
//   bar_base[0]             = 64'h0000_0001_0000_0000  (4 GB boundary)
//   bar_size[0]             = 64'h0100_0000            (16 MB)
//   err_inj_enable          = 0
//   directed_pair_count     = 8              (matches original repeat(8))
//   directed_bar            = 0              (target BAR0)
//   directed_same_address   = 1              (read-back same addr as write)
//   directed_error_last     = ERR_NONE       (clean run)
// =============================================================================
class pcie_gen5_6_mem_rd_wr_directed_test extends pcie_gen5_6_base_test;
  `uvm_component_utils(pcie_gen5_6_mem_rd_wr_directed_test)

  function new(string name = "pcie_gen5_6_mem_rd_wr_directed_test",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // ---------------------------------------------------------------------------
  // build_phase: all cfg knobs BEFORE super creates env
  // ---------------------------------------------------------------------------
  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    // --- Role and link config ---
    cfg.agent_mode        = PCIE_AGENT_RC;
    cfg.max_speed         = PCIE_GEN5_32P0;
    cfg.init_speed        = PCIE_GEN1_2P5;
    cfg.max_width         = PCIE_WIDTH_X16;
    cfg.init_width        = PCIE_WIDTH_X1;
    cfg.enable_flit_mode  = 1'b0;
    cfg.enable_scrambling = 1'b1;
    cfg.enable_precoding  = 1'b0;   // not needed below Gen6

    // --- PHY features ---
    cfg.deskew_enable              = 1'b1;
    cfg.lane_reversal_enable       = 1'b0;
    cfg.polarity_inversion_enable  = 1'b0;
    cfg.enable_retimer_hooks       = 1'b0;

    // --- BAR: one 16MB MEM64 aperture at 4 GB ---
    cfg.num_bars     = 6'h1;
    cfg.bar_type[0]  = BAR_MEM64;
    cfg.bar_base[0]  = 64'h0000_0001_0000_0000;
    cfg.bar_size[0]  = 64'h0100_0000;     // 16 MB (power-of-2, aligned)

    // --- BDF ---
    cfg.default_bus_num  = 8'h00;
    cfg.default_dev_num  = 5'h01;
    cfg.default_func_num = 3'h0;

    // --- Optional features: all off for directed clean run ---
    cfg.ide_enable      = 1'b0;
    cfg.pasid_enable    = 1'b0;
    cfg.ohc_enable      = 1'b0;
    cfg.atomic_op_enable= 1'b0;
    cfg.ecrc_enable     = 1'b1;   // ECRC always on: best practice
    cfg.lcrc_enable     = 1'b1;
    cfg.replay_enable   = 1'b1;
    cfg.err_inj_enable  = 1'b0;

    // --- Flow control (reasonable init credits for directed test) ---
    cfg.fc_ph_init   = 8'h40;    // 64  Posted Headers
    cfg.fc_pd_init   = 12'h100;  // 256 Posted Data
    cfg.fc_nph_init  = 8'h40;    // 64  Non-Posted Headers
    cfg.fc_npd_init  = 12'h100;  // 256 Non-Posted Data
    cfg.fc_cplh_init = 8'h40;    // 64  Completion Headers
    cfg.fc_cpld_init = 12'h100;  // 256 Completion Data

    // --- Timing ---
    cfg.inter_packet_gap_min = 1;
    cfg.inter_packet_gap_max = 4;
    cfg.ts_ordered_set_count = 8;

    // --- Error kind: none ---
    cfg.error_kind = ERR_NONE;
  endfunction

  // ---------------------------------------------------------------------------
  // run_phase: link training -> directed mem rd/wr
  // No virtual sequencer. Both sequences run directly on env.vseqr.
  // ---------------------------------------------------------------------------
  task run_phase(uvm_phase phase);
    pcie_gen5_6_link_training_seq        s_link;
    pcie_gen5_6_mem_rd_wr_directed_seq   s_mem;

    phase.raise_objection(this);

    // --- Step 1: Link Training ---
    s_link = pcie_gen5_6_link_training_seq::type_id::create("s_link");
    s_link.start(env.vseqr);

    // --- Step 2: Directed Memory Read/Write ---
    s_mem = pcie_gen5_6_mem_rd_wr_directed_seq::type_id::create("s_mem");
    s_mem.directed_pair_count   = 8;      // 8 WR+RD pairs
    s_mem.directed_bar          = 0;      // target BAR0
    s_mem.directed_same_address = 1'b1;   // read-back same addr as write
    s_mem.directed_error_last   = ERR_NONE;
    s_mem.start(env.vseqr);

    phase.drop_objection(this);
  endtask

endclass : pcie_gen5_6_mem_rd_wr_directed_test

`endif
