# Architecture

```text
  +--------------------------------------------------------------+
  |                         UVM TEST                             |
  |  directed/random seqs: LTSSM, flit, mem/cfg, FC, replay, err |
  +------------------------------+-------------------------------+
                                 |
                         virtual sequencer
         +-----------------------+-----------------------+
         |                       |                       |
   PIPE sequencer          TL sequencer             DL sequencer
         |                       |                       |
    PIPE agent               TL agent                DL agent
         |                       |                       |
   PIPE driver/mon       TL driver/mon           DL driver/mon
         |                       |                       |
  +------+-----------------------+-----------------------+------+
  |              DUT: PCIe Gen5/Gen6 Controller Stub             |
  |  TL request/completion | DL FC/replay/ACK/NAK | PIPE MAC/PHY |
  +------+-----------------------+-----------------------+------+
         |                       |                       |
     pcie_pipe_if            pcie_tl_if             pcie_dl_if
         |                       |                       |
  +------+-----------------------+-----------------------+------+
  |    Scoreboard: tags, completions, FC credits, flit seq,      |
  |    replay buffer, config side effects, expected errors       |
  +--------------------------------------------------------------+
```

The environment uses the DUT-mode setting to make the testbench act as the opposite link partner. If the DUT is configured as RC, sequences generate endpoint-style completions and upstream behavior. If DUT is configured as EP, sequences generate root-complex-style configuration and memory access.

## PIPE model

`pcie_pipe_if` models a controller-level PIPE connection with per-lane TX/RX data, valid, DataK, start-block, sync-header, electrical idle, rate, width, polarity, equalization, margining, retimer, scrambling, precoding, and PAM4 abstraction hooks.

## Gen5 vs Gen6 behavior

- Gen5 uses 32.0 GT/s, 128b/130b-oriented abstraction, equalization, lane margining, SKP/EIEOS/SDS, and non-Flit/optional Flit hooks.
- Gen6 uses 64.0 GT/s, Flit Mode, 1b/1b encoding abstraction, PAM4 symbol abstraction, 236B TLP + 6B DLP + 8B CRC + 6B ECC flit structure, ACK/NAK flit sequence and replay abstractions.

