# DieselCairn Adapter Protocol

## Goal

Define one transport-independent record contract for the app, firmware, host simulator, and hardware-in-the-loop fixtures. DieselCairn's PB305 profile needs independent J1939/CAN and J1587/J1708 channels. This document is a design baseline, not evidence that any adapter is implemented or vehicle-ready.

## Multi-link protocol record

Each event must carry a `network` enum (`j1939CAN`, `j1587J1708`), direction, source (`SIMULATOR`, `REPLAY`, `LIVE`), monotonic and wall timestamps, adapter sequence, validity/error flags, and adapter identity. A network-specific payload is mandatory; do not coerce J1587 messages into CAN identifiers.

- J1939 event: 29-bit identifier, extended flag, classic CAN payload `0...8`, bitrate, controller status, and optional J1939 TP reassembly metadata.
- J1587 event: raw bytes including MID and checksum (`2...21` bytes for this profile), checksum/framing validity, 9,600-baud timing, idle interval, priority class, retry/collision status, and optional parsed PID records.
- Physical adapter capabilities advertise the links independently. A dual-link profile requires two separately protected transceiver channels and cannot imply one shared wire pair.
- Start physical operation listen-only. J1708 transmission requires adapter-side 10-bit-time idle qualification, priority delay, echo comparison/collision detection, and bounded retry. Host scheduling alone is not a timing guarantee.
- OEM programming commands are not general-purpose frame transmit. They require a separate target workflow and reviewed approval; generic simulator/MCP tools cannot authorize them.

## Frame record

Every received/sent frame has:

- 29-bit CAN identifier and explicit extended/standard flag
- Classic CAN payload length `0...8` and bytes; future CAN-FD must be a separate capability
- Monotonic timestamp plus optional wall-clock timestamp
- Direction, channel, adapter sequence, and receive error/status flags
- Explicit listen-only/transmit-enabled adapter state

The host must reject malformed lengths, out-of-range IDs, unsupported CAN-FD records, duplicate sequence corruption, and stale/disconnected streams. J1939 PGN parsing is separate from transport framing.

## Common binary framing (Arduino implementation present; host integration not yet implemented)

Protocol v1 uses a version byte, type byte, 16-bit sequence, 16-bit payload length, payload, and CRC-16/CCITT-FALSE over the header and payload. The packet is COBS-encoded and terminated by `0x00`. Multi-byte header, CAN identifier, and timestamp fields use network byte order. Serial runs at 115200 baud. The Swift codec and Arduino Leonardo firmware implement this frame envelope; the desktop/mobile production transport integration is still open.

Message types currently defined: HELLO, CAPABILITIES, SET_MODE, CAN_RX, CAN_TX, TX_RESULT, BUS_STATUS, ERROR.

- `CAN_RX` payload: 29-bit identifier in four bytes, DLC byte (`0...8`), CAN data bytes, 32-bit MCU `micros()` receive timestamp. Total payload length is `9 + DLC`.
- `CAN_TX` payload: 29-bit identifier in four bytes, DLC byte, CAN data bytes. Total payload length is `5 + DLC`; the firmware permits it only after the physical TX arm jumper and host SET_MODE request.
- `TX_RESULT` payload: one byte from the MCP2515 send result.
- `BUS_STATUS` payload: CAN initialization status and transmit-armed state.
- `CAPABILITIES` payload: family byte, mode byte, TX-armed byte, flags byte, 16-bit CAN feature flags, and 32-bit nominal bitrate in big-endian order (10 bytes total).

Firmware starts in LISTEN_ONLY and will not accept CAN_TX until the local hardware interlock is present. It does not implement ECM/TCM programming.

BLE uses the same logical message model over a documented GATT characteristic service, with fragmentation/reassembly, MTU negotiation, notification back-pressure, pairing/authentication, and disconnect recovery. It is not interchangeable with the USB serial transport.

## Hardware-path notes

### STM32F031K6

It has neither native CAN nor native USB. Use an external CAN controller and transceiver, and a USB-to-UART bridge or a different MCU. Exact clock tree, SPI pins, reset/interrupt routing, power protection, and firmware toolchain must be fixed before a BOM or construction guide is released. Candidate Renode STM32F0 models require a peripheral-by-peripheral match review before they can count as firmware emulation.

### Arduino USB-CDC

Choose a specific ATmega32U4 board and board revision. The MCP2515 connects through the board's actual SPI pins (often ICSP on 32U4 boards), with documented interrupt and chip-select pins. Pin labels and voltages differ across board variants. Select oscillator-aware timing, transceiver, protection, and termination parts from their datasheets. Firmware library and version must be pinned.

### FT232H

The FT232H MPSSE drives SPI to an MCP2515; it is not itself a CAN interface. The Mac host needs a supported FTDI D2XX/MPSSE access path, device claim/permission handling, SPI timing, MCP2515 reset/configuration, receive buffers, and error reporting. A mock FTDI device can test command sequencing, but not actual USB, SPI signal integrity, controller behavior, transceiver, or CAN bus.

## Electrical requirements before vehicle use

No pin-level vehicle connection or construction procedure is approved yet. The electrical design must identify the RE300 diagnostic connector and actual J1939/J1708 networks, voltage range, polarity, grounding, transient protection, isolation, common-mode range, ESD/surge strategy, connector retention, fuse, current draw, CAN bitrate, and oscillator. Termination must remain disabled unless a bench topology explicitly requires it. Use galvanic isolation appropriate to the selected design and verify all parts against datasheets.

## Simulator interoperability

The GUI CAN bench routes simulated and replayed frames through the v1 packet envelope and CAN_RX payload layout before decoding. JSON trace fixtures retain identifier, data, timestamp, direction/source labels, and scenario metadata. The virtual hardware GUI can change the modeled adapter stages and deterministic bus/transport fault conditions. It does not execute the selected board firmware or emulate electrical bus/controller behavior. Future HIL mode may bridge fixtures to a physical adapter only with explicit “bench only” status and a disabled vehicle connector.
