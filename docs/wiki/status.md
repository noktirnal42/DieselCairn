# Project status and completion gates

## Implemented in source today

- Native SwiftUI macOS/iOS app targets and app branding assets.
- VIN decode/profile foundation and local flash-project manifest.
- Partial J1939 frame model/decoder and software-only synthetic CAN simulator.
- Swift adapter framing codec and Arduino Leonardo CAN-only sketch prototype.
- Initial MCP server and app navigation.
- J1587 message model with length/checksum validation and J1708 timing helper (software functions only).

## Not yet complete or proven

- Full J1939 transport protocol, diagnostics and request behavior for exact PB305 modules.
- Complete GUI J1708/J1587 simulator controls and common two-link event model.
- J1708 adapter firmware and physical simulator-node firmware.
- Dual-link reviewed schematic, board, verified parts list and HIL hardware.
- STM32 target firmware, FT232H host service, production USB/BLE adapter transports.
- Allison 3000PTS nameplate verification; OEM/Allison authenticated read/write workflows and exact ECM/TCM profile.
- Physical Mac/iPhone end-to-end test against physical adapters and bus simulators.
- Vehicle validation (bus, vehicle and hardware are unavailable in this development context).

## QA status

Update `docs/DEVICE_QA.md` with date, hardware identity, app build, tested route, screenshot/artifact path and pass/fail evidence for every platform. Build success is not workflow QA. Simulator result is not a live bus test. Mark external blockers precisely.

