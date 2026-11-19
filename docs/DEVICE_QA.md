# Device and simulator QA

QA records actual build, device, and simulator evidence separately. Build success does not prove hardware compatibility.

## Evidence from 18 November 2026

| Area | Result | Evidence / limit |
|---|---|---|
| Swift package | Pass | 32 tests pass, including BAM reassembly, malformed count/global destination/sequence rejection, replay integration, SPN/FMI DM1 encoding/decoding, active/history fault handling and simulator clear, J1587 model/checksum, VIN parsing, and virtual-bench integration. The MCP regression harness passes range/overflow rejection, decimal PGN parsing, virtual J1939/J1587/BAM, simulator-only fault injection/clear, flash manifest integrity, and write-boundary checks. |
| macOS app | Pass | Current Xcode build succeeds and launches on the MacBook. Sidebar routes were exercised for Diagnostics, Vehicle Profile, Flash Studio, CAN/J1708 bench, Virtual Hardware, and Adapters. A profile layout overflow was corrected and visually rechecked. |
| Mac software bench | Pass | The isolated app session starts/stops, advances counters, and displays modeled ECU/TCM rates. Metric cards now use a stable desktop grid. This is app-internal synthetic traffic, not an external bus or physical simulator node. |
| MCP server | Pass | `python3 scripts/qa_mcp.py` builds and drives the stdio server using framed JSON-RPC; boundary inputs return errors without terminating the server. Flash write capability correctly reports unavailable. |
| iOS device build | Blocked | A current-build install is blocked by local Xcode account/provisioning state: without a team, signing is required; supplying the locally configured team fails because Xcode reports no account and no matching profile for the app bundle. No team identifier or credentials are stored in this repository. |
| iPhone current-build visual QA | Blocked | The iPhone 16 Pro Max is connected, but the device was locked at the latest screenshot attempt. The installed app is from the previous verified build; current UI changes have not been installed or visually checked on-device. |
| VIN decoder | Pass | A public auction fixture VIN was decoded through NHTSA vPIC: returned PB305 model code, RE series, and DT466/MaxxForce DT engine description. No ECM/TCM serial or calibration was returned. This is fixture data, not the owner's bus VIN. |
| Documentation site | Pass | Strict Zensical build and GitHub Pages deployment completed successfully (run 44430646091). The public site returns HTTP 200 at https://noktirnal42.github.io/DieselCairn/. Local visual inspection found and fixed raw icon/card markup; the landing page renders a branded hero, responsive cards, evidence labels, and a readable service flow. |
| External simulator tools | Reviewed | CANExplorer and pycangui are generic J1939 candidates; neither emulates this PB305 ECM or Allison TCM. No reusable timed J1708/J1587 source simulator was found. CANExplorer's release checksum matched, but macOS rejected its ad-hoc signature, so the app was not opened. |

## Remaining MacBook checks

- [ ] Exercise Diagnostics fault injection, VIN decode error/manual correction, local profile persistence, and Flash Studio import/export/re-import.
- [ ] Check J1939/J1587 manual injection, trace export/replay, pause/reset, and virtual hardware fault states in the GUI (MCP injection boundaries are covered by `scripts/qa_mcp.py`).
- [ ] Verify window sizing/persistence, full keyboard navigation, VoiceOver, contrast, and large text.

## Remaining physical iPhone checks

- [ ] Install and inspect the current build after Xcode account/provisioning is restored and the phone is unlocked.
- [ ] Exercise navigation, Diagnostics, profile/VIN input, simulator controls, file picker/export, and persistence on device.
- [ ] Check safe areas, orientation, keyboard behavior, Dynamic Type, VoiceOver, background/foreground recovery, and touch targets.

## Hardware-in-loop and vehicle gates

- [ ] Build the external J1939 and J1708/J1587 simulator nodes and their control UI/firmware.
- [ ] Verify physical timing, bus electrical behavior, fault injection, adapter disconnects, and capture fidelity on an isolated, current-limited bench.
- [ ] Record the bus connector/pinout, Allison 3000PTS nameplate, transmission serial, TCM identity/calibration, and engine/ECM identifiers from the actual PB305.
- [ ] Perform authorized read/write validation only after bench recovery evidence, target compatibility, and service authorization are established.

No physical CAN or J1708 simulator node is connected in this pass. No vehicle connection, live write, or vehicle compatibility is claimed.
