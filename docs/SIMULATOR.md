# DieselCairn Multi-Link Simulator and Hardware Bench

## Target system and network scope

The current target is the 2009 International RE300 school bus (factory school-bus model PB305), MaxxForce DT, and an owner-reported Allison 3000 Series 3000PTS. Verify the transmission nameplate; exact serial, TCM generation/calibration, and configured gear range remain unknown. Bench coverage must treat engine and transmission controls as separate systems and keep data-source provenance visible.

| Network / layer | What it does | Required simulation |
|---|---|---|
| J1939 over classic CAN | Engine/TCM broadcast and request traffic; standard PGN transport | 29-bit identifiers, 8-byte frames, configurable bitrate, address/source behavior, bus arbitration, load, error frames, TP.CM/TP.DT segmentation, timeout/retry and replay |
| J1939-73 diagnostics | DM1/DM2 and diagnostic service behavior where target supports it | Lamp states, zero/multiple DTCs, SPN/FMI/occurrence parsing, multi-packet transport, malformed frames, negative/unsupported response and timeout cases |
| J1708 physical/data link | 9,600-baud two-wire link and shared-bus access arbitration | 8N1 symbols, idle qualification, priority delay, collision/echo detection, backoff/retry, bus stuck/noise and framing errors |
| J1587 message layer | MID/PID/data/checksum records carried over J1708 | Valid/invalid checksum, MID/PID catalogs with provenance, 21-byte max profile, unknown PID, length errors, inter-message gap and replay |
| OEM workflow simulator | Separately modeled Navistar and Allison authorized service procedures | Explicit state machine, target identity, Save Request/J1708 then Program/J1939 sequence fixture, wrong calibration, auth declined, interrupted transport/power, recovery, audit trail; no live writes |

Navistar IK2600282 identifies J1708 for the Save Request step and J1939 for Program on relevant 2007-09 MaxxForce engines. That is why these links must be independently simulated and logged. The actual PB305 engine/module applicability and DLC pinout still require the owner's labels/build data and authorized service documentation. [Navistar IK2600282](https://static.nhtsa.gov/odi/tsbs/2025/MC-11019110-0001.pdf).

