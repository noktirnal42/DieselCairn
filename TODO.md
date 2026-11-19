# Product TODOs

## Design and usability

- [x] Replace the generic demo gauge/card dashboard with a restrained, information-dense heavy-duty scan-tool layout.
- [x] Replace the playful orange/mint palette with neutral instrument surfaces and semantic status colors.
- [x] Add a custom app icon and matching vector brand mark for DieselCairn.
- [ ] Complete the Mac screen review and improve the long scrolling profile/Flash Studio forms for iPhone; current iPhone section routing and settled screen fit were checked on-device.
- [ ] Check VoiceOver, keyboard navigation, contrast, and Dynamic Type on the physical devices.

## Vehicle diagnostics and programming

- [ ] Add the owner's VIN to the local profile only after the owner provides/confirms it; independently decode it and preserve RE300 (badge/series) separately from PB305 (school-bus model number).
- [ ] Obtain the VIN-specific International build/feature record and matching RE electrical diagram/manual revision; public vPIC decoding is not a build sheet.
- [ ] Record engine ESN, EFRC, ECM SID/part number, software/calibration IDs, transmission model/serial/assembly number, and TCM label/generation from the actual bus or authorized OEM reports. Do not infer these from PB305 or year alone.
- [ ] Verify live RE300 ECM/TCM identity, fault retrieval, and parameter support using an identified adapter on an isolated bench.
- [ ] Document supported OEM flash containers and implement executable flash-program generation only after their format and target rules are verified.
- [ ] Implement an authorized programming transport with interruption recovery, stable-power checks, identity binding, and operation logs.
- [ ] Complete J1708/J1587 simulator GUI controls and adapter firmware (real-time idle qualification, priority, echo collision, retry and error cases); current software model is not electrical emulation.
- [ ] Find, license-check, download and evaluate reusable J1939/J1708 simulator nodes; otherwise build dedicated physical simulator firmware and GUI controls.
- [ ] Design/validate dual-link adapters and separate physical J1708 + J1939 simulator nodes; obtain connector/build-specific evidence and review circuitry before ordering a vehicle-facing design.
- [ ] Acquire no calibration binary until ECM/TCM labels are read and official Navistar/Allison tools authorize a target-specific file.
- [ ] Confirm the installed Allison series, TCM generation/calibration, speed/tire ratios, and OEM approval before evaluating sixth range.
- [ ] Verify the three adapter paths (STM32 + CAN controller, Arduino + CAN controller, FT232H + CAN controller) independently and document which functions each supports.

## Simulation and release evidence

- [ ] Complete J1939 simulator coverage: address claim, TP.CM/TP.DT, DM1/DM2, request timeout and error injection.
- [ ] Update graphical wiki, GitHub Pages and printable PDF manuals after engineering decisions; verify citations, links and rendered pages.
- [ ] Create private GitHub remote; exclude build products, secrets, VIN/captures and licensed OEM files; version source/docs and QA evidence.
- [ ] Expand PC/GUI multi-link simulation and firmware emulation where peripheral models are accurate; record model limits.
- [ ] Run current-limited adapter HIL checks and keep vehicle-level work gated on bench evidence.
- [ ] Finish MacBook and physical iPhone functional/accessibility QA beyond the completed launch, dashboard, and navigation checks; record evidence in `docs/DEVICE_QA.md`.
