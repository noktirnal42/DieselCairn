# Reusable simulator and analyzer options

Reviewed 18 November 2026. These are free/open-source candidates, not PB305-compatible simulators. Use them for protocol-level tests and compare their output to DieselCairn fixtures. Do not connect to a vehicle bus.

| Tool | License | Useful capability | Limits for DieselCairn |
|---|---|---|---|
| [CANExplorer](https://github.com/AKJ7/CANExplorer) | MIT | GUI, restbus simulation, Python/QML simulated ECUs, J1939 address claim/diagnostics/transport, J1708 live capture/J1587 decode with supported physical interface; macOS Apple Silicon release | Not an International ECM or Allison TCM emulator. J1708 capability is capture/decoding, not a virtual J1708 node. Virtual `vcan` is Linux-specific; test cross-process integration explicitly. |
| [pycangui](https://github.com/davhodg/pycangui) | Apache-2.0; demo node templates MIT-0 | GUI trace/plots, J1939 node, custom Python simulation nodes, replay, multiple adapters; macOS is supported for the app | Built-in virtual bus is process-local; its UDP multicast bridge can be explored for integration. No J1708 simulator or target-specific Allison model. |
| [pretty_j1587](https://github.com/ainfosec/pretty_j1587) | MIT | J1708/J1587 log decoder and randomized packet generator useful for parser fuzz tests | Not a timed network simulator; its PID database requires licensed SAE material, which must not be bundled without permission. |
| [GENIVI CANdevStudio](https://github.com/GENIVI/CANdevStudio) | MPL-2.0 | GUI CAN restbus projects, timed frames and script components | No high-level PB305/Allison model; extra licensing/source obligations for modified MPL-covered files. |
| [Linux J1939 kernel API](https://docs.kernel.org/networking/j1939.html) and [can-utils](https://github.com/linux-can/can-utils) | Kernel docs / GPL tools | Shared multi-process J1939 testing on Linux SocketCAN/vcan | Not native macOS virtual CAN, no GUI or engine/transmission target model. Keep GPL tools separate from DieselCairn unless licensing is reviewed. |

## Acquisition and integration decision

The official [CANExplorer releases](https://github.com/AKJ7/CANExplorer/releases) provide a free macOS Apple Silicon DMG. DieselCairn can use it as an external J1939 restbus/reference tool; use its release checksum and inspect the app's signature/notarization before opening. Do not copy source or binaries into the app without checking license and distribution terms.

Use CANExplorer/pycangui as candidate graphical J1939 simulators and test whether their virtual buses can exchange frames with DieselCairn. An app-internal Python bus does not automatically interoperate across processes; the product needs an explicit localhost transport/bridge and source labels if integration is pursued. Do not assume the downloaded app is a physical simulator node until tested with real, separate adapters.

No credible open-source virtual J1708/J1587 wire/node simulator was found in this review. DieselCairn should implement its deterministic software node plus a physical MCU-based J1708 simulator node, while `pretty_j1587` is evaluated only for parsing/fuzz fixture ideas. The physical network model still needs compliant hardware and HIL captures.

## Exact-target model gap

These tools do not supply a verified Navistar MaxxForce DT ECM or Allison TCM firmware emulator. The target-specific signal map, diagnostic services, calibration identity and authorization procedure require the exact bus labels, approved documentation and captures. A generic simulated ECU must remain explicitly generic.

