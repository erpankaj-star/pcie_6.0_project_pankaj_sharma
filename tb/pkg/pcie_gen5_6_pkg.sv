`ifndef PCIE_GEN5_6_PKG_SV
`define PCIE_GEN5_6_PKG_SV

package pcie_gen5_6_pkg;

  //--------------------------------------------------------------------------
  // UVM + types (must be first - everything depends on these)
  //--------------------------------------------------------------------------
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  import pcie_gen5_6_types_pkg::*;

  //--------------------------------------------------------------------------
  // Sequence items
  // Must come before cfg (cfg has BAR/credit fields that use item-related
  // parameters) and before any driver/monitor/sequence.
  //--------------------------------------------------------------------------
  `include "../sequence_items/pcie_tlp_item.sv"
  `include "../sequence_items/pcie_dlp_item.sv"
  `include "../sequence_items/pcie_flit_item.sv"
  `include "../sequence_items/pcie_pipe_symbol_item.sv"
  `include "../sequence_items/pcie_cfg_item.sv"

  //--------------------------------------------------------------------------
  // Config object + transaction descriptor
  // cfg must come after items (its array fields reference item-related types).
  // txn must come after cfg (it mirrors cfg knobs) and before base_seq.
  //--------------------------------------------------------------------------
  `include "../env/pcie_gen5_6_cfg.sv"
//  `include "../sequences/pcie_gen5_6_txn.sv"

  //--------------------------------------------------------------------------
  // Drivers
  //--------------------------------------------------------------------------
  `include "../drivers/pcie_gen5_6_pipe_driver.sv"
  `include "../drivers/pcie_gen5_6_tl_driver.sv"
  `include "../drivers/pcie_gen5_6_dl_driver.sv"

  //--------------------------------------------------------------------------
  // Monitors
  //--------------------------------------------------------------------------
  `include "../monitors/pcie_gen5_6_pipe_monitor.sv"
  `include "../monitors/pcie_gen5_6_tl_monitor.sv"
  `include "../monitors/pcie_gen5_6_dl_monitor.sv"

  //--------------------------------------------------------------------------
  // Agents (use drivers + monitors declared above)
  //--------------------------------------------------------------------------
  `include "../env/pcie_gen5_6_pipe_agent.sv"
  `include "../env/pcie_gen5_6_tl_agent.sv"
  `include "../env/pcie_gen5_6_dl_agent.sv"

  //--------------------------------------------------------------------------
  // Virtual sequencer
  // MUST come before any sequence that uses:
  //   `uvm_declare_p_sequencer(pcie_gen5_6_virtual_sequencer)
  //--------------------------------------------------------------------------
  `include "../env/pcie_gen5_6_virtual_sequencer.sv"

  //--------------------------------------------------------------------------
  // Checker / coverage components
  //--------------------------------------------------------------------------
  `include "../env/pcie_gen5_6_ref_model.sv"
  `include "../env/pcie_gen5_6_scoreboard.sv"
  `include "../env/pcie_gen5_6_coverage.sv"

  //--------------------------------------------------------------------------
  // Environment (uses agents + vseqr + scoreboard + coverage + ref_model)
  //--------------------------------------------------------------------------
  `include "../env/pcie_gen5_6_env.sv"

  //--------------------------------------------------------------------------
  // Sequence library
  //
  // ORDER IS MANDATORY:
  //   1. base_seq              - parent of all sequences; uses p_sequencer
  //   2. PIPE sub-sequences    - used by link_training_seq
  //   3. DL FC init sub-seq    - used by link_training_seq
  //   4. virtual_seq_base      - parent of all virtual sequences
  //   5. link_training_seq     - FIRST virtual seq; defines typedef alias
  //                              used by every test
  //   6. All other sequences   - may extend base_seq or virtual_seq_base
  //--------------------------------------------------------------------------
  `include "../sequences/pcie_gen5_6_base_seq.sv"

  // PIPE sub-sequences (TS1/TS2/EIEOS/SDS/SKP) - needed by link training

  // `include "../sequences/pcie_gen5_6_pipe_subseqs.sv"

  // DL FC init sub-sequence - needed by link training
 // `include "../sequences/pcie_gen5_6_dl_fc_init_seq.sv"

  // Virtual sequence base class (after vseqr, after base_seq)
 // `include "../env/pcie_gen5_6_virtual_seq_base.sv"

  // Link training virtual sequence (defines pcie_gen5_6_link_training_seq
  // typedef alias - must come before any test that calls it)
  `include "../sequences/pcie_gen5_6_link_training_seq.sv"

  // Feature sequences
 `include "../sequences/pcie_gen5_6_flit_mode_entry_seq.sv"
 //  `include "../sequences/pcie_gen5_6_mem_rd_wr_seq.sv"

  // `include "../sequences/pcie_gen5_6_cfg_rd_wr_seq.sv"
