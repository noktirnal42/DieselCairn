from pathlib import Path
import sys

sys.path.insert(0, "/tmp/dieselcairn_pdfdeps")
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import BaseDocTemplate, Frame, PageTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, Flowable

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output/pdf/DieselCairn-Multi-Link-Protocol-and-Simulator-Guide.pdf"
OUT.parent.mkdir(parents=True, exist_ok=True)
NAVY = colors.HexColor("#152A3D")
TEAL = colors.HexColor("#0A8585")
AMBER = colors.HexColor("#A9610A")
INK = colors.HexColor("#1D2B36")
MIST = colors.HexColor("#EDF3F5")
MUTED = colors.HexColor("#586A76")
st = getSampleStyleSheet()
st.add(ParagraphStyle(name="CoverTitle", parent=st["Title"], fontName="Helvetica-Bold", fontSize=26, leading=31, textColor=colors.white, alignment=TA_LEFT, spaceAfter=12))
st.add(ParagraphStyle(name="Deck", parent=st["BodyText"], fontName="Helvetica", fontSize=11, leading=15, textColor=colors.HexColor("#D9E5EA")))
st.add(ParagraphStyle(name="H1DC", parent=st["Heading1"], fontName="Helvetica-Bold", fontSize=17, leading=21, textColor=NAVY, spaceBefore=8, spaceAfter=7, keepWithNext=True))
st.add(ParagraphStyle(name="H2DC", parent=st["Heading2"], fontName="Helvetica-Bold", fontSize=11.5, leading=14, textColor=TEAL, spaceBefore=6, spaceAfter=4, keepWithNext=True))
st.add(ParagraphStyle(name="BodyDC", parent=st["BodyText"], fontName="Helvetica", fontSize=8.7, leading=12, textColor=INK, spaceAfter=5))
st.add(ParagraphStyle(name="SmallDC", parent=st["BodyText"], fontName="Helvetica", fontSize=7.2, leading=9, textColor=MUTED, spaceAfter=3))
st.add(ParagraphStyle(name="HeadDC", parent=st["BodyText"], fontName="Helvetica-Bold", fontSize=7.5, leading=9, textColor=colors.white))
st.add(ParagraphStyle(name="CellDC", parent=st["BodyText"], fontName="Helvetica", fontSize=7.2, leading=9.4, textColor=INK))
st.add(ParagraphStyle(name="CalloutDC", parent=st["BodyText"], fontName="Helvetica-Bold", fontSize=9, leading=12, textColor=NAVY))

def P(s, style="BodyDC"):
    return Paragraph(s, st[style])

def table(rows, widths):
    t = Table(rows, colWidths=widths, repeatRows=1, hAlign="LEFT")
    t.setStyle(TableStyle([("BACKGROUND", (0,0),(-1,0), NAVY), ("ROWBACKGROUNDS",(0,1),(-1,-1),[colors.white,MIST]), ("GRID",(0,0),(-1,-1),.35,colors.HexColor("#CAD5DB")), ("VALIGN",(0,0),(-1,-1),"TOP"), ("LEFTPADDING",(0,0),(-1,-1),6), ("RIGHTPADDING",(0,0),(-1,-1),6), ("TOPPADDING",(0,0),(-1,-1),5), ("BOTTOMPADDING",(0,0),(-1,-1),5)]))
    return t

