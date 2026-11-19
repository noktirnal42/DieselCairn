# Protocol map

```mermaid
flowchart TB
  M[DieselCairn service workflow]
  M --> C[J1939 application and network]
  C --> CAN[J1939-21 classic CAN transport]
  CAN --> PHY1[CAN transceiver / CAN-H CAN-L]
  M --> S[J1587 message layer]
  S --> J[J1708 data link and physical layer]
  J --> PHY2[J1708 transceiver / separate pair]
  M --> O[OEM / Allison procedure state machine]
  O -->|Navistar Save Request fixture| J
  O -->|Navistar Program fixture| CAN
```

J1939 and J1587 are not interchangeable encodings. J1587 travels on J1708; it is not a PGN and does not use CAN arbitration. Each physical link has its own capability, status, capture, adapter front end and fault injection controls. See [J1939/CAN](j1939.md), [J1708/J1587](j1708-j1587.md), and [cross-link workflow](programming-workflow.md).

