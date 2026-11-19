# DieselCairn RE300 Protocol Profile

**Scope:** 2009 International RE300 school bus (factory school-bus model PB305) with MaxxForce DT and the installed electronically controlled Allison transmission. First-generation system scope includes classic J1939 over CAN and J1587 over J1708 where the identified vehicle/module procedure uses them. Additional makes, model years, passenger-car OBD-II, marine, and other craft are future expansion work.

## Protocol stack and simulator scope

| Layer / network | Role in DieselCairn | Required simulator behavior | Status |
|---|---|---|---|
| J1939-11/21 over classic CAN | 29-bit extended CAN data link and network/application message transport | Arbitration, 250/500 kbit/s profiles only when selected for a fixture, 8-byte frames, address claims, PDU1/PDU2 PGNs, TP.CM/TP.DT segmentation, bus-off/error counters, timing and replay | Existing app simulator covers a subset of classic frames; complete stack and target bitrate remain unverified |
| J1939-73 | Diagnostic messages such as DM1/DM2, clear/read request behavior per target support | Lamp states, multi-DTC payloads, SPN/FMI/occurrence parsing, transport-protocol reassembly, request timeout/retry and negative/unsupported response cases | DM1 fixture path partial; target-specific requests require service evidence |
| J1708 physical/data link | 9,600-baud, two-wire dominant/recessive network and access arbitration | 8N1, 10-bit-time idle requirement, priority delay, echo/collision detect, backoff/retry, bus idle/noise and error cases | Not implemented in physical adapter today; simulator model being added |
| J1587 message layer over J1708 | MID/PID/data/checksum messages and diagnostic/informational values | MID, PID length/data tables, checksum validation, 21-byte message limit for standard profile, message gap/framing, unsupported PID, malformed checksum and overflow cases | New message model added; vehicle-specific PID dictionary still requires licensed/manual evidence |
| OEM programming workflows | Navistar service sequence and Allison TCM services | Explicit sequence-state simulator, authorization gates, wrong target/file, power loss, transport failure, resume/recovery, audit record; never treat generic bus simulation as a real write | Target protocol and production programming implementation are not verified |

