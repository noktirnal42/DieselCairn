# DieselCairn User Guide

DieselCairn is an RE300 service workspace for diagnosing and repairing a **2009 International RE300 / PB305 with MaxxForce DT and an owner-reported Allison 3000 Series 3000PTS transmission**. Confirm the transmission nameplate before target-specific service work. Later expansion may add other makes/models/years, standard passenger-vehicle OBD-II, and other craft; those are not current support claims.

## Current app status

The macOS and iOS app targets share a SwiftUI service workspace. It opens disconnected with no generated readings. A user may explicitly start an isolated multi-link bench simulation for J1939/CAN and J1587/J1708 testing. No source code in this version has a validated live RE300 adapter connection or executable ECM/TCM write path. Flash Studio currently imports an OEM package or raw image, fingerprints it, and builds an auditable project file; it does not claim that the file is compatible or flashable.

## Start a session

1. Launch DieselCairn. It starts disconnected with no live or simulated readings. Choose the isolated bench simulator when you want test traffic. J1939 and J1587/J1708 must be separate protocol channels and every virtual value must remain labeled simulated. The current J1708/J1587 software simulator and physical simulator-node firmware are engineering work in progress; do not interpret their presence in a plan as completed hardware support.
2. Open **Vehicle profile** and confirm the owner-reported Allison 3000PTS against its nameplate. Enter the VIN, engine serial, ECM serial/part number and calibration ID, transmission serial, TCM serial, and TCM calibration ID.
3. Use **Decode VIN** to request available basic vehicle fields from NHTSA vPIC. The app keeps the decoded NHTSA model code/series separate from the physical chassis model label. Check each returned value against the title/door label and service records. VIN decoding does not provide engine serial, ECM/TCM identifiers, calibration IDs, or transmission serial/model when vPIC has no field value.
4. Record module IDs and calibration information from manufacturer-supported diagnostic software or labels. The electronic push-button selector alone is not enough to identify the transmission series or gear capability.
5. Use **Overview** and **Diagnostics** to view data only after starting the virtual bench. Values, faults, gear, and frames carry a simulation label and are not vehicle readings.

## Vehicle profile and privacy

The profile is stored locally on the current device by default. VIN decoding sends the VIN and optional model year to the NHTSA vPIC API over HTTPS. The app must disclose this request before sending it. Do not put account passwords, OEM portal credentials, or private security keys in the profile or project notes. Future cloud synchronization is not enabled.

## Flash Studio

Flash Studio creates a portable project record for either an engine ECM or transmission TCM:

1. Confirm the vehicle and module identity fields are complete.
2. Select the target module and import the authorized OEM package or raw image you intend to investigate.
3. Review the original file name, byte count, and SHA-256 fingerprint.
4. Add the source, intended service action, and any approval/evidence references to notes.
5. Select **Build flash project** to export the `.json` project manifest with the source payload embedded. This prepares an audit package; it does not produce a running flash program.

The manifest is a **project record**, not executable instructions. It preserves the original payload and records a blank execution profile until format, module compatibility, authorization, transport, recovery, and validation requirements are met. Do not rename it as a vendor calibration or load it into an ECU/TCU tool.

## Pairing after a swap

Use the vehicle record to preserve the before/after relationship for an engine, ECM, transmission, or TCM swap. Record donor and installed serials and calibration IDs, VIN, approval documentation, and all diagnostic reports. The live pairing wizard will only be enabled for a confirmed module family and a manufacturer-supported procedure. Do not use a generic write when module IDs or calibration compatibility are uncertain.

## Sixth range

DieselCairn will first identify the installed transmission and TCM, capture the existing calibration, and collect the evidence required for a gear-range request. Some Allison units require additional internal hardware; higher maximum range requests can require OEM approval, specific N/V checks, tire-rating review, speed limiting, and other documentation. The app will guide the user through verified service requirements and the authorized programming workflow. It will not present a universal “unlock” action based only on a five-speed display.

## Adapter development status

The intended app architecture keeps three requested hardware routes under evaluation:

- STM32 serial adapter with external CAN controller/transceiver and a separate USB bridge
- Arduino USB-CDC adapter with external CAN controller/transceiver
- FT232H MPSSE host with external MCP2515/transceiver

The iOS app requires a BLE gateway; USB-C device support is not assumed. All live paths remain unavailable until the separate CAN/J1939 and J1708/J1587 electrical designs, correct bus timing, receive-only behavior, driver/firmware, and RE300 interoperability are verified. Navistar IK2600282 documents J1708 for a Save Request step and J1939 for programming on relevant 2007-09 MaxxForce engines; confirm this applies to the actual engine/module in this bus. Exact connector wiring and adapter support remain to be verified. See `HardwareDesign.md`, `AdapterProtocol.md`, `ProtocolSpec.md`, and `docs/SIMULATOR.md`.

## Git and engineering records

Use Git for source, firmware, protocol profiles, parts revisions, and build instructions. Work on short feature branches (`codex/<topic>`), keep commits focused, do not commit secrets, calibration payloads, VINs, or private logs, and document evidence for hardware tests. Exclude `.build`, derived data, and generated logs from version control. Tag a release only after the applicable Mac/iPhone and bench/vehicle QA has passed.

## QA plan

When the implementation is ready, validate the app on this Mac and the user's physical iPhone against separate physical J1939 and J1708/J1587 bench simulators through the actual adapter transport. Test the multi-link Save Request/Program sequence as a simulator state machine, not a real ECU write. For later vehicle validation, record the VIN, serials, module IDs, calibration IDs, supply voltage, adapter revision, firmware revision, captures, faults before/after, and recovery outcome. Physical hardware tests and publication are not yet completed.

## Troubleshooting

- **VIN decode fails:** vPIC may be unavailable or have incomplete commercial-vehicle data; fill and verify fields manually.
- **Unknown transmission:** capture the transmission nameplate and read TCM identity with supported service equipment.
- **No live adapter:** current release supports the simulator only; adapter cards are engineering targets, not connected devices.
- **Project cannot be flashed:** expected until an exact module/file/profile match and validated writer are available.

See `ProtocolSpec.md`, `HardwareDesign.md`, `AdapterProtocol.md`, and `FlashStudioSpec.md` for engineering requirements and evidence status.
