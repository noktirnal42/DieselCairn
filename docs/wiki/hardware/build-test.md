# Build and acceptance procedure

## Build packet prerequisites

Before purchasing a complete design, publish a reviewed schematic, exact MPN/revision BOM, connector and pinout, PCB files, isolation/power design, protection calculations, enclosure, firmware targets, build/flash procedure, test fixture, and calibration/measurement procedure. Current guides are architecture research, not finished construction instructions.

## Staged bench acceptance

1. Inspect PCB/assembly and measure power rails; no network or vehicle cable connected.
2. Verify startup is listen-only and both interfaces are independently discovered.
3. Verify CAN clock/bit timing, identifier, payload, error counters and timestamp against a separate CAN simulator.
4. Verify J1708 9,600 8N1, line polarity, per-node load circuit and analog levels with differential probe/logic analyzer.
5. Measure ten idle bit-times, priority delay, echo/collision detect, retry/backoff, checksum/length errors and stuck-line fail-safe.
6. Inject reset, brownout, USB disconnect, firmware mismatch and simultaneous dual-link traffic; confirm fail-safe and accurate provenance.
7. Test GUI simulator control over separate management link; capture expected raw traffic on both links.
8. Record board/adapter serial, transceiver/oscillator, firmware hash, host app build, test equipment, wiring photo, trace and pass/fail result.

No step authorizes connection to the bus. Vehicle connector topology and pinout require VIN/build-specific service documentation. Do not use the owner's vehicle while absent from the lab.