//  `include "../sequences/pcie_gen5_6_completion_seq.sv"
//  `include "../sequences/pcie_gen5_6_flow_control_seq.sv"
//  `include "../sequences/pcie_gen5_6_replay_seq.sv"
//  `include "../sequences/pcie_gen5_6_error_injection_seq.sv"
//  `include "../sequences/pcie_gen5_6_ide_seq.sv"
//  `include "../sequences/pcie_gen5_6_lane_margining_seq.sv"
//  `include "../sequences/pcie_gen5_6_equalization_seq.sv"
//  `include "../sequences/pcie_gen5_6_power_mgmt_seq.sv"
//  `include "../sequences/pcie_gen5_6_msg_atomic_seq.sv"
//
  // Virtual sequences (after virtual_seq_base + all sub-sequences)
//  `include "../sequences/pcie_gen5_6_flit_mode_vseq.sv"
//  `include "../sequences/pcie_gen5_6_mem_rd_wr_vseq.sv"
//  `include "../sequences/pcie_gen5_6_cfg_rd_wr_vseq.sv"
//  `include "../sequences/pcie_gen5_6_error_inject_vseq.sv"

  //--------------------------------------------------------------------------
  // Tests (base_test first - all others extend it)
  //--------------------------------------------------------------------------
  `include "../tests/pcie_gen5_6_base_test.sv"
//  `include "../tests/pcie_gen5_6_mem_rd_wr_directed_test.sv"

  // `include "../tests/pcie_gen5_6_smoke_test.sv"
//  `include "../tests/pcie_gen5_6_rc_to_ep_mem_test.sv"
//  `include "../tests/pcie_gen5_6_ep_to_rc_mem_test.sv"
//  `include "../tests/pcie_gen5_6_cfg_test.sv"
  `include "../tests/pcie_gen5_6_flit_mode_test.sv"
//  `include "../tests/pcie_gen5_6_random_mem_test.sv"
//  `include "../tests/pcie_gen5_6_flow_control_test.sv"
//  `include "../tests/pcie_gen5_6_replay_ack_nak_test.sv"
//  `include "../tests/pcie_gen5_6_lcrc_crc_ecc_error_test.sv"
//  `include "../tests/pcie_gen5_6_ltssm_test.sv"
//  `include "../tests/pcie_gen5_6_equalization_test.sv"
//  `include "../tests/pcie_gen5_6_lane_margining_test.sv"
//  `include "../tests/pcie_gen5_6_ide_test.sv"
//  `include "../tests/pcie_gen5_6_error_aer_dpc_test.sv"
//  `include "../tests/pcie_gen5_6_gen5_32gt_test.sv"
//  `include "../tests/pcie_gen5_6_gen6_64gt_test.sv"
//  `include "../tests/pcie_gen5_6_pasid_ohc_test.sv"
//  `include "../tests/pcie_gen5_6_atomic_dmw_test.sv"
//  `include "../tests/pcie_gen5_6_power_l0s_l1_l2_test.sv"
//  `include "../tests/pcie_gen5_6_lane_reversal_polarity_test.sv"
//  `include "../tests/pcie_gen5_6_retimer_hook_test.sv"
//  `include "../tests/pcie_gen5_6_doe_ide_cfg_test.sv"
//  `include "../tests/pcie_gen5_6_random_traffic_test.sv"
//
endpackage : pcie_gen5_6_pkg

`endif






































































