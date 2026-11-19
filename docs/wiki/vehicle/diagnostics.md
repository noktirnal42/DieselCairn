# Diagnostics, reports and safety

## Data provenance

Each value and fault must include source, network, adapter identity, timestamp, module identity (when known), raw frame/message reference, and decoder/version. Show disconnected/stale state explicitly. Never save simulator data as a vehicle observation.

## Diagnostic coverage roadmap

- J1939: known standard parameter groups and J1939-73 DM1/DM2 parsing, with target-specific support marked unverified until captured/documented.
- J1587/J1708: receive and parse valid MID/PID/checksum messages; identify unsupported PIDs without inventing meanings.
- Requests, clear-code commands, active tests, regen controls and output controls require documented target support, authorization, interlocks and dedicated procedure tests. UI controls alone do not establish functioning support.
- Reports preserve raw bytes, decoded view, protocol/network and uncertainty.

## Always fail closed when

Target identity is missing or mismatched; protocol/connector is uncertain; the data source is simulation/replay; power or transport is unstable; an operation is undocumented; signature/checksum verification fails; or recovery is unavailable. Do not bypass OEM authorization.

