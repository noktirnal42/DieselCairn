# Device and simulator QA

QA records actual build, device, and simulator evidence separately. Build success does not prove hardware compatibility.

## Evidence from 18 November 2026

| Area | Result | Evidence / limit |
|---|---|---|
| Swift package | Pass | 23 focused tests pass: J1587 model/checksum, J1939/VIN decoding, simulator integration, and owner-reported Allison profile defaults. |
| macOS app | Pass | Xcode build succeeds. App launched on the MacBook; Overview and Vehicle Profile were inspected. The Profile shows Allison 3000 Series / 3000PTS as owner-reported and asks for nameplate confirmation. |
| Mac software bench | Pass | The app's isolated virtual session generated labeled synthetic traffic, increasing frame and adapter counters, and displayed modeled J1939 rates. This is an app-internal simulator session, not an external bus or physical simulator node. |
| iOS device build | Pass | Signed build succeeds and installs on the paired iPhone 16 Pro Max. The developer team is provided locally at build time and is not stored in this public repository. |
| iPhone launch / latest visual | Pass | Latest signed build installed and launched on the physical iPhone 16 Pro Max. A direct device screenshot shows the disconnected Overview, blank live readings, and the owner-reported Allison 3000PTS line. Other mobile workflows still need current-build interaction QA. |
| Documentation site | Pass | Strict Zensical build and GitHub Pages deployment completed successfully (run 44430646091). The public site returns HTTP 200 at https://noktirnal42.github.io/DieselCairn/. Local visual inspection found and fixed raw icon/card markup; the landing page renders a branded hero, responsive cards, evidence labels, and a readable service flow. |
| External simulator tools | Reviewed | CANExplorer and pycangui are generic J1939 candidates; neither emulates this PB305 ECM or Allison TCM. No reusable timed J1708/J1587 source simulator was found. CANExplorer's release checksum matched, but macOS rejected its ad-hoc signature, so the app was not opened. |

## Remaining MacBook checks

- [ ] Exercise Diagnostics and fault injection, VIN decode success/error and manual correction, local profile persistence, and Flash Studio import/export/re-import.
- [ ] Check J1939/J1587 manual injection, invalid messages, trace export/replay, pause/reset, and virtual hardware fault states in the current build.
- [ ] Verify window sizing/persistence, full keyboard navigation, VoiceOver, contrast, and large text.

## Remaining physical iPhone checks

- [x] Launch the latest signed build on the physical iPhone 16 Pro Max; direct device screenshot confirms the disconnected Overview, blank live readings, and owner-reported Allison 3000PTS provenance text.
- [ ] Exercise navigation, Diagnostics, profile/VIN input, simulator controls, file picker/export, and persistence on device.
- [ ] Check safe areas, orientation, keyboard behavior, Dynamic Type, VoiceOver, background/foreground recovery, and touch targets.

## Hardware-in-loop and vehicle gates

- [ ] Build the external J1939 and J1708/J1587 simulator nodes and their control UI/firmware.
- [ ] Verify physical timing, bus electrical behavior, fault injection, adapter disconnects, and capture fidelity on an isolated, current-limited bench.
- [ ] Record the bus connector/pinout, Allison 3000PTS nameplate, transmission serial, TCM identity/calibration, and engine/ECM identifiers from the actual PB305.
- [ ] Perform authorized read/write validation only after bench recovery evidence, target compatibility, and service authorization are established.

No physical CAN or J1708 simulator node is connected in this pass. No vehicle connection, live write, or vehicle compatibility is claimed.
