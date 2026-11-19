# Arduino Leonardo adapter firmware

This is a USB-CDC CAN frame bridge for an **Arduino Leonardo / ATmega32U4** with an external MCP2515 and CAN transceiver. It replaces the former invalid sketch, which confused MCP2515 registers with CAN identifiers and used nonexistent PGN values.

## Requirements

- Arduino Leonardo or a specific, verified ATmega32U4 board
- MCP2515 module with a 16 MHz oscillator (change the compile-time setting only after identifying the actual crystal)
- CAN transceiver, protection/isolation, and a reviewed connector/power design
- Arduino IDE or Arduino CLI
- mcp_can by Cory J. Fowler, LGPL-2.1-or-later: https://github.com/coryjfowler/MCP_CAN_lib
- Protocol implementation in `AdapterProtocol.md`

## Pin defaults

- MCP2515 CS: D10
- MCP2515 SPI: ATmega32U4 SPI pins at the ICSP header (verify board manual)
- TX arm jumper: D7 to GND; absent at boot by design
- CAN INT is polled by the pinned mcp_can API; connect only if a future interrupt-backed implementation is validated.

These are firmware defaults, not a vehicle connector wiring guide. Do not connect this prototype to the RE300 until the full schematic, transceiver, protection, connector pinout, bus rate, and listen-only bench validation are documented.

## Build

1. Install the Arduino AVR board package and select **Arduino Leonardo**.
2. Install the mcp_can 1.5.1 from Arduino Library Manager.
3. Confirm the MCP2515 oscillator. Defaults are 250 kbit/s and 16 MHz; the installed RE300 bus rate remains unverified. Do not use these defaults as a vehicle connection recommendation.
4. Compile and inspect the output before flashing the adapter board.
5. Boot and verify it reports listen-only with no arm jumper. Verify serial framing/CRC and simulated CAN frames on a bench.
6. Verify that SET_MODE normal is rejected with the jumper absent. Do not enable transmit on a vehicle without an approved application workflow and hardware review.

The current iOS/macOS app does not yet include the physical serial transport. Firmware compilation alone is not end-to-end adapter validation.
