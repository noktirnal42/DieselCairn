# DieselCairn Hardware Design and Parts Planning

## Scope

The first target is the owner's 2009 International RE300 rear-engine school bus, model PB305, with a MaxxForce DT and an owner-reported Allison 3000 Series 3000PTS transmission. Use RE300 for the side-badge/series identity and PB305 for the school-bus model number. Verify the transmission identification against its nameplate. The push-button selector/LED display is evidence of electronic controls, not a sufficient identifier for TCM generation, hardware configuration, or sixth-range capability.

Three adapter paths remain in the project plan because the owner wants to be able to use any/all of them. None has been verified on this RE300, and the former BOM prices and “plug and play” statements are withdrawn.

## Shared system architecture

`Mac/iPhone app ⇄ adapter transport ⇄ CAN (J1939) and, where the authorized Navistar procedure requires it, J1708 link ⇄ protected/isolated vehicle data links`

App protocol logic must not depend on a specific board. Hardware identity and capabilities are reported at connection time. Firmware starts in listen-only mode; transmit requires explicit arming and a supported target procedure. Vehicle programming is a separate capability from ordinary CAN transport.

## Path A — STM32 + external CAN controller

**Prior proposal correction:** STM32F031K6 has no integrated CAN controller and no native USB device peripheral. Add a separate CAN controller such as MCP2515 and a USB-UART bridge, or choose a different MCU if one-chip CAN/USB is required.

Parts to select and verify before BOM publication:

- Exact STM32F031K6 package/board and clock/reset/debug circuitry
- MCP2515 variant, oscillator frequency, decoupling, SPI wiring, interrupt handling
- Automotive-appropriate CAN transceiver with required common-mode/transient ratings
- Galvanic isolation as required by the approved schematic; isolated power if required
- USB-UART bridge/cable, ESD protection, connector, fuse, and enclosure
- Switchable termination with default OFF, labeled CAN-H/CAN-L, and test points

## Path B — Arduino USB-CDC + external CAN controller

Use one identified ATmega32U4 USB-CDC board revision, not a generic “Nano/Uno” pin diagram. Add MCP2515, oscillator-matched configuration, CAN transceiver, protections/isolation, and a protected vehicle connector. On ATmega32U4 boards, SPI is normally exposed at the ICSP header; verify the exact board manual before wiring. Keep termination disabled by default.

## Path C — FT232H + external CAN controller

FT232H MPSSE talks SPI to MCP2515; MCP2515 handles CAN controller functions; a separate transceiver connects the differential pair. Host support requires direct MPSSE access and a tested macOS USB permission/driver strategy. The current fake Swift loopback has been removed. A VCP-only serial driver is not sufficient for MPSSE.

## Cross-path safety and validation

**New MaxxForce flash-interface requirement:** Navistar bulletin IK2600282 for 2007–09 MaxxForce DT/9/10 documents J1708 for NavKal's Save Request step and J1939 for programming. A J1939-only CAN adapter is therefore insufficient for that documented full flash workflow. The exact vehicle connector pins, active data links, and approved interface for this RE300 have not been confirmed; add J1708 only after connector and electrical research. Do not attach a generic J1708 bus driver to an assumed connector pinout.

Before vehicle connection, validate supply range/current, reverse polarity, load dump/transient response, ESD, galvanic isolation, logic levels, termination, common-mode range, bus bitrate/oscillator, receive-only startup, watchdog/fail-safe behavior, reset handling, bus-off recovery, timestamp accuracy, and transmit authorization on a current-limited isolated bench. Do not connect raw breadboard wiring to vehicle diagnostics.

Construction guide release requires a reviewed schematic, revisioned BOM with manufacturer part numbers, board revision, connector pinout, wire list, enclosure drawings, firmware build steps, calibrated test procedure, and bench results. No cost/date estimates are committed until parts are selected and current quotes are checked.

## Required dual-link expansion: J1708 + J1587

The earlier CAN-only adapter designs are incomplete for this vehicle workflow. Navistar IK2600282 documents J1708 for the NavKal Save Request step and J1939 for Program on relevant 2007-09 MaxxForce engines. Every hardware version must therefore expose two independent, electrically distinct links: J1939 classic CAN and J1708 (with J1587 software framing above it). The bulletin does not establish the user's exact engine variant or connector wiring; verify those before a vehicle harness is designed.

J1708 must not use an ordinary RS-485 breakout as a drop-in. Its dominant/recessive electrical behavior, 9,600-baud 8N1 signaling, per-node load/bias/filter network, and access arbitration differ. Evaluate a protected automotive J1708 transceiver such as Renesas ISL32455E against its current datasheet and reference circuit; use a reviewed reference design, isolated supply/digital isolation as required, ESD/transient protection, test points, and a separate keyed connector. No endpoint termination resistor is added by default. The selected device needs a UART plus hardware-timed driver enable, RX echo/collision comparison, 10-bit-time idle detection, priority delay (classes 1-8), and deterministic backoff/retry. A host-only FT232H timing loop is not adequate for reliable transmit; the FT232H path needs an MCU/companion controller handling J1708 in real time.

### Dual-link hardware acceptance criteria

1. Receive-only boot verified independently on CAN and J1708; TX requires a local physical arm control and host selection, and cannot be armed by a simulator profile.
2. CAN bit timing and J1708 9,600 8N1 timing verified with a logic analyzer and electrically representative isolated bench fixture.
3. J1708 idle qualify, priority delay, echo collision detection, retry bounds, and stuck-dominant fail-safe measured at the adapter, not assumed from desktop timing.
4. J1587 checksum, MID/PID parsing, 21-byte limit, inter-message gap, malformed frame reporting, and timestamp behavior pass fixture tests.
5. Both networks can be logged concurrently without timestamp/source confusion. Loss of one physical link must not fabricate status on the other.
6. Power transient, ESD, reverse polarity, isolation, fault protection, connector pinout, and enclosure review complete before any vehicle use.

For a physical training/simulation node, build a second identical compliant J1708 PHY as an isolated bench node with a simulator-mode firmware image. Its GUI must select deterministic J1587 message sets, MIDs, PID/data values, rates, collision/noise/idle scenarios and start/stop, while showing `SIMULATED BENCH NODE`. The node must be physically disconnected from vehicle wiring; do not use a vehicle harness for this bench.

## Emulator and simulator findings

- Renode documents STM32F0 family support, but support for a family does not prove exact STM32F031K6 peripheral fidelity. Confirm CPU, timers, SPI, UART, GPIO, interrupt, clock, and memory models first. The MCP2515 still needs a peripheral model or a mocked SPI register device.
- The in-app CAN simulator is suitable for app/J1939 decoder fixtures. It does not emulate MCP2515 electrical behavior, FT232H USB/MPSSE, transceiver faults, protection, or vehicle wiring.
- FT232H command-level mocks can cover host-driver sequencing. Real MPSSE/controller/transceiver behavior requires bench hardware.
- Emulator coverage is additive; final acceptance still requires hardware-in-the-loop adapter checks and physical MacBook/iPhone app QA.
- Add a J1708/J1587 physical-layer model and firmware timing tests; Renode/desktop unit tests alone cannot validate the dominant/recessive electrical circuit, timing jitter, analog fault behavior, or real collision waveforms. A J1587 software node should run on a separate adapter/device, never loop back through the app's virtual source and masquerade as live traffic.
