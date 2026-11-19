# Adapter and simulator firmware

## Adapter responsibilities

- Boot receive-only on each link, independent of host state.
- Report device identity, firmware hash/version, capabilities, per-link health, timing mode, transmit interlock and errors.
- J1939/CAN receive/transmit through a validated CAN controller/transceiver; transmit requires the local arm and an explicit bench mode.
- J1708/J1587 uses a dedicated PHY and MCU-side real-time access timing, echo compare/collision response, retry bounds, message checksums and capture timestamps.
- Preserve strict network tags: J1939 event is CAN ID/data; J1587 event is raw MID/PID/data/checksum bytes.
- Watchdog, brownout and disconnect recover to listen-only.

## Physical simulator node firmware

Build separate simulator-only images for J1939 CAN node and J1708/J1587 source. A separate USB management/control link selects deterministic messages and fault scenarios. Provide physical mode indication and firmware identity. The simulator image must not share a vehicle connector or permit accidental bridge to a live bus.

## Current repository state

`Firmware/ArduinoLeonardoAdapter` is a CAN-only prototype sketch. J1708 adapter firmware, simulator-node firmware, STM32 firmware, FT232H host service and production USB/BLE app transports remain open. Successful compile of the CAN sketch does not validate the physical bus or app connection.