For this MaxxForce year range, Navistar IK2600282 states that NavKal uses J1708 for “Save Request” and J1939 for “Program”. That is a workflow fact, not a complete transport specification or permission to reproduce NavKal. The TSB also describes 2007–09 MaxxForce diagnostic connections. Simulator scripts must represent these as two separate links and preserve their event order. The actual PB305 connector, pinout, adapter, engine identity, and applicability must be confirmed from its build records and authorized service data before live use. [Navistar IK2600282](https://static.nhtsa.gov/odi/tsbs/2025/MC-11019110-0001.pdf).

J1708 is not generic RS-485. Use a J1708-compliant dominant/recessive transceiver circuit and collision handling; J1587 is the message protocol above it. A J1587 byte array must never be put into a J1939 PGN or CAN frame. The simulator must identify network, direction, source label, timestamp, framing validity, and whether the event is simulated, replayed, or a physical capture. [TI AN-915](https://www.ti.com/lit/an/snla038b/snla038b.pdf), [U.S. DOT J1587/J1708 training reference](https://www.its.dot.gov/StandardsTraining/modtransit5/sup/mt5sup.pdf).

## Evidence and status

The previous draft contained invented PGNs (for example `0x0CFF` for engine speed), decimal SPNs written as hexadecimal fragments, a nonexistent `0x27G` PGN, and generic seed/key and CRC claims that were not tied to an observed RE300 module. Those entries are withdrawn. No writes, flash commands, security algorithms, or vehicle-specific parameter availability are established by the source tree today.

Standard J1939 broadcast definitions below are protocol references, not proof that this bus transmits them, that the MaxxForce calibration uses them, or that an Allison TCM exposes equivalent data. Every live mapping must be confirmed against a captured frame from this bus, module identity, the licensed/authoritative J1939 data dictionary, and service information for the identified module.

| PGN (decimal / hex) | Standard group | Relevant SPN | Standard meaning | DieselCairn status |
|---|---|---:|---|---|
| 61444 / `0xF004` | EEC1 | 190 | Engine speed, bytes 4–5, 0.125 rpm/bit | Standard decoder + synthetic simulator only; RE300 presence unverified |
| 61443 / `0xF003` | EEC2 | 92 | Engine percent load at current speed | Candidate mapping; bus capture and calibration confirmation required |
| 65262 / `0xFEEE` | ET1 | 110, 175 | Coolant temperature (byte 1, 1 °C/bit, −40 °C offset); engine oil temperature (bytes 4–5, 0.03125 °C/bit, −273 °C offset) | Standard decoder + virtual simulator; RE300 presence and availability unverified |
| 65266 / `0xFEF2` | LFE1 | 183 | Engine fuel rate (bytes 1–2, 0.05 L/h per bit) | Standard decoder + virtual simulator; RE300 presence unverified |
| 65270 / `0xFEF6` | IC1 | 102, 105 | Intake manifold pressure; intake manifold temperature | Candidate mappings; field positions/scaling must be checked against current J1939DA |
| 65269 / `0xFEF5` | AMB | 171 | Ambient air temperature (bytes 4–5, 0.03125 °C/bit, −273 °C offset) | Standard decoder + virtual simulator; RE300 presence unverified |

The separate virtual transmission test node emits generic ETC2 (PGN 61445 / `0xF005`) from source address `0x04`, with a configurable 1–6 test gear and corresponding selected/current range bytes. Its field layout is based on a non-Allison third-party TCU communication document and is not an Allison or RE300 profile. See the [virtual simulator fidelity notes](docs/SIMULATOR.md#virtual-hardware-gui) and [PCS J1939 communication document](https://powertraincontrolsolutions.com/download/Released/Public/Developer_Files/PCS%20J1939%20Messages%20v2_1.pdf).

PGNs use decimal values in the J1939 standards; hexadecimal values above are the same numbers in base 16. J1939 CAN identifiers are 29-bit extended identifiers. PGN extraction must handle PDU1 destination-specific PGNs by clearing the PDU-specific byte when PF < 240. Classic CAN payloads are at most 8 bytes; transport-protocol messages must be reassembled before decoding.

## Transmission and diagnostic data

The Allison product family and module generation are not yet identified. The push-button electronic selector confirms an electronic control system, but it does not establish series, generation, build date, maximum gear range, or calibration compatibility. The live profile must collect the transmission nameplate and read the TCM serial/part number, software/calibration ID, and available diagnostic identity before enabling any action.

The app must support a distinct ECM and TCM diagnostic record, including module address/identity, active and previously active DTCs, occurrence/count data when present, freeze-frame/snapshot records when available, and raw-frame provenance. Implement DM1/DM2 and any manufacturer-specific diagnostic services only after checking the applicable J1939-73/service documentation and captured target behavior. Never display a simulated code as a vehicle fault.

## ECM/TCM pairing and calibration changes

Pairing after engine/transmission/module swaps is a first-class RE300 service workflow, but exact procedures depend on the installed engine family/rating, ECM, TCM generation, transmission serial number, vehicle configuration, and manufacturer support. The app must record old/new module identifiers, original and replacement calibration IDs, VIN and serials, the approved source file, and results. It must not synthesize pairing credentials, bypass authentication, or guess a calibration from VIN alone.

## Sixth range investigation

Sixth-range availability is a compatibility and authorization check, not a generic flag write. Allison service information says 1000/2000 Series units built after 2006-06-28 have the necessary internal hardware, subject to specific N/V ratio requirements; 3000/4000 Series can achieve six speeds. Allison also requires OEM approval for a maximum gear-range increase, with additional requirements for approved tire speed rating, VIN/transmission serial, vehicle acknowledgement, and potentially speed limiting. Some OEMs are restricted to five-speed service releases. DieselCairn must identify the actual transmission and TCM and show the applicable approval/evidence before it creates an authorized programming plan.

No sixth-gear toggle, proprietary calibration edit, security bypass, or write routine is implemented in this repository. The simulator may demonstrate the workflow and will label its state as simulated.

## Flash project requirements

DieselCairn Flash Studio accepts a source file and creates an auditable project containing:

- Vehicle profile and VIN decode source/date
- Target module (ECM or TCM), observed module identity, calibration ID, and transmission identity where relevant
- Original file name, size, SHA-256, and immutable source bytes
- Package format/version, operator notes, evidence/approval references, and selected verified target profile
- Explicit state: draft, compatibility-reviewed, bench-validated, or authorized for vehicle use

Raw image formats, OEM package containers, checksums/signatures, address maps, write/erase routines, recovery procedures, and completion criteria remain target-specific and must be documented before an executable flash plan can be generated. Unknown or mismatched targets fail closed. Live write execution must include stable power requirements, backup and recovery path, voltage/communications monitoring, interruption handling, post-write identification, DTC rescan, and an audit log.

## Adapter protocol

The app and each adapter will share a documented transport-neutral frame interface. Each implementation must state CAN bitrate, oscillator, transceiver, bus voltage range, termination, isolation, receive/transmit state, timestamp semantics, and fault reporting. Hardware must start in listen-only mode. Read-only diagnostics must be proven before any transmit or programming capability is enabled.

Current product paths retained for engineering evaluation:

1. STM32 MCU + external CAN controller/transceiver + a valid USB serial bridge (the STM32F031K6 has no native USB or CAN controller).
2. Arduino USB-CDC board + external CAN controller/transceiver (board-specific SPI pins and oscillator must be verified).
3. FT232H MPSSE host + external MCP2515 and transceiver (FT232H is a USB-to-MPSSE bridge, not a CAN controller).

BLE is a separate mobile gateway path. It requires a BLE-capable controller/gateway, a defined GATT service and framing, and a measured latency/reliability profile. None of these physical paths is currently validated against the RE300.

## References

- [SAE J1939 Data Dictionary reference via ISOBUS](https://www.isobus.net/isobus/pGNAndSPN/17187?type=PGN): PGN 65270 and associated SPNs.
- [ISOBUS SPN 110 mapping](https://www.isobus.net/isobus/pGNAndSPN/17119?type=SPN): Engine Coolant Temperature is linked to PGN 65262.
- [ISOBUS SPN 183 mapping](https://www.isobus.net/isobus/pGNAndSPN/17166?type=SPN): Engine Fuel Rate is linked to PGN 65266.
- [NHTSA-hosted Navistar IK2600282](https://static.nhtsa.gov/odi/tsbs/2025/MC-11019110-0001.pdf): 2007–2009 MaxxForce programming information and engine swap support constraints.
- [Allison SIL 19-TR-08 Rev. D](https://static.nhtsa.gov/odi/tsbs/2020/MC-10185305-0001.pdf): maximum gear-range increase policy and hardware/approval requirements.
- [Allison Service Tip 1321](https://allisontransmission.bynder.com/m/26fc11925d20487/original/Allison-DOC-for-6th-Generation-Controls-Release-1321.pdf): authenticated programming requirements for 6th Generation controls.
