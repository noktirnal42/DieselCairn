# DieselCairn — RE300 / PB305 Service Workspace

**Project:** 2009 International RE300 rear-engine school bus · factory/VIN model PB305 · MaxxForce DT · owner-reported Allison 3000 Series 3000PTS  
**Current app name:** DieselCairn  
**Platforms:** macOS first-class workstation, iOS/iPadOS companion  
**Document status:** Version 6, evidence-led scope; replaces the incomplete V5 prompt.

## Product mission

Build a polished native app to diagnose and repair the user's 2009 International RE300: engine, ECM, transmission, and TCM. Core workflows are vehicle records, module identity, fault reading/clearing where verified, live data, engine/transmission/ECM/TCM swaps and supported pairing, and authorized calibration/flash preparation and programming. Investigate sixth-range support for the installed Allison configuration using its actual transmission, TCM, calibration, speed-ratio, tire, and OEM approval data.

Build a companion Flash Studio that can import documented OEM packages and raw images, inspect and compare supported formats, verify checksums/signatures, create calibration projects, and execute only verified target-specific programming sequences. It must preserve source bytes, target identity, provenance, compatibility decisions, approvals, and a complete operation log. Do not guess proprietary formats, firmware maps, security keys, or target compatibility.

The app includes a multi-link bench simulator for J1939 over classic CAN and J1587 over J1708, plus independent simulated ECU/TCU/adapter nodes and separate physical simulator-node controls. Values/faults must always be marked simulated. The applicable Navistar MaxxForce procedure uses J1708 for Save Request and J1939 for Program; confirm target applicability and all exact procedures before live use. Hardware/protocol implementations must be tested on software fixtures, isolated physical CAN and J1708 benches, and the user's MacBook and physical iPhone before release.

## Scope boundaries

- **Now:** one vehicle configuration: this 2009 International RE300 / PB305 school bus, MaxxForce DT, and an owner-reported Allison 3000 Series 3000PTS transmission. Preserve RE300 as the badge/series name and PB305 as the school-bus model number. Verify the transmission nameplate and collect the actual VIN plus exact engine, ECM, and TCM identity before selecting target profiles.
- **Later roadmap only:** other International/IC Bus makes, models, and years; standard passenger-vehicle OBD-II; other trucks and fleet vehicles; boats, aircraft, and other craft. Do not imply this release supports them.
- Maintain three requested adapter paths: STM32 + CAN controller, Arduino USB-CDC + CAN controller, and FT232H MPSSE + CAN controller. iOS requires a BLE gateway. “Compatible architecture” is not a claim of vehicle or hardware validation.
- Support authorized diagnostics and calibration work. Preserve official authentication and OEM/Allison approval workflows. Never bypass module security or fabricate signed calibrations.

## Source-truth rules

1. Distinguish proven app code, standard protocol references, target-specific evidence, simulated behavior, and unverified assumptions.
2. A PGN/SPN in a standard J1939 data dictionary does not prove a particular RE300 module broadcasts or supports it.
3. A VIN decoder provides basic vehicle facts, not installed ECM/TCM identity, calibration compatibility, six-speed hardware, or authorization.
4. The owner reports an Allison 3000 Series 3000PTS. Verify that identification against the transmission nameplate; the push-button selector/display alone does not establish TCM generation, installed gear hardware, calibration, or sixth-range eligibility.
5. Any live write requires verified module and file identity, matching protocol profile, backup/recovery method, stable power, interruption behavior, completion verification, and evidence log. Unknown targets fail closed.
6. Never use simulation data to populate live vehicle records or imply a vehicle test passed.

## Product design

- Brand: DieselCairn. Visual language: dark instrument-room surfaces, warm signal orange, calm status mint, legible engineering typography, custom waveform/axle mark. Avoid generic automotive-dashboard clutter.
- Start with a vehicle-aware workspace: Overview, Diagnostics, Vehicle profile, Flash Studio, and Bench simulator.
- Use a clear persistent source state: Simulated, Replay, or Live (with adapter and module identity). Use explicit stale-data and disconnected states.
- Keep common shop tasks visible: scan/read codes, save report, inspect module IDs, compare calibration IDs, build a flash project, resume a service record.
- Forms must have practical keyboard entry on Mac, touch-sized controls on iPhone, Dynamic Type, VoiceOver labels, high contrast, and confirmation/error states.
- Preserve VIN and service records locally by default. Disclose that VIN decoding sends VIN/model year to NHTSA vPIC. Never store portal passwords or private security tokens in project notes.

