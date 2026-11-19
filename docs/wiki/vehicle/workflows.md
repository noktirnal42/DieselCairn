# PB305 service workflows

## A. Diagnose a fault

1. Select the vehicle record and confirm its identity and installed ECM/TCM entries.
2. Confirm adapter identity, protocol capability and source state (SIMULATOR, REPLAY or LIVE).
3. Read module identity, active and previously active DTCs, occurrence/freeze-frame information where supported, and raw captures.
4. Save a report with timestamp, network, adapter/firmware revision, module identity and source provenance.
5. Do not clear a code until the raw code and freeze-frame data are preserved and the module procedure is verified.

## B. Engine/transmission/ECM/TCM swap and pairing

Capture old and replacement module identities, engine/transmission serials, VIN, ratings, calibration IDs, wiring configuration, approved source files and OEM/Allison authorization. Pairing support must be implemented only after the exact procedure and required authenticated software/interface are documented. VIN alone is not sufficient to select calibration or pair modules. No security bypass or invented seed/key method is permitted.

## C. Allison sixth-range investigation

Record the Allison series/model and serial; TCM generation/part number/calibration; current and requested maximum range; ratios; tire size/speed rating; vehicle acknowledgement and OEM approval. Determine hardware/ratio eligibility using the applicable Allison service information. Do not infer six-speed capability from a push-button selector or simulated sixth-range value. A generic “unlock sixth” toggle is not an acceptable procedure.

## D. Navistar programming workflow study

Navistar bulletin IK2600282 says NavKal uses J1708 for Save Request and J1939 for Program for applicable 2007–09 MaxxForce engines. Confirm the actual engine variant and bulletin applicability. Use the simulated two-link workflow to test application state ordering and failure recovery only. Do not send a live request or program event without licensed procedure, exact target identity, stable power, approved interface, recovery method and an explicit project authorization gate.