class ProtocolDiagram(Flowable):
    def __init__(self):
        super().__init__(); self.width = 7.1*inch; self.height = 1.75*inch
    def draw(self):
        c=self.canv
        def box(x,y,w,h,title,body,color):
            c.setFillColor(color); c.roundRect(x,y,w,h,7,fill=1,stroke=0)
            c.setFillColor(colors.white); c.setFont("Helvetica-Bold",8); c.drawCentredString(x+w/2,y+h-13,title)
            c.setFont("Helvetica",7); c.drawCentredString(x+w/2,y+9,body)
        def line(x1,y1,x2,y2):
            c.setStrokeColor(TEAL); c.setLineWidth(2); c.line(x1,y1,x2,y2)
            c.setFillColor(TEAL); p=c.beginPath(); p.moveTo(x2,y2); p.lineTo(x2-5,y2+3); p.lineTo(x2-5,y2-3); p.close(); c.drawPath(p,fill=1,stroke=0)
        box(5,95,104,42,"DieselCairn","protocol-aware app",NAVY)
        box(151,112,139,38,"J1939 stack","29-bit CAN + diagnostics",TEAL)
        box(151,51,139,38,"J1587 message","MID / PID / checksum",TEAL)
        box(337,112,155,38,"CAN PHY","separate CANH / CANL",NAVY)
        box(337,51,155,38,"J1708 PHY","separate 2-wire link",NAVY)
        line(109,122,151,131); line(109,110,151,70); line(290,131,337,131); line(290,70,337,70)
        c.setFillColor(AMBER); c.setFont("Helvetica-Bold",7.5); c.drawCentredString(257,18,"Two links, distinct records, separate simulators. No vehicle connector on the bench.")

class WorkflowDiagram(Flowable):
    def __init__(self):
        super().__init__(); self.width=7.1*inch; self.height=1.35*inch
    def draw(self):
        c=self.canv
        labels=[("1", "Identify target"),("2", "Save Request\nJ1708 fixture"),("3", "Check gates"),("4", "Program\nJ1939 fixture"),("5", "Verify / journal")]
        xs=[5,111,217,323,429]
        for x,(n,label) in zip(xs,labels):
            c.setFillColor(NAVY); c.roundRect(x,38,92,48,7,fill=1,stroke=0)
            c.setFillColor(colors.white); c.setFont("Helvetica-Bold",9); c.drawCentredString(x+46,69,n)
            c.setFont("Helvetica",7); c.drawCentredString(x+46,52,label.split("\n")[0])
            if "\n" in label: c.drawCentredString(x+46,42,label.split("\n")[1])
        c.setStrokeColor(TEAL); c.setLineWidth(1.5)
        for x in [97,203,309,415]:
            c.line(x,62,x+14,62); c.setFillColor(TEAL); p=c.beginPath(); p.moveTo(x+14,62); p.lineTo(x+9,65); p.lineTo(x+9,59); p.close(); c.drawPath(p,fill=1,stroke=0)

class Doc(BaseDocTemplate):
    def __init__(self,path):
        super().__init__(path,pagesize=letter,leftMargin=.62*inch,rightMargin=.62*inch,topMargin=.6*inch,bottomMargin=.55*inch)
        self.addPageTemplates(PageTemplate(id="p",frames=Frame(self.leftMargin,self.bottomMargin,self.width,self.height,id="f"),onPage=self.decorate))
    def decorate(self,c,doc):
        c.saveState()
        if doc.page==1:
            c.setFillColor(NAVY); c.rect(0,0,letter[0],letter[1],fill=1,stroke=0)
            c.setFillColor(TEAL); c.rect(.62*inch,9.72*inch,.56*inch,.08*inch,fill=1,stroke=0)
            c.setFillColor(colors.white); c.setFont("Helvetica-Bold",9); c.drawString(.62*inch,9.94*inch,"DIESELCAIRN  /  PROTOCOLS & BENCH LAB")
            c.setStrokeColor(colors.HexColor("#506779")); c.line(.62*inch,.45*inch,letter[0]-.62*inch,.45*inch)
            c.setFillColor(colors.HexColor("#B9C9D3")); c.setFont("Helvetica",7.5); c.drawString(.62*inch,.27*inch,"PB305 / RE300  •  REV 1  •  18 NOV 2026")
        else:
            c.setFillColor(NAVY); c.rect(0,letter[1]-.38*inch,letter[0],.38*inch,fill=1,stroke=0)
            c.setFillColor(colors.white); c.setFont("Helvetica-Bold",8); c.drawString(.62*inch,letter[1]-.25*inch,"DIESELCAIRN  /  MULTI-LINK PROTOCOL FIELD GUIDE")
            c.setStrokeColor(colors.HexColor("#CFD9DF")); c.line(.62*inch,.42*inch,letter[0]-.62*inch,.42*inch)
            c.setFillColor(MUTED); c.setFont("Helvetica",7); c.drawString(.62*inch,.24*inch,"Software fixtures are not vehicle captures. Hardware is not vehicle-ready.")
            c.drawRightString(letter[0]-.62*inch,.24*inch,str(doc.page))
        c.restoreState()

