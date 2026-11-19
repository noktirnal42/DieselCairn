# Flash Studio Specification

## Purpose

Flash Studio is the companion project builder and future programming workspace for the target 2009 International RE300. It handles engine ECM and Allison TCM records separately and preserves the complete chain from vehicle identity to source file and programming result.

## Implemented now

- Edit and locally persist a vehicle profile.
- Decode basic VIN fields through the NHTSA vPIC API; keep manual values editable and show decode source/date.
- Import one OEM/raw file up to 64 MiB.
- Preserve original bytes in a JSON project package with source filename, module target, vehicle record, notes, byte count, SHA-256, schema version, and an explicit unassigned execution profile.

The JSON package is a project container only. It is not currently executable or accepted by an OEM programming tool. It may contain licensed/proprietary material and must not be checked into Git.

## Required next features

- Parse supported Navistar OEM packages and Allison calibration packages only after file formats and licensing permit.
- Show metadata, part/calibration IDs, target module family, version, image segments/address ranges, signature/checksum state, and compatibility report.
- Compare two compatible images with semantic field diffs where their format is documented; otherwise provide byte/segment diffs only.
- Never modify signed/calibrated bytes without a documented, authorized procedure. No arbitrary table editor until parameter definitions, units, ranges, checksum rules, and target application are established.
- Build a flash plan from a validated module profile, package type, exact module identity, and applicable authorization evidence.
- Simulate start, erase/program/verify stages, progress, timeout, voltage drop, USB/BLE disconnect, target mismatch, rollback/recovery, and post-flash identity/fault scan.
- Require a stable-power check, original read/backup when the module supports it, immutable payload hash, plan review, explicit vehicle state, and final confirmation before any actual write.
- After writes, retain operation ID, timestamp, operator, VIN, ECM/TCM IDs, old/new calibration IDs, adapter/firmware versions, authorization references, voltage history, raw event log, verification results, and faults.

## Target-specific facts required

Before creating executable procedures, document the exact ECM and TCM hardware/software generations, original calibration IDs, manufacturer-supported file acquisition route, container layout, authenticity checks, programming service/protocol, required credentials or OEM workflow, timing/flow-control, erase/program granularity, recovery/boot behavior, power requirements, and post-flash checks. The first implementation must use manufacturer-authorized source files and procedures for this exact vehicle configuration.

## Sixth-range assessment workflow

- Read Allison transmission family/model and serial from tag; read TCM serial, generation, calibration ID, and current max range.
- Capture VIN, tire speed rating, relevant N/V/ratio data, installed gear/sensor hardware, and requested operation.
- Attach OEM approval and Allison support correspondence/track record when required.
- Match only the authorized Allison calibration/profile for the exact target.
- Show an eligibility result with every unresolved condition; never emit a generic “unlock sixth” write.

Allison SIL 19-TR-08 (Rev D) states the hardware and OEM approval dependencies. This workflow is an evidence collector; it does not replace an Allison-authorized service outlet or create its own calibration.
