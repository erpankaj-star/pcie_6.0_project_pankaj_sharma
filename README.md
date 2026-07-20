# PCIe Gen5/Gen6 PIPE Controller UVM Verification Project v2

This project is a controller-level SystemVerilog/UVM verification skeleton for a PCIe Gen5/Gen6 controller connected at a PIPE-style interface.

## What changed from the previous version

- The DUT stub now has explicit PIPE, TL, and DL interface ports instead of loose placeholder wiring.
- The PIPE interface is lane-aware and contains controller-to-PHY and PHY-to-controller signal groups.
- Gen5 32.0 GT/s and Gen6 64.0 GT/s are both modeled through enums and test configuration.
- Gen6 Flit Mode has dedicated flit item fields for 236 TLP bytes, 6 DLP bytes, 8 CRC bytes, and 6 ECC bytes.
- Replay, ACK/NAK, FC credit, LTSSM, lane margining, lane reversal, polarity inversion, equalization, retimer hooks, AER/DPC/IDE/DOE coverage hooks are included.
- Indentation is 2-space consistent inside packages/classes/modules.

## Compile and run

```bash
cd sim
make compile
make run TEST=pcie_gen5_6_smoke_test MODE=RC SPEED=6 WIDTH=16
make run TEST=pcie_gen5_6_gen5_32gt_test MODE=EP SPEED=5 WIDTH=8
make run TEST=pcie_gen5_6_lcrc_crc_ecc_error_test ERROR=BAD_CRC
```

SPEED mapping: 1=2.5GT/s, 2=5.0GT/s, 3=8.0GT/s, 4=16.0GT/s, 5=32.0GT/s, 6=64.0GT/s.

## True implementation vs abstraction

True UVM implementation skeleton:
- RC/EP configuration object and plusarg control.
- PIPE/TL/DL interfaces and monitors/drivers.
- Scoreboard structures for outstanding tags, completions, replay buffer, and credits.
- Assertions for credit, ACK/NAK, sequence, PIPE stability, and LTSSM legality.
- Functional coverage for speed, width, errors, flit mode, and lane features.
- Directed tests and reusable sequences.

Abstracted/stubbed:
- Analog PAM4 electrical behavior, channel loss, jitter, eye margin, and FEC math.
- Full production PIPE specification timing.
- Full PCIe configuration capability linked-list implementation.
- Exact PCIe CRC/LCRC/ECRC/ECC algorithms.
- Full LTSSM timing counters and all corner transitions.
- Complete IDE encryption/PCRC cryptography.

These are represented as hooks and checkable transaction-level abstractions so that a real DUT can be connected and the environment can be expanded progressively.

