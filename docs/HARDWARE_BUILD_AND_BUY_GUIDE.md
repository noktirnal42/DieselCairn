# DieselCairn Hardware Build and Buy Guide

> **Protocol revision:** The earlier three CAN-only build concepts are incomplete. Every useful PB305 bench adapter must be designed for separate J1939/CAN and J1708/J1587 paths. This document records engineering requirements and a staged prototype plan; the J1708 schematic, verified BOM, layout, safety validation, and vehicle connector pinout are not yet complete. Do not treat this guide as instructions to connect to the bus.

## Required multi-link scope update

Keep all three host options (STM32 + CAN controller, Arduino USB-CDC + CAN controller, FT232H MPSSE) as host/adapter experiments, but add a dedicated J1708 PHY and a device-side timing controller to each dual-link design. A J1587/J1708 interface cannot be implemented by the existing CAN HAT. FT232H MPSSE can access SPI but must not schedule J1708 bus timing from macOS; use a microcontroller or validated intelligent adapter for real-time access arbitration and collision handling.

### Per-adapter dual-link block diagram

```text
DieselCairn Mac / iPhone
          | USB (Mac) or BLE gateway (iPhone)
   adapter firmware / MCU  <--- local physical TX arm; default listen-only
          |                         |
          | SPI                    | UART + timed driver control + RX echo
      MCP2515                   J1708 compliant PHY
          |                         |
 CAN transceiver + isolation    J1708 transceiver + load/bias/filter network
          |                         |
  isolated J1939 CAN pair       separate J1708/J1587 pair
```

Both links are separate channels with separate transceivers, protection, status, logs, and capabilities. Do not join their wires or assume the same diagnostic connector pinout. The app must timestamp each event and keep J1939 PGN frames distinct from J1587 MID/PID messages.

### J1708/J1587 front-end selection and validation

J1708 operates at 9,600 baud, 8 data bits, no parity, one stop bit. The dominant/recessive wired behavior and bus access rules mean generic RS-485 modules are not direct replacements. Reference TI AN-915 and Renesas AN1990; design around the selected manufacturer's J1708-compatible circuit and validate the entire electrical network. Candidate Renesas ISL32455E is a protected RS-485 transceiver identified in a J1708 reference design, not a completed or approved product schematic. The implementation must review driver polarity/enable logic, 4.7 kOhm bias resistors, 47 ohm series resistors, 2.2 nF filtering capacitors where required by the chosen reference design, isolation, supply, fault protection, pinout, and component tolerances. Do not copy these values into a vehicle board without engineering review.

Do not add CAN-style 120-ohm endpoint termination to J1708 by habit. J1708 uses its specified per-node load/bias/filter network. Firmware must implement ten consecutive high idle bit-times, priority delay `P_D = P × 2 × tB` for the selected priority class, echo/collision detection, and bounded retry/backoff. Timing must be measured on adapter hardware with a logic analyzer and compliant electrical bench simulator.

### Bench simulator hardware

Build two isolated bench endpoints: the adapter under test and a separate simulator node with its own J1708 transceiver. The simulator node runs a simulator-only firmware build that emits selectable J1587 MID/PID/checksum fixtures and can exercise no-message idle, multiple source MIDs, malformed checksum, bus load, collision, noise, and stuck-dominant cases. Control it over a separate USB management channel and label it `SIMULATED BENCH NODE`. A second CAN simulator node generates known J1939 frames, address-claim and diagnostic/transport fixtures. Keep every vehicle connector absent and use a current-limited isolated bench supply.

### Added purchasing categories (BOM remains open)

- Exact J1708-compliant transceiver and reference schematic (candidate ISL32455E pending circuit review)
- MCU with deterministic UART timing, RX echo capture, timer/interrupt resources and firmware update/recovery path
- Digital isolation and isolated power supply selected for required ratings
- J1708 load/bias/filter components per selected reference circuit; no assumed 120-ohm termination
- ESD/transient protection and connector selected only after PB305 wiring evidence is obtained
- Separate simulator-node MCU, matching J1708 PHY, isolated supply, USB control port, and enclosure
- Logic analyzer, differential probe/oscilloscope access, current-limited supply and verified test fixture