story=[Spacer(1,1.25*inch),P("MULTI-LINK<br/>PROTOCOL & SIMULATOR GUIDE","CoverTitle"),P("A practical field guide for J1939 over CAN, J1587 over J1708, DieselCairn simulator nodes, and authorized-service workflow boundaries for a 2009 International RE300 / PB305 with an owner-reported Allison 3000PTS.","Deck"),Spacer(1,.35*inch)]
warn=Table([[P("READ FIRST","HeadDC")],[P("The software simulator is a fixture, not an electrical bus or engine emulator. Current adapter firmware is CAN-only. No live ECM/TCM write is implemented. Keep vehicle connectors disconnected during all simulator work.","CalloutDC")]],colWidths=[7.05*inch])
warn.setStyle(TableStyle([("BACKGROUND",(0,0),(-1,0),AMBER),("BACKGROUND",(0,1),(-1,1),colors.white),("LEFTPADDING",(0,0),(-1,-1),9),("RIGHTPADDING",(0,0),(-1,-1),9),("TOPPADDING",(0,0),(-1,-1),8),("BOTTOMPADDING",(0,0),(-1,-1),8)]))
story += [warn,PageBreak(),P("1 / Protocol map", "H1DC"),P("The target workflows need distinct data-link implementations. J1939 uses extended CAN frames and PGNs. J1708 provides a two-wire data link with access timing; J1587 messages use MID/PID/data/checksum above it. Keep the byte models and logs separate."),ProtocolDiagram(),P("Message boundaries", "H2DC")]
story += [table([[P("Link / layer","HeadDC"),P("Shape","HeadDC"),P("What the simulator must validate","HeadDC")],[P("J1939 over classic CAN","CellDC"),P("29-bit ID; 0-8 data bytes; PGN/source/priority","CellDC"),P("PDU1/PDU2 PGN extraction, data bounds, address behavior, TP segmentation, DM messages, timestamps and errors","CellDC")],[P("J1708","CellDC"),P("9,600 baud; 8N1; shared two-wire dominant/recessive bus","CellDC"),P("Idle qualification, priority delay, echo/collision and retry; requires device-side timing for physical operation","CellDC")],[P("J1587 over J1708","CellDC"),P("MID + PID/data + checksum; common max profile 21 bytes","CellDC"),P("Checksum, length, MID/PID parsing and provenance; decode PID meaning only from licensed/verified dictionary","CellDC")]], [1.35*inch,1.85*inch,3.85*inch]),P("Target-specific support is a separate evidence layer", "H2DC"),P("A standard PGN/SPN dictionary does not prove the user's bus broadcasts that data. A generic J1939 transmission message is not an Allison TCM model. A J1587 PID meaning must be sourced and matched to the exact module. Never fill missing readings with synthetic data without a visible SIMULATOR label.")]

story += [PageBreak(),P("2 / J1939 CAN bench", "H1DC"),P("Use a dedicated J1939 node and a separate short, terminated bench pair. The app's existing fixture can generate engine scenarios, a generic ETC2 frame, one DM1 sample, and manual classic CAN frames; trace export/replay traverses the app's packet codec. Treat all of this as protocol/UI integration, not PB305 compatibility.")]
story += [P("Software test run", "H2DC")]
for s in ["1. Start the CAN / J1708 bench and choose a scenario. Confirm the SIMULATOR banner before inspecting any values.","2. Exercise scenario start/stop/reset; confirm readings clear after stop and remain blank before start.","3. Send a known PGN/source/priority and 0-8 byte payload; verify raw ID, PGN and decoded value. Invalid bytes/DLC must be rejected.","4. Toggle the synthetic DM1 fault and verify the DTC is visibly simulated.","5. Export a fixture and replay it. Preserve source and timestamps; reject malformed identifier or payloads.","6. Turn off CAN controller/transceiver or mismatch adapter/bus bitrate. Verify errors are surfaced and no readings are claimed received."]:
    story.append(P(s,"BodyDC"))
