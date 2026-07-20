# Debug Guide

## Link does not reach L0

Check:
- `tb_top.pipe_if.ltssm_state`
- `rx_symbol_lock`, `rx_block_align`, `rx_lane_aligned`
- `eq_phase_done`, `rate_change_ack`, `deskew_done`
- Ordered sets from PIPE driver: TS1, TS2, EIEOS, SDS

## Gen6 Flit Mode not active

Check:
- `negotiated_speed == PCIE_GEN6_64P0`
- `phy_mode_flit`, `flit_mode_active`
- `tx_start_block`, `tx_sync_header`, `tx_valid`
- SDS and first IDLE/NOP/Payload flit exchange

## Replay/ACK/NAK mismatch

Check:
- `dl_if.flit_seq_num`, `dl_if.ack_nak_seq_num`
- `dl_if.ack`, `dl_if.nak`, `dl_if.replay_req`
- scoreboard `replay_buffer`, `expected_flit_seq`, `acked_flit_seq`

## Flow-control failure

Check:
- `tl_if.credit_avail`
- DL credits: `ph_credit`, `pd_credit`, `nph_credit`, `npd_credit`, `cplh_credit`, `cpld_credit`
- `optimized_update_fc`, `scaled_fc_enable`
- assertion `a_no_tlp_without_fc`

## Completion mismatch

Check:
- `tl_if.tag`, `requester_id`, `completer_id`
- scoreboard `outstanding_by_tag`
- Cpl/CplD generation sequence

## Lane/equalization failures

Check:
- `lane_reversal_detected`, `rx_polarity_inverted`, `deskew_done`
- `equalization_in_progress`, `eq_phase_done`
- `rx_margin_status`

## Error injection path

Check:
- plusarg `+PCIE_ERROR=BAD_CRC/BAD_ECC/BAD_SEQ/NAK/LINK_DOWN`
- `pipe_if.injected_error`, `error_indication`
- `dl_if.error_to_tl`, `tl_if.malformed_tlp`, `tl_if.poisoned`