The three earlier BOMs cover only a CAN bench. Prices for Waveshare CAN HAT+, Nucleo, FT232H, or Leonardo do not include J1708 hardware. Do not order a presumed vehicle connector or label the set as flash-capable. The electrical schematic/BOM/build guide should be released only after the design review and bench validation are documented.

Revision 1 • 18 November 2026  
Target: bench prototypes for the 2009 International RE300 school bus, factory model PB305, with an owner-reported Allison 3000 Series 3000PTS transmission  
Builds: STM32 + SPI CAN, Arduino Leonardo + SPI CAN, FT232H + SPI CAN

## Read this before ordering

The three builds below are **isolated CAN bench adapters for diagnostics-transport development**. They are not vehicle-ready, do not provide J1708, and do not perform ECM/TCM programming. Navistar's documented 2007-09 MaxxForce DT programming flow uses J1708 for Save Request and J1939 for programming; these CAN-only prototypes cannot perform that complete workflow. Do not order them as flash tools.

They are designed to exercise a real MCP2515 controller and CAN transceiver on a separate, low-voltage bench bus while DieselCairn's current CAN simulator exercises the software-only virtual bus. The app does not yet have production physical-adapter integration, and the STM32 and FT232H firmware/host paths are not complete. Treat these builds as staged engineering prototypes; complete software integration and the acceptance checks below before expecting the app to talk to them.

**Keep the bus connector off the vehicle.** The selected Waveshare 2-CH CAN HAT+ documents isolation and protection components, but that does not certify the complete adapter, harness, connector, transient immunity, isolation distances, or vehicle compatibility. The RE300 connector/pinout, voltage domain, active J1939/J1708 links, and approved interface are still unverified. Do not connect to the PB305, engine ECU, TCM, or a vehicle diagnostic connector with any of these builds.

## Choose the three builds

| Version | Host/transport | Build status | Best use |
|---|---|---|---|
| A — STM32 | NUCLEO-F031K6 target + ST-LINK virtual COM + external MCP2515 | Hardware available; firmware/protocol integration remains to be completed | Embedded firmware learning and deterministic USB-serial adapter development |
| B — Leonardo | ATmega32U4 USB CDC + external MCP2515 | Closest to the existing Arduino Leonardo bridge firmware | First prototype to build; easiest to reuse current firmware |
| C — FT232H | Mac USB host drives SPI/MPSSE directly into MCP2515 | Hardware available; Mac host driver/service and app transport remain to be completed | Bench instrument and low-level controller experiments; not a standalone adapter |

All three use the same CAN-side module and bench harness. For a complete set, buy **three CAN modules** and the three host boards. They are independent devices; do not stack the host boards onto the CAN modules unless the exact wiring revision explicitly supports it.

## Architecture diagram

```text
                       USB data / power
 MacBook  ─────────────────────────────────────────────────────────────────┐
   │                                                                        │
   ├─ A: NUCLEO-F031K6 ── SPI ─┐                                            │
   ├─ B: Leonardo ─────── SPI ─┼─ Waveshare 2-CH CAN HAT+ ── CANH/CANL ────┤
   └─ C: FT232H MPSSE ─── SPI ─┘       MCP2515 + isolation + transceiver    │
                                      (bench CAN only; terminator selectable)
```

Isolation protects the host-side logic from the CAN-side reference under the module's documented conditions. It does not make an unreviewed vehicle harness safe.

## Buy list

### Common items for all three builds

