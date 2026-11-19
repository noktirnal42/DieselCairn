# Evidence and references

## Primary technical/service references

| Subject | Reference | How it is used |
|---|---|---|
| MaxxForce 2007–09 program workflow | [Navistar IK2600282, NHTSA-hosted PDF](https://static.nhtsa.gov/odi/tsbs/2025/MC-11019110-0001.pdf) | Documents J1708 Save Request and J1939 Program sequence for applicable engines; confirm exact target applicability |
| J1708 electrical layer | [TI AN-915](https://www.ti.com/lit/an/snla038b/snla038b.pdf) | Physical-layer circuit and design constraints |
| J1708 electrical layer | [Renesas AN1990](https://www.renesas.com/en/document/apn/an1990-rs-485-transceivers-j1708-physical-layer-applications-heavy-duty-vehicles) | Alternative protected PHY application note and access timing discussion |
| J1587/J1708 overview | [U.S. DOT training supplement](https://www.its.dot.gov/StandardsTraining/modtransit5/sup/mt5sup.pdf) | Message relationship, framing and legacy bus overview |
| Allison diagnostics | [Allison electronic diagnostics/tools](https://www.allisontransmission.com/aftermarket-and-channel/parts-and-service/service-tools--information/electronic-diagnostics--service-tools) | Product-family tool reference; not proof of the bus's TCM/generation |
| Generic PGN dictionary | [ISOBUS PGN/SPN reference](https://www.isobus.net/isobus/pGNAndSPN/17187?type=PGN) | Cross-reference only; not an RE300 bus capture |
| Navistar software catalog | [International/Navistar Public Information Portal](https://msi.navistar.com/public/documents/0001360585.xml) | Current product and guide index; software access/licensing remains Navistar-controlled |
| Navistar NED | [NED User Guide](https://msi.navistar.com/public/ned/4328482.pdf) | Documents DTC/freeze-frame, monitoring, snapshots, tests and programming feature areas |
| Allison diagnostic tools | [Allison DOC features](https://www.allisontransmission.com/aftermarket-and-channel/parts-and-service/service-tools--information/electronic-diagnostics--service-tools) | Current official feature tiers and generation coverage; verify actual bus TCM generation |
| J1939 FMI definitions | [NHTSA-hosted technical bulletin table](https://static.nhtsa.gov/odi/tsbs/2018/MC-10145133-9999.pdf) | Generic FMI wording; it does not supply all OEM/SPN-specific troubleshooting |
| International/Allison patents | [International engine control](https://patents.google.com/patent/US6248041B1/en), [Allison multi-speed control](https://patents.google.com/patent/US11047474B2/en), [Allison TCM remote programming](https://patents.google.com/patent/US12237971B2/en) | General design history only; these do not identify this bus's modules/calibration or provide a service procedure |

## Reusable open-source tooling review

[CANExplorer](https://github.com/AKJ7/CANExplorer) (MIT) and [pycangui](https://github.com/davhodg/pycangui) (Apache-2.0) are candidates for generic J1939 node/replay tests. [pretty_j1587](https://github.com/ainfosec/pretty_j1587) (MIT) parses J1708/J1587 logs and can help fuzz a parser, but is not a timed network emulator. Detailed capability, license and integration notes are in [Reusable Simulator Tools](bench/simulator-options.md). No candidate is a verified PB305 ECM/Allison TCM emulator.

## Local source-of-truth files

Codebase source-of-truth files: `ProtocolSpec.md`, `HardwareDesign.md`, `AdapterProtocol.md`, `docs/SIMULATOR.md`, `docs/HARDWARE_BUILD_AND_BUY_GUIDE.md`, and `docs/DEVICE_QA.md`. When these differ from a generic reference, target-specific evidence must decide; preserve uncertainty in the UI and report.