J1708 is not generic RS-485, and J1587 is not a CAN protocol. J1587 raw messages must not be converted to J1939 PGNs. J1708 electrical behavior requires a compliant dominant/recessive physical layer; timing/arbitration must execute in adapter firmware. See [TI AN-915](https://www.ti.com/lit/an/snla038b/snla038b.pdf) and the [U.S. DOT J1587/J1708 training reference](https://www.its.dot.gov/StandardsTraining/modtransit5/sup/mt5sup.pdf).

## In-app software simulator

No virtual session means no simulated readings/faults. Starting a virtual session creates an explicit synthetic source. Every view, capture, report, MCP result, and export must label `SIMULATOR`; the simulator may never write data into the vehicle's live record or claim a physical test passed.

The existing **CAN / J1708 bench** has scenario, start/stop, manual J1939 PGN frame injection, J1939 trace replay, synthetic engine/TCM nodes, adapter stages, voltage/load/termination, and transport-drop controls. It reassembles receive-side J1939-21 BAM global broadcasts up to 1,785 bytes, validates announced length/packet count, source, global destination and sequence, and displays completed messages separately from raw frames. It does not implement connection-managed RTS/CTS or a BAM expiry timer yet. BAM's sender-managed pacing is not emulated by trace replay. The J1708/J1587 panel builds a checksum-valid message from MID + raw data, checks the 21-byte profile limit, and routes it through a distinct adapter message type. Virtual hardware also exposes idle-bit count, priority class, J1708 PHY/node state, and echo-collision injection. These are application/software fixtures; they do not emulate external electrical behavior or establish PB305 broadcast behavior/Allison support.

Run a virtual session before using **Export trace**, then open that JSON with **Replay fixture…**. New traces store frames in timestamp order and retain subsecond timestamps. Replay accepts version 1 traces with either ISO 8601 or numeric timestamps. It processes frame batches to exercise decoding and reassembly.

The GUI currently exposes a software J1587 transmitter fixture. Expand it with a protocol selector and full controls for:

- **J1939/CAN (partial):** bitrate, extended test frame, PGN/source/priority, 0-8 byte payload, ECU/TCM fixtures, DM1 fixture, bus load/termination/drop, adapter state and capture/replay. BAM receive/reassembly is implemented and tested. Still needed: standard-ID support, address claim, BAM pacing/expiry, transmit segmentation, RTS/CTS, DM2, request response/timeout, arbitration/error frames and broader negative fixtures.
- **J1708/J1587 (partial):** fixed 9,600 profile, MID/raw data editor, checksum auto-calc, 21-byte boundary, priority 1-8, idle-high count, collision switch and independent virtual transceiver/source-node state. Still needed: PID catalog provenance, corrupt-checksum/framing fixtures, measured message gaps, detailed backoff/retry, stuck bus/noise waveforms, and received serial-device integration.
- **Cross-link workflow:** a timeline showing Save Request fixture over J1708 then Program fixture over J1939, with target/file/calibration identity and simulated authorization/recovery gates. This tests application sequencing only; it is not a NavKal/Allison DOC clone or ECU/TCU emulator.
- **Virtual hardware:** independent per-link controller/transceiver state, adapter firmware version/capability declaration, timestamps, packet loss, reset/brownout, disconnected cable, and bus errors. Software controls are clearly distinct from the physical bench simulator controls.

## Physical simulator/emulator hardware

The app-only simulator covers software boundaries. A separate physical test node is needed to exercise the actual Mac/iPhone adapter and firmware. Implement a controlled J1939 CAN simulator and a controlled J1708/J1587 simulator with their own compliant physical layers, powered from a current-limited isolated bench supply and no vehicle connection. The J1708 simulator should transmit known MID/PID/checksum fixtures, exercise collision and timing cases, and expose a device-side configuration/telemetry control API over a separate USB link. Do not use the CAN network itself as the simulator control channel.

The Leonardo sketch currently bridges classic CAN only. J1708 firmware, complete dual-link transport records, physical serial integration, and simulator-node firmware remain to be implemented and hardware-tested. The J1708 simulator should be built as a compliant isolated MCU node with a separate USB management channel, not as a generic USB/RS-485 dongle. The FT232H path needs a device-side timing MCU for J1708. Renode can help with CPU logic only after exact peripherals are matched; it does not establish physical-layer fidelity.

## Acceptance test matrix

| Test class | Pass evidence |
|---|---|
| J1939 unit/protocol | Identifier/PDU extraction, payload bounds, DM parsing, transport reassembly, timestamps and error handling from known fixtures |
| J1587 unit/protocol | MID/PID retention, checksum and length validation, timestamp/gap behavior, malformed-frame reporting |
| J1708 firmware timing | Logic analyzer capture at 9,600 8N1; idle and priority timing, echo collision detection, bounded retry and safe stuck-dominant shutdown |
| Dual-link integration | Simultaneous captures have distinct channels, monotonic timestamps, correct source labels and independent disconnect/error states |
| Device simulator | GUI sets scenarios and reads simulator node state over separate control path; verified expected bytes appear on a physical bench bus |
| Workflow integration | Simulated J1708 Save Request event precedes simulated J1939 Program event; incorrect target, interruption, unsupported calibration and rejected authorization fail closed |
| Mac/iPhone QA | Each platform connects to the physical bench adapter/simulator path and exercises scan, live-data fixtures, fault reports, captures, VIN/profile, flash-project preparation and navigation; screenshot/notes are recorded per device |

## Test boundaries

No actual ECM/TCM software emulator, proprietary Navistar/Allison calibration file, seed/key method, or target-specific flash implementation is included unless a lawful, authorized, target-specific source is documented and compatible fixtures are obtained. Synthetic readings remain synthetic. A software loopback passing is not hardware-in-the-loop QA. A physical simulator passing is not proof of vehicle compatibility.

## References

- [Navistar IK2600282 (NHTSA PDF)](https://static.nhtsa.gov/odi/tsbs/2025/MC-11019110-0001.pdf)
- [TI AN-915: J1708 physical layer](https://www.ti.com/lit/an/snla038b/snla038b.pdf)
- [U.S. DOT J1708/J1587 training reference](https://www.its.dot.gov/StandardsTraining/modtransit5/sup/mt5sup.pdf)
- [Renesas AN1990: J1708 physical layer with RS-485 transceivers](https://www.renesas.com/en/document/apn/an1990-rs-485-transceivers-j1708-physical-layer-applications-heavy-duty-vehicles)
- [Allison electronic diagnostics and tools](https://www.allisontransmission.com/aftermarket-and-channel/parts-and-service/service-tools--information/electronic-diagnostics--service-tools)
