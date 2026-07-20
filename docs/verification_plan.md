# Verification Plan

## Transaction Layer

- Memory Read/Write, Config Read/Write, Completion/CplD, Message, AtomicOp abstraction, Deferrable Memory Write abstraction.
- Tag allocation and completion matching.
- Byte Enable constraints and assertions.
- Traffic class, attributes, PASID/OHC, IDE-present, poison/ECRC abstraction.
- Completion timeout and unexpected completion injection.

## Data Link Layer

- DL states: DL_INACTIVE, DL_FEATURE, DL_INIT, DL_ACTIVE, DL_DOWN.
- Feature exchange and scaled FC hooks.
- InitFC1/InitFC2, UpdateFC, Optimized_UpdateFC.
- ACK/NAK, replay request, replay timeout, sequence tracking.
- Link down and error-to-TL indication.

## Physical/PIPE

- Detect/Polling/Configuration/Recovery/L0/L0s/L0p/L1/L2/Disabled/Loopback/Hot Reset state coverage.
- x1/x2/x4/x8/x16 width coverage.
- Gen1 through Gen6 speed coverage.
- TS1/TS2, SKP, SDS, EIOS/EIEOS, FTS abstractions.
- Equalization pass/fail, lane reversal, polarity inversion, deskew, retimer hooks.
- Gen6 PAM4/1b1b modeled as symbolic values, not analog voltage.

## Gen6 Flit Mode

- IDLE/NOP/Payload/Replay/Nullified/Poisoned flits.
- 236B TLP region, 6B DLP region, 8B CRC region, 6B ECC region.
- DLP ACK/NAK and optimized FC payload hooks.
- Sequence number handshake, normal flit exchange, replay scheduling.
- CRC/ECC error injection and Flit Error logging hooks.