story += [P("Still needed for realistic J1939", "H2DC"),P("Full J1939-21 TP.CM/TP.DT segmentation and reassembly; J1939-73 DM1/DM2; address claim behavior; request responses/timeouts; bus arbitration/error states; full malformed and recovery fixtures. A third-party utility can provide reference nodes, but no generic emulator proves the International ECM or Allison TCM behavior.")]

story += [PageBreak(),P("3 / J1708 + J1587 bench", "H1DC"),P("The current app exposes a software transmitter fixture. It constructs MID + raw data + checksum, enforces a 21-byte total, models idle-high-bit and priority delay gates, and runs the message through the virtual adapter envelope. It does not produce wire timing, analog levels, collision waveforms or a physical serial capture.")]
story += [P("Use the virtual panel", "H2DC")]
for s in ["1. Start the isolated software session; open J1708/J1587 Virtual Link.","2. Enter MID as hexadecimal and enter raw PID/data bytes. The app computes the checksum; these bytes do not imply a decoded vehicle parameter.","3. Set idle high-bit count and priority class. A transmit requires at least ten idle-high bit-times and the selected delay.","4. Verify the resulting raw message contains MID and data, a valid checksum, and a SIMULATOR source.","5. Set idle below ten bits or enable collision injection. The virtual message should fail and increment the modeled error counter.","6. Exporting a J1939 trace does not export J1587. A common multi-link capture format remains required."]:
    story.append(P(s,"BodyDC"))
story += [P("Physical requirements", "H2DC"),table([[P("Requirement","HeadDC"),P("Bench proof","HeadDC")],[P("Compliant J1708 PHY, not generic RS-485","CellDC"),P("Review selected vendor J1708 circuit; measure line polarity, common mode, loading, isolation, protection and fault behavior","CellDC")],[P("Adapter-side access timing","CellDC"),P("Logic analyzer checks 9,600 8N1, ten idle bit-times, P_D = P x 2 x tB, echo/collision detection and bounded retry","CellDC")],[P("Separate source node","CellDC"),P("Second compliant MCU PHY with its own USB management control, simulator-only firmware, raw fixture selection and no vehicle harness","CellDC")]], [2.1*inch,4.95*inch])]

story += [PageBreak(),P("4 / Two-link Navistar service sequence", "H1DC"),P("Navistar bulletin IK2600282 says NavKal uses J1708 for Save Request and J1939 for Program on relevant 2007-09 MaxxForce engines. Verify exact applicability against the engine and module labels. The bulletin does not provide a complete third-party wire-protocol implementation or authorize bypassing OEM controls."),WorkflowDiagram(),P("Simulator state machine cases", "H2DC")]
for s in ["Pass: target identity -> simulated J1708 Save Request -> verified file/approval/recovery gates -> simulated J1939 Program -> simulated read-back/audit event.","Fail before Program: unknown engine family, wrong VIN/module/calibration, denied authorization, missing backup/recovery, J1708 timeout/rejection/collision or disconnect.","Fail during simulated Program: J1939 bus-off, missing transport segment, supply brownout, adapter reset or cable loss. Preserve event journal and show a recovery decision.","Success must be titled SIMULATED WORKFLOW RESULT. It is not a completed flash or proof of ECM/TCM behavior."]:
    story.append(P(s,"BodyDC"))
