# Device and simulator QA

QA records actual build, device, and simulator evidence separately. Build success does not prove hardware compatibility.

## Evidence from 18 November 2026

| Area | Result | Evidence / limit |
|---|---|---|
| Swift package | Pass | 37 tests pass, covering synthetic J1939/J1587 traffic, BAM reassembly, trace timestamp compatibility, SPN/FMI handling, VIN validation and label lookup, vehicle profile, and bench integration. |
| macOS app | Pass | Current Xcode build succeeds and launches on the MacBook. Sidebar routes were exercised for Diagnostics, Vehicle Profile, Flash Studio, CAN/J1708 bench, Virtual Hardware, and Adapters. A profile layout overflow was corrected and visually rechecked. |
| Mac software bench | Pass | The isolated app session starts/stops, advances counters, and displays modeled ECU/TCM rates. Metric cards now use a stable desktop grid. This is app-internal synthetic traffic, not an external bus or physical simulator node. |
| MCP server | Pass | `python3 scripts/qa_mcp.py` builds and drives the stdio server using framed JSON-RPC; boundary inputs return errors without terminating the server. Flash write capability correctly reports unavailable. |
| iOS device signing and install | Pass | The paired iPhone 16 Pro Max accepted the development build after the mobile targets picked up the existing team's local signing configuration. The cached profile covers this device and its development certificate is available in the local keychain. A strict signature check passed before installation. |
| Mobile UI | Pass | Three XCTest workflows passed on the iPhone 17 simulator and the physical iPhone 16 Pro Max on iOS 27.2. The tests exercised section navigation, start/stop, adapter-to-hardware navigation, simulated DM1 fault injection and clear, Vehicle Profile and Flash Studio. Review used app screenshots from each destination. |
| Mac VIN entry and lookup | Pass | The Mac app accepted a formatted standard VIN after consent. A separate 18-character test label enabled the prefix lookup and preserved the full identifier in an isolated profile. NHTSA returned 2009 IC BUS / PB305 / RE with an invalid check digit, which the app showed in the advisory panel. The lookup allows 30 seconds and shows progress and a specific timeout message. |
| App icon | Pass | The 1024-pixel source is opaque sRGB, and all Mac catalog sizes are tracked. The built Mac app contains the updated icon. |
| Documentation site | Pass | Strict Zensical build and GitHub Pages deployment completed successfully (run 44430646091). The public site returns HTTP 200 at https://noktirnal42.github.io/DieselCairn/. Local visual inspection found and fixed raw icon/card markup; the landing page renders a branded hero, responsive cards, evidence labels, and a readable service flow. |
| External simulator tools | Reviewed | CANExplorer and pycangui are generic J1939 candidates; neither emulates this PB305 ECM or Allison TCM. No reusable timed J1708/J1587 source simulator was found. CANExplorer's release checksum matched, but macOS rejected its ad-hoc signature, so the app was not opened. |

## Local iPhone signing

The generated mobile targets use Automatic signing and read an optional, gitignored `Signing/DieselCairnMobile.local.xcconfig`. This keeps the local team selection across `xcodegen generate`. Create the file with the following line, substituting the development team that has a profile and certificate covering this app and the paired iPhone.

```xcconfig
DEVELOPMENT_TEAM[sdk=iphoneos*] = YOUR_TEAM_ID
```

```sh
xcodegen generate
xcrun devicectl list devices
xcodebuild -project DieselCairn.xcodeproj -scheme DieselCairnMobile \
  -destination "platform=iOS,id=$DEVICE_UDID" -derivedDataPath "$BUILD_DIR" build
codesign --verify --deep --strict "$BUILD_DIR/Build/Products/Debug-iphoneos/DieselCairn.app"
xcrun devicectl device install app --device "$DEVICE_UDID" "$BUILD_DIR/Build/Products/Debug-iphoneos/DieselCairn.app"
xcrun devicectl device process launch --device "$DEVICE_UDID" dev.noktirnal.dieselcairn.ios
```

Set `DEVICE_UDID` to the paired phone and `BUILD_DIR` to a local build directory. Unlock the iPhone before launching. Xcode can build with a valid cached profile and matching local development identity. If that profile expires or the device changes, use the selected team's account in Xcode to refresh provisioning. See [Apple's registered-device guide](https://developer.apple.com/documentation/xcode/distributing-your-app-to-registered-devices/). The missing team setting was reproduced and fixed independently of the reported account sign-out.

## Follow-up MacBook checks

- [x] Start the virtual session, inject SPN 110/FMI 0, inspect the active Diagnostics row, and clear the simulated faults.
- [x] Exercise J1939 and J1587 manual injection and navigate from Adapters to Virtual hardware.
- [x] Verify inline VIN correction, consent, live public-fixture decode, and local profile persistence.
- [x] Confirm a disconnected virtual CAN transceiver drops a test frame, then stop and reset the bench.
- [ ] Verify Flash Studio import/export and trace export/replay through the file dialogs. Package tests cover compatible trace timestamps and frame ordering.
- [ ] Verify window sizing/persistence, full keyboard navigation, VoiceOver, contrast, and large text.

## Remaining physical iPhone checks

- [x] Sign and install a current development build on the paired iPhone.
- [x] Launch on the unlocked iPhone and inspect Overview, Diagnostics, simulator controls, profile and Flash Studio.
- [x] Exercise section navigation, synthetic DM1 injection and clear, bench lifecycle, and virtual hardware navigation on the physical iPhone.
- [ ] Verify VIN editing and decode, file picker/export, and persistence on the physical iPhone.
- [ ] Check safe areas, orientation, keyboard behavior, Dynamic Type, VoiceOver, background/foreground recovery, and touch targets.

## Hardware-in-loop and vehicle gates

- [ ] Build the external J1939 and J1708/J1587 simulator nodes and their control UI/firmware.
- [ ] Verify physical timing, bus electrical behavior, fault injection, adapter disconnects, and capture fidelity on an isolated, current-limited bench.
- [ ] Record the bus connector/pinout, Allison 3000PTS nameplate, transmission serial, TCM identity/calibration, and engine/ECM identifiers from the actual PB305.
- [ ] Perform authorized read/write validation only after bench recovery evidence, target compatibility, and service authorization are established.

No physical CAN or J1708 simulator node is connected in this pass. No vehicle connection, live write, or vehicle compatibility is claimed.
