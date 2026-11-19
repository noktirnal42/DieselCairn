# Service tools and module identification

Use official tool features as a checklist for DieselCairn. Their existence does not mean DieselCairn supports those commands or that this PB305 contains a specific module revision.

| Area | Product reference | DieselCairn feature target |
|---|---|---|
| International engine | Navistar Engine Diagnostics (NED), legacy ServiceMaxx J1708/J1939, NavKal | Identify engine/module; refresh DTCs; request freeze frame; view, record and graph supported live signals; preserve snapshot/replay; expose approved service tests and programming only after applicability is proven. |
| Body/chassis multiplex | Diamond Logic Builder (DLB) | Separate BCM/module faults, configuration and connector information from ECM/TCM functions. |
| Allison transmission | Allison DOC and TCM Reflash | Identify TCM generation and transmission serial; manage DTCs, freeze-frame/live records, customer-modifiable configuration and authorized reflash according to the correct subscription and service procedure. |

Navistar's public programming bulletin groups 2007–2009 MaxxForce DT/9/10 as ECM-only and lists ServiceMaxx 1708 support for that application family. The 2007 training material describes a single-box ECM/IDM arrangement. These are family-level sources; get actual VIN build data and read the ECM label and identity before choosing a service path.

Allison asks for the transmission serial when identifying parts, and current DOC support varies by control generation. “3000PTS” does not identify a TCM generation, CIN, calibration, or part number. Record the physical TCM/transmission labels before planning any pairing or configuration change.

The fault screen in DieselCairn now supports simulator-only arbitrary SPN/FMI injection and simulator clear. Generic FMI definitions are shown in plain language, with unknown SPNs labeled unknown. This is for exercising the user interface and DM1 handling; it does not clear a vehicle code. Before any future live clear, preserve the diagnostic report and follow the target's service plan.

## Module/patent search

Public parts listings contain possible MaxxForce DT ECM labels and numbers, but they are vendor leads, not confirmed vehicle fitment. Allison listings vary by generation, feature package and serial. Do not source a replacement module or calibration using a search result alone.

Public patent records describe broad engine and transmission control concepts, not production ECU/TCM schematics or the calibration installed on this bus. Reviewed examples include [International engine control linked to vehicle controls](https://patents.google.com/patent/US6248041B1/en), Allison's later [multi-speed control system](https://patents.google.com/patent/US11047474B2/en), and a later Allison [TCM remote-programming architecture](https://patents.google.com/patent/US12237971B2/en). None establishes a sixth-gear unlock procedure for the 2009 3000PTS.

For product details, source notes and patent limitations, see [Detailed service-tool and module research](detailed-service-research.md) and the [reference index](../references.md).
