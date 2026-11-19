# Bench simulator operations

## Software bench

1. Open DieselCairn and confirm the banner says **SIMULATOR**.
2. Select J1939/CAN, J1708/J1587, or a two-link workflow scenario.
3. Set nodes, protocol rates and fault injection before starting.
4. Start the virtual session and verify frames/messages arrive through the adapter protocol boundary.
5. Inspect raw capture and decoded fields; intentionally inject a malformed event and verify explicit error reporting.
6. Export the fixture with scenario, source label, adapter profile and timestamps.
7. Stop/reset; confirm simulated readings disappear and the app returns to disconnected state.

## Hardware bench

The physical simulator has separate CAN and J1708 test pairs. Control each test-node device over an independent USB management link. Verify its scenario state, firmware hash and expected raw bytes. Connect only the adapter under test and simulator nodes to an isolated current-limited bench network. No vehicle harness, ECM, TCM or vehicle power supply is connected.

The in-app software fixture is not a hardware simulator. Hardware HIL requires real PHYs, firmware, host transport and a recorded capture.