| Qty | Item | Exact purchase target / notes |
|---:|---|---|
| 3 | CAN interface modules | [Waveshare 2-CH CAN HAT+](https://www.waveshare.com/product/2-ch-can-hat-plus.htm), product 27338. It uses MCP2515 + SN65HVD230, includes digital and power isolation, TVS, logic-level selection, and selectable 120-ohm termination. Manufacturer price observed: US$24.99 each, before shipping/tax. |
| 1 | Short twisted-pair bench cable | 22-24 AWG twisted pair with insulated ends; clearly label CANH and CANL from the source node's printed terminal labels. Keep it short for first tests. |
| 2 | CAN termination resistors | 120 ohm, 1%, 0.25 W, one at each physical end of the two-node bench cable if the CAN HAT termination jumpers are not used. Do not fit both the onboard and external resistor at the same end. |
| 1 | USB-C data hub, if needed | Powered hub only if the Mac lacks enough ports. Use a data-capable USB cable; charging-only cables will fail enumeration. |
| 1 | ESD-safe work surface and wrist strap | Standard electronics bench equipment; avoid carpet and loose conductive hardware. |
| 1 | Labeled parts tray and small enclosure/board standoffs | Keep exposed prototypes from shorting against the Mac, bench, or each other. Do not call the enclosure vehicle-rated. |
| 1 set | Dupont jumpers | 10-15 cm; female-to-male for HAT-to-Nucleo/Leonardo and female-to-female for HAT-to-FT232H after header installation. Use distinct colors and labels. |
| 1 strip | 0.1-inch male header | For the FT232H breakout if not fitted; inspect its package contents before purchase. |

The HAT has two CAN channels. Use only channel 0 for the first node unless a test explicitly requires a second channel. For the currently documented 2-CH CAN HAT+ route, use the marked Raspberry Pi 40-pin host header and map by **physical header pin number** below. Follow the exact board revision's wiki for connector labels and jumper positions. Leave onboard termination **off** unless that node is at a physical end of the test cable. Set the board's logic-voltage selector to 3.3 V for the STM32 and FT232H, and to 5 V for the Leonardo. Power the HAT from its documented 5 V host-side input; do not feed the isolated bus-side supply from a host GPIO. Inspect the board revision's power-routing diagram before connecting the host.

| HAT header pin (physical) | Raspberry Pi signal | CAN0 function |
|---:|---|---|
| 2 | 5V | HAT host-side power |
| 6 | GND | Host-side logic reference |
| 40 | GPIO21 / SPI1_SCLK | Serial clock |
| 38 | GPIO20 / SPI1_MOSI | Controller input |
| 35 | GPIO19 / SPI1_MISO | Controller output |
| 11 | GPIO17 / SPI1_CE1 | CAN0 chip select |
| 15 | GPIO22 | CAN0 interrupt, optional |

These are the HAT's documented default SPI1/CS/interrupt routes. Verify the silk-screen and current manual against the exact board revision before wiring. Do not use Raspberry Pi BCM numbers as physical header numbers.

### Version A — STM32 host board

| Qty | Item | Purchase / notes |
|---:|---|---|
| 1 | STM32 Nucleo-32 board | [NUCLEO-F031K6](https://estore.st.com/en/products/evaluation-tools/product-evaluation-tools/mcu-mpu-eval-tools/stm32-mcu-mpu-eval-tools/stm32-nucleo-boards/nucleo-f031k6.html). Current ST listing observed US$32.73 (quantity and shipping can change). The STM32F031K6 does not supply the CAN controller or target USB device; use the MCP2515 HAT for CAN, and the ST-LINK virtual COM port for USB serial. |
| 1 | USB-A-to-Micro-B data cable | For the Nucleo board's ST-LINK connector. Add a USB-C adapter/hub if required. |

**Wire map (Nucleo-F031K6 to CAN HAT channel 0):**

| Nucleo signal | Nucleo header | HAT signal |
|---|---|---|
| +5V | CN4, pin 4 | HAT physical pin 2 |
| GND | CN3 pin 4 or CN4 pin 2 | HAT physical pin 6 |
| SPI1_SCK | D13 / PB3 | HAT physical pin 40 |
| SPI1_MOSI | D11 / PB5 | HAT physical pin 38 |
| SPI1_MISO | D12 / PB4 | HAT physical pin 35 |
| GPIO chip select | D10 / PA11 | HAT physical pin 11 |
| GPIO interrupt (optional) | D3 / PB0 | HAT physical pin 15; optional if firmware polls |

Use exactly one host-side supply path. Do not connect both USB 5 V sources or feed the CAN-side isolated rail from the host. The HAT's SPI pin breakout is the authoritative pin naming; check board revision and polarity before powering.

### Version B — Arduino Leonardo

| Qty | Item | Purchase / notes |
|---:|---|---|
| 1 | Arduino Leonardo Rev3 / ATmega32U4 | [Arduino Leonardo product page](https://docs.arduino.cc/hardware/leonardo/), use an official board or a vendor that clearly identifies the Rev3/ATmega32U4 design. The Leonardo includes USB CDC; do not substitute an Uno/Nano without revising the wiring and firmware. |
| 1 | USB-A-to-Micro-B data cable | USB CDC connection to Mac. |
| 1 set | Female-to-female Dupont jumpers | 7 short wires, labeled; HAT pin to FT232H header. |
| 1 strip | 0.1-inch male header | See common parts; solder only if the FT232H has bare holes. |

**Wire map (matches current firmware defaults):**

| Leonardo signal | Connection | HAT signal |
|---|---|---|
| 5V | 5V pin | HAT physical pin 2 |
| GND | GND | HAT physical pin 6 |
| SPI SCK | ICSP header, SCK | HAT physical pin 40 |
| SPI MOSI | ICSP header, MOSI | HAT physical pin 38 |
| SPI MISO | ICSP header, MISO | HAT physical pin 35 |
| D10 | GPIO chip select | HAT physical pin 11 |
| D7 | TX-arm input; jumper D7 to GND only for isolated-bench transmit tests | No HAT connection |
| Optional | CAN interrupt is currently polled; do not wire INT unless firmware changes and tests it | HAT physical pin 15 |

The ATmega32U4's SPI is exposed at the ICSP header. Do not take SPI from a copied Uno pin diagram. Leave the D7-to-GND arm jumper **out** for receive-only start-up. The present firmware's arm pin is not a vehicle-safety authorization; it is only a local bench interlock.

### Version C — FT232H host bridge

| Qty | Item | Purchase / notes |
|---:|---|---|
| 1 | FT232H breakout | [Adafruit product 2264](https://www.adafruit.com/product/2264), current listing observed US$14.95. New revision is USB-C; use a USB-C data cable. |
| 1 | USB-C data cable | Connects FT232H to Mac. |
| 1 set | Female-to-female Dupont jumpers | 7 short wires from the HAT header to FT232H male headers. Use 3.3 V logic. |
| 1 strip | 0.1-inch male header | Solder to FT232H breakout if not pre-fitted. |
| 1 | Software host environment | Pin an approved `pyftdi` version in a project virtual environment. Its docs list macOS and FT232H MPSSE support; the DieselCairn Swift app integration is not implemented yet. |

**Wire map (FT232H SPI mode):**

| FT232H pin | FT232H signal | HAT header |
|---|---|---|
| 5V | USB 5 V | Physical pin 2 |
| GND | Ground | Physical pin 6 |
| D0 | SCLK | Physical pin 40 |
| D1 | MOSI | Physical pin 38 |
| D2 | MISO | Physical pin 35 |
| C0 | Active-low chip select | Physical pin 11 |
| C1 | Optional interrupt | Physical pin 15 |

Do not enable the HAT's onboard 120-ohm termination on both channels if only channel 0 is connected. Do not attach the FT232H's 5V pin to a 3.3V signal. The FT232H is a USB-to-MPSSE bridge, not a CAN interface: the MCP2515 still performs CAN controller functions and the HAT still provides the physical CAN layer.

## Build sequence

### 1. Prepare the bench

1. Work on an ESD-safe surface with the Mac disconnected from vehicle or bus wiring.
2. Lay out and label each host board, CAN HAT, and cable as A, B, or C. Keep the CAN HAT loose until the pin map has been checked against the board manual.
3. Inspect each module for bent pins, solder bridges, damaged insulation, loose terminal blocks, or missing jumpers. Photograph both sides and record the product/revision labels.
4. Ensure CANH/CANL terminals are open; leave any transmit-arm jumper out. Check that CAN termination is disabled during power-up checks.

### 2. Assemble the CAN HAT connection

1. Attach the included 2x20 header or labeled SPI connector exactly as shown in the module revision's manual. Confirm pin 1 before inserting the breakout.
2. Set the logic-level jumper to 3.3 V for Version A and C. Set it to 5 V for Version B only after cross-checking the module revision.
3. Connect only the required signals in the version's table: host-side 5 V, ground, SCK, MOSI, MISO, and CS. Keep wires short; do not connect any vehicle connector.
4. Add the optional interrupt wire only if the current firmware path is configured for it. The current Arduino firmware polls CAN status.
5. With USB unplugged, use a continuity meter to verify there are no shorts between 5V/3V3/GND and that the SPI wires are not crossed.

### 3. Build each host variant

**A — STM32:** connect D13/PB3, D11/PB5, D12/PB4, D10/PA11, GND, and the documented logic supply. Verify the Nucleo UM1956 pin table; do not infer pin labels from another STM32 Nucleo board. The VCP USART shares MCU resources with Nano-header pins, so keep the chosen UART mapping fixed in the firmware and document it.

**B — Leonardo:** connect SPI at ICSP, not copied Uno headers. Connect CS to D10. Keep D7 TX-arm open. Flash the existing `Firmware/ArduinoLeonardoAdapter` only after the library and board build settings in that directory are met. The source currently selects MCP2515 16 MHz and 250 kbit/s; these are bench-fixture assumptions and must match the module's 16 MHz crystal and simulator configuration.

**C — FT232H:** set the host library to SPI/MPSSE, 3.3 V logic, and a conservative SPI clock for initial tests. Wire FT232H D0/D1/D2 and C0 to the CAN HAT channel-0 SPI. Create a macOS virtual environment and install a pinned PyFtdi release only after the app/host integration plan is accepted. Do not install random unsigned FTDI kernel extensions.

### 4. Build the closed bench bus

```text
CAN node A (H/L) ───────── twisted pair ───────── CAN node B (H/L)
      120 ohm at end A                           120 ohm at end B
      chassis/vehicle connector: NOT CONNECTED
```

1. Use two CAN nodes on a separate table-top harness. One may run a deterministic frame source; the other receives and logs. First use passive frame fixtures with no engine-control meaning.
2. Make the nodes the two physical ends of a short linear bus. Enable exactly one 120-ohm termination at each end. If using the HAT's selectable resistor, check that it is actually on the correct end/channel. Do not add star branches.
3. Connect CANH to CANH and CANL to CANL using the labels on both modules. Do not trust wire colors. Leave any third reference/COM conductor unconnected until the two module manuals specify whether it is required for this bench setup.
4. Set the bus rate on both nodes to the same **bench** value, initially 250 kbit/s for the existing Leonardo firmware. Confirm the CAN HAT's oscillator is 16 MHz; change software timing if the installed board differs.
5. Keep all CAN output disconnected while configuring and power-checking the host boards.

### 5. First power-up and functional checks

1. Connect only the host USB cable. Confirm the host enumerates (Nucleo ST-LINK VCP, Leonardo USB CDC, or FT232H USB device).
2. Confirm the host sees the expected device identity and the firmware reports listen-only/disarmed. If it reports an unknown CAN module, stop and check SPI wiring, chip select, oscillator, and logic level.
3. Verify supply rails with a meter before attaching the twisted pair. Check that the isolated CAN-side supply is present only as documented by the HAT manufacturer.
4. Attach the closed two-node bench bus with CANH/CANL checked, termination on both ends, and no vehicle harness attached.
5. Start the receive-only firmware/host path. Confirm frames are received with valid identifier, DLC, payload, and monotonic timestamp; confirm malformed frames and disconnects are surfaced as errors.
6. For Version B only, run existing protocol/CRC tests from `AdapterProtocol.md`. Ensure SET_MODE transmit requests are rejected with the local D7 jumper absent.
7. Test transmit only on the closed bench bus with generic, harmless fixture frames and a second receiving adapter. Keep engine-specific commands and any live diagnostic connection out of the test.
8. Capture version, wiring photo, host logs, test vectors, bus rate, oscillator marking, termination state, and pass/fail result in the build record.

## Firmware and software status at this guide revision

| Build | Hardware | Firmware/driver | DieselCairn live integration |
|---|---|---|---|
| STM32 | Specified development board + MCP2515 HAT | Not yet complete as an adapter implementation; pin map/build/serial transport need a dedicated firmware and test target | Not integrated |
| Leonardo | Specified board + MCP2515 HAT | Existing USB-CDC bridge source; review/rebuild against a pinned Arduino core/library before use | Not integrated |
| FT232H | Specified breakout + MCP2515 HAT | Host MPSSE access can be developed with PyFtdi; no production driver service yet | Not integrated |

No build is currently proven on a physical bus or even verified through physical CAN HIL in this guide. A successful firmware compile is not evidence of a working app-to-adapter session.

## What remains before any vehicle connection

- Identify the PB305 diagnostic connector, verified pinout, vehicle power domain, grounds, and active J1939/J1708 links from the VIN/build-specific wiring diagrams.
- Select a validated vehicle interface with documented electrical protection, isolation, connector, fusing, transient testing, and bus-off/recovery behavior.
- Add and validate J1708 support if the target programming workflow requires it. The three CAN builds above do not provide it.
- Implement host transports and capability negotiation in DieselCairn; keep receive-only as the default; enforce app and physical interlocks for bench transmit.
- Test protocol framing, loss, stale timestamps, disconnect, bus-off, malformed frames, reset, watchdog, and host sleep/wake behavior on a current-limited isolated bench.
- For ECU/TCU programming, use only the exact OEM-authorized workflow and target-specific calibration, with stable power, identity capture, verified recovery path, and manufacturer/service authorization. None of these prototypes meets that requirement.

## Purchases and references

The purchase targets above were checked on 18 November 2026. Prices and stock are live listings, not quotes; revisit before checkout. Do not buy based on a generic “MCP2515 CAN module” keyword: crystal frequency, logic level, transceiver, isolation, termination, and connector layout vary among clones.

- ST: [NUCLEO-F031K6 product/order page](https://estore.st.com/en/products/evaluation-tools/product-evaluation-tools/mcu-mpu-eval-tools/stm32-mcu-mpu-eval-tools/stm32-nucleo-boards/nucleo-f031k6.html), [Nucleo-32 user manual UM1956](https://www.st.com/resource/en/user_manual/um1956-stm32-nucleo32-boards-mb1180-stmicroelectronics.pdf).
- Arduino: [Leonardo hardware page and official Buy link](https://docs.arduino.cc/hardware/leonardo/), [pinout PDF](https://content.arduino.cc/assets/Pinout-Leonardo_latest.pdf).
- Waveshare: [2-CH CAN HAT+ product](https://www.waveshare.com/product/2-ch-can-hat-plus.htm), [manual/wiki with isolation, jumpers, pin mappings](https://www.waveshare.com/wiki/2-CH_CAN_HAT%2B).
- Adafruit: [FT232H product 2264](https://www.adafruit.com/product/2264), [pinout and SPI lines](https://learn.adafruit.com/circuitpython-on-any-computer-with-ft232h/pinouts).
- PyFtdi: [supported devices and macOS](https://eblot.github.io/pyftdi/index.html).
- Microchip: [MCP2515 product status and datasheet](https://www.microchip.com/en-us/product/MCP2515).
- TI: [ISO1042 isolated CAN transceiver ratings](https://www.ti.com/product/ISO1042). The recommended Waveshare module uses a different transceiver; ISO1042 is cited as a design reference only, not a claim about that module.
- Navistar: [IK2600282 programming bulletin](https://static.nhtsa.gov/odi/tsbs/2025/MC-11019110-0001.pdf), for the separate J1708/J1939 workflow limitation.
