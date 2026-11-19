# Flash Studio and calibration projects

Flash Studio currently fingerprints imported bytes and creates an auditable project manifest. It does not prove OEM container validity, target compatibility, signature validity, calibration correctness or flashability.

## Required project record

Source bytes and SHA-256; file provenance/license; container/version; VIN and decode source/date; observed ECM or TCM identity; calibration/CIN; engine/transmission serials; target profile evidence; compatibility checks; approval reference; immutable original; operator and timestamp; validation state; and operation/recovery log.

## Future simulation workflow

The simulator may use explicitly synthetic packages to verify screens and state transitions: accepted/rejected format; wrong ECU/TCU; checksum/signature mismatch; wrong calibration; J1708 Save Request failure; J1939 transfer loss; voltage drop; reset/resume; audit export. It must not contain real calibration binaries or pretend synthetic data is OEM software.

## Live-write gates

Exact target profile and module identity; legitimate authorized OEM/Allison procedure; supported interface and firmware; verified package/signature and compatibility; stable power; original backup where supported; interruption/recovery plan; explicit confirmation; readback/post-program identity and DTC rescan. Unknown target fails closed. No security bypass.

