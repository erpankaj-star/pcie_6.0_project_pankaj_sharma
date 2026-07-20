`ifndef PCIE_GEN5_6_MEM_RD_WR_RANDOM_TEST_SV
`define PCIE_GEN5_6_MEM_RD_WR_RANDOM_TEST_SV

// =============================================================================
// TEST: pcie_gen5_6_mem_rd_wr_random_test
//
// PURPOSE:
//   Fully randomized memory read/write traffic.
//   - num_pairs randomized 4-64 (constrained in sequence)
//   - Target BAR is randomly selected per pair from all configured BARs
//   - Error injection enabled with weighted distribution (60% clean traffic)
//   - AtomicOps (FetchAdd/Swap/CAS) randomly interspersed
//   - Error types gated against their respective feature enables
//
// SEQUENCE USED:
//   pcie_gen5_6_link_training_seq   - bring link to L0
//   pcie_gen5_6_mem_rd_wr_random_seq - randomized pairs across 3 BARs
//
// KEY CFG KNOBS SET HERE:
//   agent_mode        = PCIE_AGENT_RC
//   max_speed         = PCIE_GEN5_32P0
//   max_width         = PCIE_WIDTH_X16
//   enable_flit_mode  = 0
//   num_bars          = 3  (BAR0 MEM64 64MB, BAR1 MEM32 4MB, BAR2 IO 256B)
//   err_inj_enable    = 1  (random error injection active)
//   atomic_op_enable  = 1  (AtomicOps interspersed)
//   ecrc_enable       = 1
//   ide_enable        = 0  (excluded from error mix)
//   pasid_enable      = 0  (excluded from error mix)
// =============================================================================
class pcie_gen5_6_mem_rd_wr_random_test extends pcie_gen5_6_base_test;
  `uvm_component_utils(pcie_gen5_6_mem_rd_wr_random_test)

  function new(string name = "pcie_gen5_6_mem_rd_wr_random_test",
               uvm_component parent = null);
    super.new(name, parent);
  endfunction

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
    cfg.enable_precoding  = 1'b0;

    // --- PHY features ---
    cfg.deskew_enable             = 1'b1;
    cfg.lane_reversal_enable      = 1'b0;
    cfg.polarity_inversion_enable = 1'b0;
    cfg.enable_retimer_hooks      = 1'b0;

    // --- Three BARs: MEM64 + MEM32 + IO ---
    cfg.num_bars = 6'h3;

    cfg.bar_type[0] = BAR_MEM64;
    cfg.bar_base[0] = 64'h0000_0001_0000_0000;  // 4 GB
    cfg.bar_size[0] = 64'h0400_0000;             // 64 MB

    cfg.bar_type[1] = BAR_MEM32;
    cfg.bar_base[1] = 64'h9000_0000;             // 2.25 GB  (32-bit range)
    cfg.bar_size[1] = 64'h0040_0000;             // 4 MB

    cfg.bar_type[2] = BAR_IO;
    cfg.bar_base[2] = 64'h0000_0000_0000_1000;   // I/O at 0x1000
    cfg.bar_size[2] = 64'h0000_0100;             // 256 B

    // --- BDF ---
    cfg.default_bus_num  = 8'h00;
    cfg.default_dev_num  = 5'h01;
    cfg.default_func_num = 3'h0;

    // --- Features: atomics + error injection ON; IDE/PASID/OHC OFF ---
    cfg.ide_enable       = 1'b0;
    cfg.pasid_enable     = 1'b0;
    cfg.ohc_enable       = 1'b0;
    cfg.atomic_op_enable = 1'b1;   // FetchAdd/Swap/CAS interspersed
    cfg.ecrc_enable      = 1'b1;
    cfg.lcrc_enable      = 1'b1;
    cfg.replay_enable    = 1'b1;
    cfg.err_inj_enable   = 1'b1;   // enables random error injection in sequence

    // --- Flow control ---
    cfg.fc_ph_init   = 8'h40;
    cfg.fc_pd_init   = 12'h100;
    cfg.fc_nph_init  = 8'h40;
    cfg.fc_npd_init  = 12'h100;
    cfg.fc_cplh_init = 8'h40;
    cfg.fc_cpld_init = 12'h100;

    // --- Timing ---
    cfg.inter_packet_gap_min = 0;   // back-to-back allowed
    cfg.inter_packet_gap_max = 8;
    cfg.ts_ordered_set_count = 8;

    // --- Default error kind (random seq picks its own internally) ---
    cfg.error_kind = ERR_NONE;
  endfunction

  task run_phase(uvm_phase phase);
    pcie_gen5_6_link_training_seq       s_link;
    pcie_gen5_6_mem_rd_wr_random_seq    s_mem;

    phase.raise_objection(this);

    // --- Step 1: Link Training ---
    s_link = pcie_gen5_6_link_training_seq::type_id::create("s_link");
    s_link.start(env.vseqr);

    // --- Step 2: Random Memory Traffic ---
    // num_pairs constrained [4:64] in sequence; sequence handles BAR selection,
    // error kind gating, and AtomicOp insertion internally.
    s_mem = pcie_gen5_6_mem_rd_wr_random_seq::type_id::create("s_mem");
    s_mem.start(env.vseqr);

    phase.drop_objection(this);
  endtask

endclass : pcie_gen5_6_mem_rd_wr_random_test

`endif
