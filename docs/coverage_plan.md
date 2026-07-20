# Coverage Plan

Functional coverage is implemented in `pcie_gen5_6_coverage.sv` and should be extended with TL and DL subscriber covergroups in a production environment.

Covered now:
- RC and EP mode.
- Gen1/2/3/4/5/6 speeds.
- x1/x2/x4/x8/x16 widths.
- PIPE symbols: TS, SKP, SDS, EIOS/EIEOS, Flit.
- Flit Mode on/off.
- Error classes: CRC, ECC, replay, link/equalization/deskew.
- Lane reversal, polarity inversion, deskew, retimer.
- Precoding and scrambling abstraction.

Recommended extensions:
- Cross TLP type with traffic class, attributes, PASID/OHC, poison/ECRC/IDE.
- Cross DLP ACK/NAK with replay buffer occupancy.
- Cross FC type with scaled/optimized updates.
- Cross LTSSM state with speed and width.
- Cross config capability access with side effects.