story += [P("External open-source tools reviewed", "H2DC"),table([[P("Tool","HeadDC"),P("What it can help with","HeadDC"),P("Limit","HeadDC")],[P("CANExplorer (MIT)","CellDC"),P("Generic J1939 restbus and GUI; macOS ARM release; live J1708 capture/J1587 decode with supported physical hardware","CellDC"),P("Downloaded release signature is ad hoc/Gatekeeper rejects; keep unlaunched. No virtual J1708 source node or target ECU/TCM.","CellDC")],[P("pycangui (Apache-2.0)","CellDC"),P("GUI and J1939 simulated nodes; macOS support; custom Python nodes","CellDC"),P("Virtual bus is process-local; no J1708 emulator or target TCM.","CellDC")],[P("pretty_j1587 (MIT)","CellDC"),P("J1708/J1587 log parser and fuzzing ideas","CellDC"),P("Not timed or electrical network simulation; do not bundle SAE PID database without rights.","CellDC")]], [1.35*inch,2.8*inch,2.9*inch])]

story += [PageBreak(),P("5 / Custom simulator build plan", "H1DC"),P("No credible open-source virtual J1708/J1587 wire/node simulator was found. Build a DieselCairn-owned deterministic software model and a separate MCU-based physical J1708 simulator node from the selected vendor reference circuit. External tools remain optional test/reference applications; DieselCairn owns its app-to-simulator integration contract.")]
story += [P("Software nodes", "H2DC")]
for s in ["Navistar engine fixture: deterministic standard J1939 broadcasts/DM1 and documented request responses only after target source evidence.","Allison TCM fixture: generic test node until exact transmission, TCM identity and authorized mapping are collected; synthetic 5/6-range states cannot imply eligibility.","J1708/J1587 source node: deterministic MID/PID bytes, checksum, gaps, priority, echo collision/retry, malformed checksum and source identity; use a bus interface that can switch between in-process events, localhost IPC and hardware UART.","Simulator controller GUI: protocol-specific scenario editor, separate node online/offline and power states, event rate, bus timing/fault sliders, live raw capture, trace export/replay and source labels.","Hardware control: independent USB management channel to simulator MCUs; query firmware/version/scenario, start/stop, set fixtures, retrieve status. Never use CAN/J1708 itself as device-management transport."]:
    story.append(P(s,"BodyDC"))
story += [P("Acceptance and QA", "H2DC")]
story += [table([[P("Gate","HeadDC"),P("Evidence to retain","HeadDC")],[P("Protocol unit","CellDC"),P("Golden frames/messages, checksum/length negatives, parser results and test output","CellDC")],[P("Device firmware","CellDC"),P("Firmware hash, board serial, logic-analyzer trace, time measurements and error recovery","CellDC")],[P("App workflow","CellDC"),P("Mac and physical iPhone app build, screenshots, test path, adapter/simulator versions and outcome","CellDC")],[P("Vehicle readiness","CellDC"),P("Exact connector/wire diagram, ratings, protection/ESD/isolation qualification, target/module identity and approved service evidence. Not currently met.","CellDC")]], [1.4*inch,5.65*inch]),P("References and evidence", "H2DC")]
for name,url in [("Navistar IK2600282","https://static.nhtsa.gov/odi/tsbs/2025/MC-11019110-0001.pdf"),("TI AN-915 J1708 physical layer","https://www.ti.com/lit/an/snla038b/snla038b.pdf"),("U.S. DOT J1587/J1708 overview","https://www.its.dot.gov/StandardsTraining/modtransit5/sup/mt5sup.pdf"),("Renesas AN1990 J1708 physical layer","https://www.renesas.com/en/document/apn/an1990-rs-485-transceivers-j1708-physical-layer-applications-heavy-duty-vehicles"),("CANExplorer release and source","https://github.com/AKJ7/CANExplorer"),("pycangui source","https://github.com/davhodg/pycangui"),("pretty_j1587 source","https://github.com/ainfosec/pretty_j1587")]:
    story.append(P(f"<link href='{url}' color='#0A8585'>{name}</link>","SmallDC"))

doc=Doc(str(OUT)); doc.build(story)
print(OUT)
