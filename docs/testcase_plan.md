# Directed Testcase Plan

1. pcie_gen5_6_smoke_test: RC x16 Gen6 train to L0 and enter Flit Mode.
2. pcie_gen5_6_rc_to_ep_mem_test: RC-originated memory reads/writes to endpoint model.
3. pcie_gen5_6_ep_to_rc_mem_test: EP-originated DMA-style memory reads/writes to RC model.
4. pcie_gen5_6_cfg_test: Config Type0 reads/writes and register side-effect hooks.
5. pcie_gen5_6_flit_mode_test: SDS followed by IDLE/NOP/Payload flits.
6. pcie_gen5_6_flow_control_test: InitFC1/InitFC2 and UpdateFC/Optimized_UpdateFC.
7. pcie_gen5_6_replay_ack_nak_test: NAK and replay buffer behavior.
8. pcie_gen5_6_lcrc_crc_ecc_error_test: Bad LCRC/CRC/ECC injection and NAK path.
9. pcie_gen5_6_ltssm_test: Legal LTSSM progression to L0.
10. pcie_gen5_6_equalization_test: Gen5/Gen6 equalization phase abstraction.
11. pcie_gen5_6_lane_margining_test: Per-lane margin commands and status hooks.
12. pcie_gen5_6_ide_test: IDE message and IDE-present TLP abstraction.
13. pcie_gen5_6_error_aer_dpc_test: Malformed TLP, AER/DPC indication hooks.
14. pcie_gen5_6_gen5_32gt_test: Gen5 32.0 GT/s non-PAM4 path.
15. pcie_gen5_6_gen6_64gt_test: Gen6 64.0 GT/s Flit Mode path.
16. pcie_gen5_6_pasid_ohc_test: PASID/OHC fields in Flit Mode TLP abstraction.
17. pcie_gen5_6_atomic_dmw_test: AtomicOp and Deferrable Memory Write abstraction.
18. pcie_gen5_6_power_l0s_l1_l2_test: EIOS/FTS based power-management hook test.
19. pcie_gen5_6_lane_reversal_polarity_test: Lane reversal and polarity inversion.
20. pcie_gen5_6_retimer_hook_test: Retimer-aware equalization and SKP hook coverage.
21. pcie_gen5_6_doe_ide_cfg_test: DOE/IDE config capability access hooks.
22. pcie_gen5_6_random_traffic_test: Mixed memory, FC, and replay traffic.

## Constrained-random ideas

- Random speed/width matrix with legal Gen5/Gen6 feature combinations.
- Random posted/non-posted/completion interleaving with tag reuse protection.
- Random flit packing with payload/NOP/IDLE/nullified markers.
- Random ACK/NAK and replay timer pressure.
- Random FC credit updates and intentional underflow negative tests.
- Random lane polarity/reversal/deskew/equalization pass-fail.
- Random config accesses across AER/DPC/DOE/IDE/lane-margining extended-capability windows.