## Phased engineering plan

### Phase 0 — Evidence and identity
- Obtain VIN and photo/record of RE300 chassis plate, engine serial/rating label, Allison transmission model/serial tag, shifter/control panel, ECM and TCM identifiers, current calibration/CINs, and available diagnostic reports.
- Confirm target ECU/TCU generations, bus physical layers/bit rates, diagnostic connector/wiring, and official OEM/Allison service path.
- Correct all protocol/hardware claims in `ProtocolSpec.md`, `HardwareDesign.md`, `AdapterProtocol.md`, and `FlashStudioSpec.md`.

### Phase 1 — App foundation and bench
- Shared native Swift model/decoder and responsive macOS/iOS SwiftUI surfaces.
- Vehicle profile with NHTSA VIN decode suggestions plus manual corrections and module identity.
- GUI CAN simulator for standard 29-bit frames, configurable scenarios, raw-frame trace, timing, fault injection, recording/replay, and export.
- Virtual hardware controls for adapter device profiles, MCU/controller/transceiver/firmware state, independent bus/adapter bitrates, supply, termination, load, and packet loss.
- Implement separate J1708/J1587 simulator, firmware, physical simulator node and adapter PHY; coordinate two-link workflows with J1939. Verify connector topology and exact authorized NavKal workflow before live use.
- No fake physical link; simulated source remains visible.

### Phase 2 — RE300 read-only live diagnostics
- Validate one chosen interface on an isolated CAN bench, then vehicle listen-only.
- Identify modules; implement verified ECM and TCM DTC, live-data, and report paths. Add raw capture and per-field provenance.
- Test a second path before claiming multi-adapter compatibility. Keep adapter interfaces shared across paths.

### Phase 3 — Flash Studio and authorized service procedures
- Document supported OEM file containers, raw image structure, checksums/signatures, calibration IDs, address maps, exact programming protocol, security/authentication handoff, and recovery.
- Build immutable import/compare/validation packages; bind each project to VIN and observed module identity. Add ECM/TCM swap-pairing checklist and supported procedure.
- Implement a flash simulator with recorded power-loss, timeout, mismatch, and recovery scenarios.
- Enable live programming only for a supported exact target profile after bench and vehicle validation.

### Phase 4 — Allison sixth-range assessment
- Read Allison series/model, transmission serial, TCM generation/serial and calibration, ratio/configuration, and vehicle/tire information.
- Track OEM approval and Allison calibration request evidence. Check hardware and ratio requirements before any plan is buildable.
- Only then implement the authorized reprogram/recovery path. Log old/new calibration and verify shift-range operation by a qualified validation protocol.

### Phase 5 — Release readiness
- Run CI/build checks, protocol fixtures, simulator and adapter emulation where available, HIL bench checks, and physical MacBook/iPhone visual and functional QA.
- Maintain the QA record in `docs/DEVICE_QA.md`; no release claims until each required gate has evidence.
- Use Git feature branches (`codex/<topic>`), focused commits, reviewable diffs, signed release tags, and no secrets, VINs, raw vehicle dumps, or licensed calibration files in Git.

## Hardware and simulator rules

- Never connect an unverified prototype transmitter to a vehicle. Default boot state is receive-only/listen-only. Termination is off by default.
- MCP2515 is a CAN controller with external oscillator and transceiver requirements; FT232H is a USB-to-MPSSE bridge. STM32F031K6 and ATmega32U4 do not provide a CAN controller; STM32F031K6 also lacks native USB.
- Use a PC CAN simulator for app/protocol behavior, Renode where its STM32F0 model matches the selected firmware peripherals, and physical hardware in a current-limited/isolated bench. Emulation of external controllers, transceivers, USB bridges, CAN electrical behavior, and power faults must be stated explicitly.
- Record exact board revision, BOM, oscillator, transceiver, isolation, termination, connector pinout, power conditioning, firmware version, and tested bitrate before publishing construction instructions.

## Acceptance criteria

- The app identifies its simulator/replay/live source at every relevant surface.
- VIN decode is optional, recoverable on network failure, and never overrules manual module labels.
- ECM and TCM identities remain separate, with saved reports and provenance.
- Unsupported or mismatched file/target pairs are blocked with a useful explanation.
- The simulator can drive the same decoder and protocol boundary used by supported adapters and produce exportable trace fixtures.
- A real vehicle write is not reported successful without a post-write identity read, fault scan, operation log, and documented validation evidence.
- Physical MacBook and physical iPhone QA is completed and recorded.
