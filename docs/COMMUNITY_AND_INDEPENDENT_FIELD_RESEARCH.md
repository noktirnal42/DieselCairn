# Community and Independent Field Research

Research date: 2026-11-18  
Scope: non-OEM experience relevant to school-bus conversions, Allison gear-range changes, transmission swaps, and diagnostics. These sources add practical context; they do not replace vehicle-specific engineering approval, calibrated service information, or controlled testing.

## What the independent sources say about sixth gear

| Source | What it contributes | Evidence class / limitation |
|---|---|---|
| [BGA School Buses: “Unlocking 6th Gear on an Allison Transmission”](https://bgaschoolbuses.blogspot.com/2021/01/) | A used-school-bus seller/service business describes owner requests on MD3060 and Allison 2000 buses, says the issue is often a TCM gear-range configuration, and describes a path through the bus manufacturer and an authorized Allison dealer. It warns that the calibration can lead to gear hunting when the engine/vehicle is poorly matched. | Independent commercial field guidance, but undated technical references beyond the 2021 post and no named vehicle-level case data. Its blanket “usually have a 6th gear inside” should not be generalized to all families/years. |
| [TSLABUS / Guy From Iowa Goes Places, Allison 3000PTS 6th-gear video, Part 1](https://www.youtube.com/watch?v=pIW2BvTwToQ) | A conversion owner documents a 3000PTS/MD3060-like project, including identifying/removing the TCM for a gear-range change. Useful for seeing owner workflow and vocabulary. | First-person conversion documentation; video description alone does not establish the exact calibration, eligibility, final road-test results, or repeatability. Do not copy a removal/programming method onto another transmission. |
| [Skoolie.net / School Bus Fleet discussion: “Do any school buses have the 6th gear unlocked?”](https://forums.schoolbusfleet.com/topic.asp?TOPIC_ID=21029) | School-bus operators report both five- and six-range configurations and describe contacting Allison distributors/rebuilders. One contributor distinguishes a requested calibration from a named “unlock” and mentions Economy-mode calibration as a separate concept. | Forum observations from 2010; useful discovery leads, not current policy or proof of compatibility. |
| [BGA School Buses, 2021](https://bgaschoolbuses.blogspot.com/2021/01/) | Gives a practical sequence: contact bus OEM for approval, take approval to authorized Allison channel, request calibration; also warns of TCM replacement cost and delay. | The approval requirements and costs may change and are application-specific. Cross-check current Allison policy before relying on the sequence. |
| [Reddit r/skoolies: “Got 6th unlocked”](https://www.reddit.com/r/skoolies/comments/1qvyw2w/got_6th_unlocked/) | A recent owner reports a Blue Bird approval letter, Allison-supplied file through a shop, installation of a replacement TCM, a 300-RPM reduction in one observed cruise condition, and the identifiers requested (transmission serial, CIN, VIN, approval). | Owner-reported single case; vehicle, gearing, tires, payload, and test method differ. The claimed RPM/fuel effects are not predictions for this International PB305. The post describes a different bus and OEM, not authorization for this bus. |
| [Parish Skoolie: school-bus Allison families and transmission swap overview](https://www.youtube.com/watch?v=V4Xh6ur246k) | Conversion-oriented discussion compares common bus units (AT545, MT643, MD3060, Allison 2000), explains swap compatibility concerns, and points to conversion specialists. | Broad educational overview, not a service manual or model-specific calibration reference. |
| [CA Conversions Allison conversion kits](https://www.caconversions.com/allison-conversions) and [their 5/6-speed swap article](https://www.caconversions.com/blog/allison-5-or-6-speed-transmission-swap) | A conversion business lists school buses among vocations it serves and discusses complete powertrain conversion packages. Useful for sourcing a specialist if the project becomes a transmission swap rather than a calibration request. | Commercial scope is not proof it performs or endorses a sixth-gear recalibration on the owner's installed 3000PTS. Confirm exact service and warranty in writing. |

### Agreement and disagreement across sources

Independent bus-owner and shop reports consistently indicate that some buses are configured for fewer available forward ranges than the transmission/control combination may support, and that a specialist can sometimes obtain or install a different calibration. They also show both approved dealer workflows and less formal mail-in/aftermarket services. This is not evidence that every “locked” unit has the mechanical hardware, calibration eligibility, or vehicle approval needed for another range.

The strongest practical cross-check is Allison's published [Maximum Gear Range Increase Policy (SIL 19-TR-08)](https://static.nhtsa.gov/odi/tsbs/2020/MC-10185305-0001.pdf): it states that a maximum-range increase requires OEM approval documentation for Allison to release a new calibration. It also distinguishes transmission-family capabilities and hardware requirements. A school-bus conversion blog or success story cannot waive that policy, and “off-label” tuning should not be presented as OEM-approved.

## What this means for this PB305

The owner's 2009 International RE300/PB305 has push-button electronic controls with an LED display. That tells us it has an electronic control/selector arrangement, but does not identify the Allison family, transmission configuration, TCM generation, TCM calibration, or whether sixth range is physically supported. The 2009 RE brochure and external donor listings are only candidate evidence; even a period brochure's base/optional equipment does not identify this bus's installed unit.

Before advising whether a sixth-range change is possible, the record needs:

1. Transmission dataplate: product family/model, assembly number, serial number, and any build/configuration codes.
2. TCM label and an authorized diagnostic identity report: assembly/part number, serial number, generation, CIN/calibration identifier, and current maximum gear range.
3. Vehicle build data: VIN, engine ESN/rating, axle ratio, tire size and speed rating, governed speed, brake/ABS configuration, and relevant bus/body options.
4. Written application approval or disposition from International/IC Bus and Allison's authorized service channel, plus a written explanation of any safety, tire-speed, or warranty implications.

VIN decoding cannot supply the TCM CIN, TCM serial, transmission serial, axle ratio, or calibration. A push-button selector display that shows “5” as the available maximum is a clue to record; by itself it does not prove a sixth gear exists in the specific unit or that it is appropriate for the bus.

## Field procedure: intake and approved service referral

This is a documentation and referral workflow, not a DIY programming procedure:

1. **Record the current state before changing anything.** Photograph transmission and TCM labels; save a read-only diagnostic report with VIN, transmission serial, TCM identifiers, CIN, DTCs, and presently selectable range. Record axle/tire data from authoritative labels or build records.
2. **Identify the actual transmission family and control generation.** Do not identify it from the selector alone or from another PB305's parts listing.
3. **Describe the request precisely.** Ask whether the request is to increase maximum gear range, change the shift schedule, enable an existing approved feature, or repair a fault. “Unlock 6th” can conceal distinct jobs.
4. **Ask International/IC Bus for the vehicle-specific engineering disposition.** Supply VIN and configuration evidence. Ask for a written approval/declination suitable for the Allison service request. A conversion title or removal of school markings is not itself technical approval.
5. **Ask an Allison distributor/dealer to confirm feasibility and authorization.** Provide transmission serial/model, TCM assembly/serial and CIN, VIN, and the OEM letter. Ask whether hardware or additional configuration work is required and whether the TCM can be programmed in-vehicle or must be exchanged/removed.
6. **Get a written work order and rollback plan.** It should name the target calibration/CIN, preserve the as-found report, say how original configuration can be restored, explain what happens if programming fails, and list any parts/core charges and warranty limits.
7. **After authorized service, verify without assuming success.** Read back the calibration identity and maximum range; inspect for DTCs; conduct the shop's controlled road test with suitable instrumentation; verify shifts, engine/transmission speed behavior, speed indication, and operating-temperature behavior. Keep the old and new reports with the vehicle record.

No source located in this research establishes a repeatable, safe programming recipe for DieselCairn to perform a gear-range increase on this PB305. We should support inventory, report capture, guided intake, compatibility checks, and referral first. Do not add a raw “set gear count” write command based on forum instructions.

## Conversion-community takeaways for DieselCairn

- Make the app distinguish **installed transmission family**, **available physical gear set**, **configured maximum range**, **current commanded gear**, and **shift schedule**. A single “6th gear locked” flag is too ambiguous.
- Add an evidence checklist and exportable **Allison calibration request packet**. Include identity evidence, as-found diagnostic report, tires/axle details, user-stated goal, OEM disposition, and service-channel response.
- Show provenance beside every value: owner entry, label photo/OCR, VIN decode, J1939/J1708 diagnostic report, simulator, or external seller/community source.
- Add simulator scenarios for five-range and six-range configurations, range-increase request rejected for missing approval, incompatible hardware, configuration mismatch, and successful authorized reflash followed by read-back. Simulation results must remain visibly simulated.
- Keep owner reports such as “300 RPM lower at 65 mph” as anecdotal reference only; never calculate expected fuel savings from them without the exact ratios, tire rolling radius, load, road speed, and measured baseline.
- Treat conversion businesses as possible consultation/referral contacts for transmission swaps and packaging, not as substitutes for Allison calibration authority.

## Source quality and use

For this project, sources are weighted in this order:

1. Current vehicle-specific engineering/build records and an authorized readout of the actual modules.
2. Published manufacturer service policy and model-specific service procedures.
3. Independent specialist or repair-business procedures that identify exact model, identifiers, and test evidence.
4. First-person conversion videos and case reports, for workflow discovery and questions to ask.
5. Forum anecdotes, for vocabulary and leads only.

Conflicts should be resolved upward in that list. Community evidence informed this guide's questions and intake checklist; no anecdote was used as a calibration or live-write instruction.

## References consulted

- Allison SIL 19-TR-08 Rev D (hosted by NHTSA): [PDF](https://static.nhtsa.gov/odi/tsbs/2020/MC-10185305-0001.pdf).
- BGA School Buses, “Unlocking 6th Gear on an Allison Transmission,” January 11, 2021: [article](https://bgaschoolbuses.blogspot.com/2021/01/).
- TSLABUS, “Enabling 6th Gear on Allison 3000 Transmission (Part 1),” July 30, 2022: [video](https://www.youtube.com/watch?v=pIW2BvTwToQ).
- School Bus Fleet forum thread, “Do any school buses have the 6th gear unlocked?”: [discussion](https://forums.schoolbusfleet.com/topic.asp?TOPIC_ID=21029).
- Reddit r/skoolies, “Got 6th unlocked,” owner-reported Blue Bird case: [discussion](https://www.reddit.com/r/skoolies/comments/1qvyw2w/got_6th_unlocked/).
- Parish Skoolie, school-bus Allison families/swap overview, December 19, 2021: [video](https://www.youtube.com/watch?v=V4Xh6ur246k).
- CA Conversions, commercial conversion services: [Allison conversion kits](https://www.caconversions.com/allison-conversions), [swap article](https://www.caconversions.com/blog/allison-5-or-6-speed-transmission-swap).
