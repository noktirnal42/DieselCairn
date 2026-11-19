# DieselCairn

A macOS/iOS service workspace for the **2009 International RE300 / PB305 with MaxxForce DT and an owner-reported Allison 3000 Series 3000PTS transmission**. Verify the transmission nameplate before target-specific work.

`RE300` is the rear-engine series badge; this owner's school-bus model number is `PB305`. `PC305` is the corresponding RE commercial-bus VIN model code. Front-engine codes vary by year and application. See the year-specific details in [VIN and service research](docs/FIRMWARE_RESEARCH.md). The owner reports an Allison 3000PTS; the nameplate, TCM generation/serial, calibration, and sixth-range eligibility still require confirmation.

## What works in this build

- Native SwiftUI service workspace for macOS and iOS.
- Locally saved vehicle profile with optional NHTSA VIN decoding.
- J1939 standard frame model/decoder for the limited documented candidate parameters.
- Stopped-by-default virtual CAN bench with scenario ECU/TCU nodes, manual J1939 frame injection, raw trace export/replay, and GUI controls for virtual bus and adapter faults.
- Virtual hardware screen controls declared adapter profiles, MCU/controller/transceiver/firmware stages, bus/adapter bitrates, power, termination, bus load, and deterministic frame loss. Frames reach the app only after virtual adapter packet decoding.
- Flash Studio imports an OEM/raw image, fingerprints it, and exports an auditable project container containing the source bytes and vehicle/module record.
- Arduino Leonardo + MCP2515 adapter firmware scaffold and a shared COBS/CRC serial-frame codec.

## What is still under engineering validation

The software simulator is not an ECM/TCM firmware emulator, electrical CAN simulator, physical adapter emulator, or evidence of vehicle compatibility. The live RE300 adapter paths, ECM/TCM diagnostic transactions, supported fault clearing, ECM/TCM pairing procedures, OEM calibration parsing, and vehicle flash execution are not yet validated. Flash Studio's JSON is a project record, **not an executable flash program**. The first release must verify the actual Allison series, TCM generation/serial/calibration, engine ECM identity, bus wiring/bit rate, and authorized file/workflow before enabling live writes.

## Build the apps

Requirements: Xcode 15 or later, Swift 5.9+, and XcodeGen.

```sh
xcodegen generate
xcodebuild -project DieselCairn.xcodeproj -scheme DieselCairnMac -destination 'platform=macOS' CODE_SIGNING_ALLOWED=NO build
xcodebuild -project DieselCairn.xcodeproj -scheme DieselCairnMobile -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO build
```

The package-only Mac executable can also be built with `swift build --product DieselCairnMac`. For an iPhone build, set the development team in the [local signing configuration](docs/DEVICE_QA.md#local-iphone-signing) before building the mobile scheme for the paired device.

Run `swift test` for package tests and `python3 scripts/qa_mcp.py` for the MCP regression harness. To run the mobile UI suite, address a booted simulator by ID.

```sh
xcodebuild -project DieselCairn.xcodeproj -scheme DieselCairnMobile \
  -destination "platform=iOS Simulator,id=$SIMULATOR_ID" \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  CODE_SIGNING_ALLOWED=NO test
```

## Documents

- [Master scope and phased plan](master_prompt.md)
- [User guide](UserManual.md)
- [RE300 J1939 profile and evidence status](ProtocolSpec.md)
- [Hardware paths and parts planning](HardwareDesign.md)
- [Adapter protocol](AdapterProtocol.md)
- [Flash Studio requirements](FlashStudioSpec.md)
- [Simulator guide](docs/SIMULATOR.md)
- [Virtual bench integration tests](Tests/DieselCairnCoreTests/VirtualBenchIntegrationTests.swift)
- [Authorized firmware/calibration and VIN research](docs/FIRMWARE_RESEARCH.md)
- [Physical device QA gates](docs/DEVICE_QA.md)
- [Brand mark source](Sources/Assets/Brand/DieselCairnMark.svg)
