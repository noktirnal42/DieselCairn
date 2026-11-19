from pathlib import Path
import sys

sys.path.insert(0, "/tmp/dieselcairn_pdfdeps")
from reportlab.lib import colors
from reportlab.lib.enums import TA_LEFT, TA_CENTER
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import BaseDocTemplate, Frame, PageTemplate, Paragraph, Spacer, Table, TableStyle, PageBreak, Flowable, HRFlowable

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output/pdf/DieselCairn-Dual-Link-Hardware-Builds-and-Buy-Guide.pdf"
OUT.parent.mkdir(parents=True, exist_ok=True)

NAVY=colors.HexColor("#12283D")
INK=colors.HexColor("#1D2B36")
TEAL=colors.HexColor("#087E83")
PALE=colors.HexColor("#EDF3F5")
AMBER=colors.HexColor("#A9610A")
MUTED=colors.HexColor("#566978")
WHITE=colors.white

st=getSampleStyleSheet()
st.add(ParagraphStyle(name="CoverTitle", parent=st["Title"], fontName="Helvetica-Bold", fontSize=28, leading=32, textColor=WHITE, alignment=TA_LEFT, spaceAfter=13))
st.add(ParagraphStyle(name="Deck", parent=st["BodyText"], fontName="Helvetica", fontSize=11.5, leading=16, textColor=colors.HexColor("#DBE6ED")))
st.add(ParagraphStyle(name="H1DC", parent=st["Heading1"], fontName="Helvetica-Bold", fontSize=18, leading=22, textColor=NAVY, spaceBefore=8, spaceAfter=7, keepWithNext=True))
st.add(ParagraphStyle(name="H2DC", parent=st["Heading2"], fontName="Helvetica-Bold", fontSize=12, leading=15, textColor=TEAL, spaceBefore=7, spaceAfter=4, keepWithNext=True))
st.add(ParagraphStyle(name="BodyDC", parent=st["BodyText"], fontName="Helvetica", fontSize=8.8, leading=12.3, textColor=INK, spaceAfter=5))
st.add(ParagraphStyle(name="SmallDC", parent=st["BodyText"], fontName="Helvetica", fontSize=7.4, leading=9.5, textColor=MUTED, spaceAfter=3))
st.add(ParagraphStyle(name="TableHeadDC", parent=st["BodyText"], fontName="Helvetica-Bold", fontSize=7.7, leading=9.6, textColor=WHITE))
st.add(ParagraphStyle(name="TableDC", parent=st["BodyText"], fontName="Helvetica", fontSize=7.5, leading=9.8, textColor=INK))
st.add(ParagraphStyle(name="CalloutDC", parent=st["BodyText"], fontName="Helvetica-Bold", fontSize=9.3, leading=13, textColor=NAVY, spaceAfter=0))
st.add(ParagraphStyle(name="StepDC", parent=st["BodyText"], fontName="Helvetica", fontSize=8.4, leading=11.5, textColor=INK, leftIndent=12, firstLineIndent=-12, spaceAfter=4))

def P(x, style="BodyDC"):
    return Paragraph(x,st[style])

class Architecture(Flowable):
    def __init__(self,width=7.15*inch,height=1.8*inch):
        super().__init__(); self.width=width; self.height=height
    def draw(self):
        c=self.canv
        def box(x,y,w,h,title,sub,fill,stroke=None):
            c.setFillColor(fill); c.setStrokeColor(stroke or fill); c.roundRect(x,y,w,h,8,stroke=1,fill=1)
            c.setFillColor(WHITE); c.setFont("Helvetica-Bold",8.3); c.drawCentredString(x+w/2,y+h-14,title)
            c.setFont("Helvetica",7); c.drawCentredString(x+w/2,y+9,sub)
        def arrow(x1,y1,x2,y2,color=TEAL):
            c.setStrokeColor(color); c.setFillColor(color); c.setLineWidth(1.5); c.line(x1,y1,x2,y2)
            import math
            a=math.atan2(y2-y1,x2-x1); r=5
            p=c.beginPath(); p.moveTo(x2,y2); p.lineTo(x2-r*math.cos(a-.45),y2-r*math.sin(a-.45)); p.lineTo(x2-r*math.cos(a+.45),y2-r*math.sin(a+.45)); p.close()
            c.drawPath(p,stroke=0,fill=1)
        box(6,64,73,50,"MacBook","USB data",NAVY)
        box(99,64,96,50,"Host options","A STM32  |  B Leonardo  |  C FT232H",TEAL)
        box(216,64,94,50,"MCP2515","CAN controller",NAVY)
        box(330,64,96,50,"Isolation + PHY","transceiver / TVS",TEAL)
        box(447,64,64,50,"Bench CAN","twisted pair",NAVY)
        arrow(79,89,99,89); arrow(195,89,216,89); arrow(310,89,330,89); arrow(426,89,447,89)
        c.setFillColor(AMBER); c.setFont("Helvetica-Bold",7.6); c.drawCentredString(257,35,"Vehicle connector stays physically disconnected")
        c.setStrokeColor(AMBER); c.setDash(3,2); c.line(8,20,506,20); c.setDash()
        c.setFont("Helvetica",7); c.setFillColor(MUTED); c.drawCentredString(257,5,"CAN and J1708/J1587 require separate PHYs, firmware paths and isolated test networks.")

class BusLayout(Flowable):
    def __init__(self,width=7.15*inch,height=1.7*inch):
        super().__init__(); self.width=width; self.height=height
    def draw(self):
        c=self.canv
        def node(x,title,term):
            c.setFillColor(NAVY); c.roundRect(x,52,125,55,7,fill=1,stroke=0)
            c.setFillColor(WHITE); c.setFont("Helvetica-Bold",9); c.drawCentredString(x+62.5,87,title)
            c.setFont("Helvetica",7.3); c.drawCentredString(x+62.5,70,term)
        node(14,"CAN node 1","120 ohm at bus end")
        node(375,"CAN node 2","120 ohm at bus end")
        c.setStrokeColor(TEAL); c.setLineWidth(3); c.line(139,85,375,85); c.line(139,69,375,69)
        c.setFillColor(TEAL); c.setFont("Helvetica-Bold",8); c.drawCentredString(257,92,"CAN-H / CANH")
        c.drawCentredString(257,54,"CAN-L / CANL")
        c.setStrokeColor(AMBER); c.setLineWidth(1.4); c.setDash(4,3); c.line(257,45,257,18); c.setDash()
        c.setFillColor(AMBER); c.setFont("Helvetica-Bold",8); c.drawCentredString(257,4,"NO vehicle harness, ECU, or TCM on this prototype bench")

class GuideDoc(BaseDocTemplate):
    def __init__(self,filename,**kwargs):
        super().__init__(filename,pagesize=letter,leftMargin=.62*inch,rightMargin=.62*inch,topMargin=.62*inch,bottomMargin=.58*inch,**kwargs)
        self.addPageTemplates(PageTemplate(id="guide",frames=Frame(self.leftMargin,self.bottomMargin,self.width,self.height,id="body"),onPage=self.decorate))
    def decorate(self,canvas,doc):
        canvas.saveState()
        if doc.page==1:
            canvas.setFillColor(NAVY); canvas.rect(0,0,letter[0],letter[1],fill=1,stroke=0)
            canvas.setFillColor(TEAL); canvas.rect(.62*inch,9.72*inch,.56*inch,.08*inch,fill=1,stroke=0)
            canvas.setFillColor(WHITE); canvas.setFont("Helvetica-Bold",9); canvas.drawString(.62*inch,9.94*inch,"DIESELCAIRN  /  HARDWARE WORKSHOP")
            canvas.setStrokeColor(colors.HexColor("#51677A")); canvas.line(.62*inch,.48*inch,letter[0]-.62*inch,.48*inch)
            canvas.setFont("Helvetica",7.8); canvas.setFillColor(colors.HexColor("#B9C9D3")); canvas.drawString(.62*inch,.29*inch,"BENCH PROTOTYPES  •  REV 1  •  18 NOV 2026")
        else:
            canvas.setFillColor(NAVY); canvas.rect(0,letter[1]-.4*inch,letter[0],.4*inch,fill=1,stroke=0)
            canvas.setFillColor(WHITE); canvas.setFont("Helvetica-Bold",8); canvas.drawString(.62*inch,letter[1]-.25*inch,"DIESELCAIRN  /  DUAL-LINK ADAPTER BUILDS")
            canvas.setStrokeColor(colors.HexColor("#CFD9DF")); canvas.line(.62*inch,.43*inch,letter[0]-.62*inch,.43*inch)
            canvas.setFillColor(MUTED); canvas.setFont("Helvetica",7.5); canvas.drawString(.62*inch,.25*inch,"Bench-only prototype. No vehicle connector use authorized.")
            canvas.drawRightString(letter[0]-.62*inch,.25*inch,str(doc.page))
        canvas.restoreState()

def table(data,widths):
    t=Table(data,colWidths=widths,repeatRows=1,hAlign="LEFT")
    t.setStyle(TableStyle([("BACKGROUND",(0,0),(-1,0),NAVY),("ROWBACKGROUNDS",(0,1),(-1,-1),[WHITE,PALE]),("GRID",(0,0),(-1,-1),.35,colors.HexColor("#C9D5DC")),("VALIGN",(0,0),(-1,-1),"TOP"),("LEFTPADDING",(0,0),(-1,-1),6),("RIGHTPADDING",(0,0),(-1,-1),6),("TOPPADDING",(0,0),(-1,-1),5),("BOTTOMPADDING",(0,0),(-1,-1),5)]))
    return t

story=[]
story += [Spacer(1,1.3*inch),P("DUAL-LINK HARDWARE<br/>BUILDS & BUY GUIDE","CoverTitle"),P("Bench construction architecture for J1939/CAN and J1587/J1708 adapters and simulator nodes for the 2009 International RE300 / PB305 with an owner-reported Allison 3000 Series 3000PTS transmission. Verify its nameplate and TCM identity before target-specific work.","Deck"),Spacer(1,.32*inch)]
warn=Table([[P("IMPORTANT SCOPE","TableHeadDC")],[P("The three host-path proposals below are CAN-only legacy prototypes. They are not vehicle-ready. The PB305 workflow also requires a separately designed J1708 PHY and J1587-capable device firmware. A reviewed dual-link schematic, exact BOM, connector pinout and electrical validation do not yet exist. Keep vehicle connectors disconnected.","CalloutDC")]],colWidths=[7.05*inch])
warn.setStyle(TableStyle([("BACKGROUND",(0,0),(-1,0),AMBER),("BACKGROUND",(0,1),(-1,1),WHITE),("LEFTPADDING",(0,0),(-1,-1),10),("RIGHTPADDING",(0,0),(-1,-1),10),("TOPPADDING",(0,0),(-1,-1),9),("BOTTOMPADDING",(0,0),(-1,-1),9)]))
story += [warn,Spacer(1,.32*inch),P("Versions: STM32 Nucleo-F031K6 • Arduino Leonardo • FT232H MPSSE", "Deck"),PageBreak()]

story += [P("1 / System plan", "H1DC"),P("The existing host paths reach an MCP2515 for J1939/CAN: embedded MCU over serial, Arduino USB CDC, or direct FT232H SPI/MPSSE. Each intended dual-link adapter additionally needs a separate J1708 PHY, hardware-timed MCU path, protection/isolation and test connector. J1708 must not share the CAN HAT or use host-side macOS scheduling.") ,Architecture(),Spacer(1,8)]
box=Table([[P("BUILD PRIORITY","TableHeadDC"),P("WHAT WORKS TODAY","TableHeadDC"),P("WHAT IS STILL OPEN","TableHeadDC")],[P("Start with the Leonardo","TableDC"),P("The repository contains an Arduino Leonardo USB-CDC bridge source, with a local transmit-arm jumper and MCP2515 settings.","TableDC"),P("The Mac/iPhone apps do not yet have production physical transport integration. STM32 firmware and FT232H Mac driver service remain to be developed.","TableDC")]],colWidths=[1.45*inch,2.7*inch,2.9*inch])
box.setStyle(TableStyle([("BACKGROUND",(0,0),(-1,0),TEAL),("ROWBACKGROUNDS",(0,1),(-1,-1),[PALE]),("GRID",(0,0),(-1,-1),.35,colors.HexColor("#C9D5DC")),("VALIGN",(0,0),(-1,-1),"TOP"),("LEFTPADDING",(0,0),(-1,-1),7),("RIGHTPADDING",(0,0),(-1,-1),7),("TOPPADDING",(0,0),(-1,-1),7),("BOTTOMPADDING",(0,0),(-1,-1),7)]))
story += [box,P("No compile, bench capture, or successful CAN-HIL test is claimed by this purchasing guide. Each device build must pass the staged checks before it counts as an adapter.")]

story += [PageBreak(),P("2 / Shopping list", "H1DC"),P("Parts and vendor pages were checked on 18 November 2026. Listing prices are snapshots before tax/shipping; recheck stock and revisions before ordering.")]
rows=[[P("QTY","TableHeadDC"),P("PART","TableHeadDC"),P("BUY / VERIFY","TableHeadDC")],
 [P("3","TableDC"),P("Waveshare 2-CH CAN HAT+ (SKU 27338)","TableDC"),P("<link href='https://www.waveshare.com/product/2-ch-can-hat-plus.htm' color='#087E83'>Manufacturer product page</link>. US$24.99 each observed. Confirm the + version, MCP2515, 16 MHz crystal, 3.3/5V logic selector, isolation, terminal blocks, and selectable 120-ohm resistor. Avoid generic lookalike modules.","TableDC")],
 [P("1","TableDC"),P("STM32 NUCLEO-F031K6","TableDC"),P("<link href='https://estore.st.com/en/products/evaluation-tools/product-evaluation-tools/mcu-mpu-eval-tools/stm32-mcu-mpu-eval-tools/stm32-nucleo-boards/nucleo-f031k6.html' color='#087E83'>ST order page</link>. US$32.73 observed. Use ST-LINK VCP for serial; the target MCU itself has no native USB/CAN peripheral.","TableDC")],
 [P("1","TableDC"),P("Arduino Leonardo Rev3 / ATmega32U4","TableDC"),P("<link href='https://docs.arduino.cc/hardware/leonardo/' color='#087E83'>Arduino product and Buy link</link>. Confirm genuine/Rev3-compatible Leonardo and ATmega32U4. Do not substitute an Uno pinout.","TableDC")],
 [P("1","TableDC"),P("Adafruit FT232H breakout, product 2264","TableDC"),P("<link href='https://www.adafruit.com/product/2264' color='#087E83'>Adafruit product page</link>. US$14.95 observed. USB-C revision; MPSSE supports SPI but requires host software.","TableDC")],
 [P("Each","TableDC"),P("USB data cables","TableDC"),P("Nucleo: USB-A to Micro-B; Leonardo: USB-A to Micro-B; FT232H: USB-C. Use USB-C adapters/hub only as needed. Verify data support, not charge-only.","TableDC")],
 [P("1 set","TableDC"),P("Jumpers and headers","TableDC"),P("Short 10-15 cm 0.1-inch Dupont jumpers, female-to-male for host header to HAT header; solder straight male pin headers to FT232H through-holes if not fitted. Confirm HAT's included 2x20 header contents before ordering.","TableDC")],
 [P("1","TableDC"),P("Bench harness","TableDC"),P("Short twisted pair plus two 120-ohm, 1%, 0.25 W resistors only if you do not use HAT termination at each end. Use board terminal markings for CANH/CANL; no vehicle connector.","TableDC")],]
story += [table(rows,[.48*inch,1.72*inch,4.85*inch]),Spacer(1,8),P("CAN parts list prices are only a planning snapshot for the earlier CAN prototypes; they exclude J1708 PHY, timed MCU, isolation/power, protections, simulator-node parts, tools, cables and enclosure. No dual-link total is available because the J1708 design/BOM is open.","BodyDC"),P("Do not order a vehicle diagnostic connector or connect these prototypes to the bus. Exact J1708 parts and connector are gated on a reviewed reference circuit and PB305 wiring evidence.","BodyDC")]

story += [PageBreak(),P("3 / Version A — STM32 Nucleo-F031K6", "H1DC"),P("Buy the NUCLEO-F031K6 and one CAN HAT+. The Nucleo target talks SPI to the MCP2515; its ST-LINK USB interface supplies a virtual COM port for the host. The STM32F031K6 is a 3.3 V MCU. Use the Nucleo board manual UM1956 for connector identities.","BodyDC")]
a=[ [P("NUCLEO-F031K6","TableHeadDC"),P("SIGNAL","TableHeadDC"),P("CAN HAT+ 40-PIN HEADER","TableHeadDC")],
 [P("CN4 pin 4","TableDC"),P("+5V host power","TableDC"),P("physical pin 2","TableDC")],
 [P("CN3 pin 4 or CN4 pin 2","TableDC"),P("Ground","TableDC"),P("physical pin 6","TableDC")],
 [P("D13 / PB3","TableDC"),P("SPI SCK","TableDC"),P("physical pin 40 / GPIO21","TableDC")],
 [P("D11 / PB5","TableDC"),P("SPI MOSI","TableDC"),P("physical pin 38 / GPIO20","TableDC")],
 [P("D12 / PB4","TableDC"),P("SPI MISO","TableDC"),P("physical pin 35 / GPIO19","TableDC")],
 [P("D10 / PA11","TableDC"),P("CS0","TableDC"),P("physical pin 11 / GPIO17","TableDC")],
 [P("D3 / PB0 (optional)","TableDC"),P("CAN0 INT","TableDC"),P("physical pin 15 / GPIO22","TableDC")],]
story += [table(a,[1.9*inch,2.15*inch,3*inch]),P("Build steps", "H2DC")]
for x in ["1. Keep power disconnected. Set HAT logic selector to 3.3 V and CAN0 termination off.","2. Connect six required lines: +5V, GND, SCK, MOSI, MISO, and CS0. Add INT only if the STM32 firmware uses it.","3. Connect the Nucleo to the Mac using Micro-B USB. Verify ST-LINK and virtual serial enumeration.","4. Record the target firmware UART pin assignment; UM1956 notes shared VCP/MCU USART resources. Compile/flash only the STM32 adapter firmware after its pin map and protocol tests are implemented.","5. Start with receive-only mode, then follow the generic bench acceptance section. The existing project does not yet include a complete STM32 adapter firmware target."]:
    story.append(P(x,"StepDC"))

story += [PageBreak(),P("4 / Version B — Arduino Leonardo", "H1DC"),P("This is the recommended first build because the repository already contains a Leonardo USB-CDC bridge. Its SPI signals are exposed at the ICSP header. Wire by the Leonardo's own pinout, not an Uno diagram.")]
b=[[P("LEONARDO","TableHeadDC"),P("SIGNAL","TableHeadDC"),P("CAN HAT+ 40-PIN HEADER","TableHeadDC")],
 [P("5V","TableDC"),P("Host-side power","TableDC"),P("physical pin 2","TableDC")],
 [P("GND","TableDC"),P("Ground","TableDC"),P("physical pin 6","TableDC")],
 [P("ICSP SCK","TableDC"),P("SPI SCK","TableDC"),P("physical pin 40","TableDC")],
 [P("ICSP MOSI","TableDC"),P("SPI MOSI","TableDC"),P("physical pin 38","TableDC")],
 [P("ICSP MISO","TableDC"),P("SPI MISO","TableDC"),P("physical pin 35","TableDC")],
 [P("D10","TableDC"),P("CS0","TableDC"),P("physical pin 11","TableDC")],
 [P("D7 to GND","TableDC"),P("Local TX arm (leave open)","TableDC"),P("not connected to HAT","TableDC")]]
story += [table(b,[1.8*inch,2.2*inch,3.05*inch]),P("Build and firmware steps", "H2DC")]
for x in ["1. Leave the D7-to-GND arm jumper off. Set the HAT logic selector to 5 V and CAN0 termination off.","2. Wire 5V/GND, SPI at the ICSP header, and D10 to the HAT channel-0 pins in the table.","3. Connect Micro-B USB to Mac and verify a USB CDC serial device appears.","4. Open Firmware/ArduinoLeonardoAdapter, select Arduino Leonardo / ATmega32U4, and install the pinned mcp_can library version 1.5.1 as documented. Verify the HAT's marked 16 MHz oscillator matches firmware settings.","5. Compile, inspect the build result, flash the Leonardo, then verify it starts listen-only and reports disarmed. The code's bench bitrate is 250 kbit/s; use that only on the isolated test network.","6. Test frame receive and protocol CRC. Confirm a host request to enable TX is rejected while D7 is open. Do not treat the jumper as permission for vehicle transmission."]:
    story.append(P(x,"StepDC"))

story += [PageBreak(),P("5 / Version C — FT232H", "H1DC"),P("This build turns the Mac into the SPI host. FT232H does not speak CAN by itself: it drives the MCP2515 through MPSSE SPI, while the HAT supplies controller/physical-layer isolation. PyFtdi documents FT232H SPI/MPSSE and macOS, but DieselCairn's native host driver is not implemented.")]
c=[[P("FT232H PIN","TableHeadDC"),P("ROLE","TableHeadDC"),P("CAN HAT+ 40-PIN HEADER","TableHeadDC")],
 [P("5V","TableDC"),P("Host-side power","TableDC"),P("physical pin 2","TableDC")],
 [P("GND","TableDC"),P("Ground","TableDC"),P("physical pin 6","TableDC")],
 [P("D0","TableDC"),P("SCLK","TableDC"),P("physical pin 40","TableDC")],
 [P("D1","TableDC"),P("MOSI","TableDC"),P("physical pin 38","TableDC")],
 [P("D2","TableDC"),P("MISO","TableDC"),P("physical pin 35","TableDC")],
 [P("C0","TableDC"),P("Active-low CS0","TableDC"),P("physical pin 11","TableDC")],
 [P("C1 optional","TableDC"),P("CAN0 INT","TableDC"),P("physical pin 15","TableDC")]]
story += [table(c,[1.5*inch,2.5*inch,3.05*inch]),P("Build steps", "H2DC")]
for x in ["1. Solder 0.1-inch male headers to the FT232H breakout only if needed; inspect its revision. Leave CANH/CANL open.","2. Set the CAN HAT logic selector to 3.3 V and CAN0 termination off.","3. Wire 5V/GND and D0/D1/D2/C0. Verify 3.3 V logic on the signal side; never wire FT232H 5V into a logic signal.","4. Connect USB-C data to the Mac. Use a project virtual environment and a pinned PyFtdi version; do not add unsigned kernel extensions.","5. Implement a small MCP2515 identification/read-only test first. Start with low SPI clock and no CAN transmit. Record USB enumeration, driver claim, SPI response, reset behavior, and errors.","6. Keep this path as a hardware lab instrument until the same transport is wrapped in a maintained DieselCairn service and the Mac UI can discover/manage it."]:
    story.append(P(x,"StepDC"))

story += [PageBreak(),P("6 / CAN bench harness and acceptance", "H1DC"),P("Use a closed linear two-node CAN bus, with one 120-ohm terminator at each physical end. For first tests, leave every vehicle-facing connector absent and use generic frame fixtures with no engine actuation or programming meaning."),BusLayout(),P("CAN bench acceptance sequence", "H2DC")]
for x in ["1. Power only the host board. Check host enumeration and firmware/driver version. Verify the adapter reports listen-only and not armed.","2. Meter the host-side power rails and check for shorts. Confirm isolation board/module revision and logic selector. Do not probe or power a vehicle connector.","3. Connect the short twisted pair CANH-to-CANH and CANL-to-CANL. Check that only the two bus-end 120-ohm terminations are enabled.","4. Set both bench nodes to the same bench rate (start at 250 kbit/s only if the CAN HAT is 16 MHz and the selected firmware matches). Verify with a known benign frame fixture.","5. Test receive, identifier/DLC/payload/timestamp integrity, disconnect detection, malformed packet rejection, and bus-off recovery.","6. On Version B, with D7 open, verify SET_MODE transmit is denied. Only after this check, enable the hardware arm for harmless bench-only test frames observed by the second node.","7. Save logs, oscilloscope/logic analyzer captures if available, wiring photos, serials, module revision, oscillator, bitrate, termination, firmware hash, and pass/fail results."]:
    story.append(P(x,"StepDC"))

story += [P("Do not connect any adapter to the bus. The CAN builds remain bench-only; dual-link design and validation is open.","CalloutDC"),P("Current limits", "H2DC"),P("The component builds in this guide cover a classic CAN-only test path and do not support the full documented Navistar procedure. A separate compliant J1708 physical layer and J1587 message firmware are required. None of the adapter paths is currently an ECM/TCM flash interface.")]

story += [PageBreak(),P("7 / J1708 + J1587 dual-link design", "H1DC"),P("J1708 is a separate 9,600-baud two-wire network. J1587 carries MID/PID/data/checksum messages over that link. It is not CAN and a generic RS-485 module is not automatically compliant. Navistar IK2600282 documents J1708 for the Save Request step and J1939 for Program on applicable 2007-09 MaxxForce engines; verify applicability to the actual engine/module.")]
story += [P("Required architecture", "H2DC")]
arch=Table([[P("MCU / adapter firmware","TableHeadDC"),P("J1939 branch","TableHeadDC"),P("J1708 / J1587 branch","TableHeadDC")],[P("Independent protocol channels; default listen-only; local physical TX interlock; accurate per-link timestamps and errors.","TableDC"),P("MCP2515 + CAN transceiver + reviewed isolation/protection + separate CAN bench node.","TableDC"),P("Compliant dominant/recessive PHY + hardware timed UART/DE + echo/collision detect + priority delay/retry + separate J1708 simulator node.","TableDC")]],colWidths=[2.15*inch,2.35*inch,2.55*inch])
arch.setStyle(TableStyle([("BACKGROUND",(0,0),(-1,0),NAVY),("ROWBACKGROUNDS",(0,1),(-1,-1),[PALE]),("GRID",(0,0),(-1,-1),.35,colors.HexColor("#C9D5DC")),("VALIGN",(0,0),(-1,-1),"TOP"),("LEFTPADDING",(0,0),(-1,-1),6),("RIGHTPADDING",(0,0),(-1,-1),6),("TOPPADDING",(0,0),(-1,-1),6),("BOTTOMPADDING",(0,0),(-1,-1),6)]))
story += [arch,Spacer(1,8),P("J1708 engineering notes", "H2DC")]
for x in ["Use the selected transceiver manufacturer's J1708 reference circuit; review driver polarity, node loading/bias/filtering, isolation, fault range, protection and component tolerances. A candidate part is not a complete schematic.","Firmware must qualify 10 consecutive high idle bit-times, apply priority delay P_D = P x 2 x tB, compare transmitted echo for collision, and perform bounded retry/backoff. Validate with hardware timing captures; a host GUI cannot prove timing.","J1587 messages contain MID, PID/data and checksum. The common profile allows up to 21 bytes including MID/checksum; checksum sum modulo 256 is 0xFF. Keep raw messages separate from J1939 PGN/CAN records.","Do not add 120-ohm CAN termination to J1708. Do not guess the PB305 connector/pinout. Keep adapter and both simulator nodes isolated from vehicle wiring."]:
    story.append(P(x,"StepDC"))
story += [P("Separate physical simulator nodes", "H2DC"),P("Use a second compliant J1708 PHY on a dedicated MCU simulator node, controlled over separate USB. A GUI selects MID/PID fixtures, rates, idle, collision/noise and stuck-line scenarios. The J1939 simulator node likewise has its own bus and management link. Keep CAN and J1708 test pairs separate; there is no vehicle connector in this setup.","BodyDC"),P("Acceptance gates", "H2DC")]
for x in ["Measure J1708 9,600 8N1 signaling, physical levels, idle qualification, priority delay, echo collision and retry with a logic analyzer/differential probe.","Verify checksum/length, malformed-message handling, independent network captures, timestamps and fail-safe recovery through adapter firmware.","Test power loss, reset, disconnected cable, bus error and simultaneous CAN/J1708 traffic. Record board revision, firmware hash, tools, traces, photos and pass/fail.","Do not label hardware vehicle-ready until circuit, transient/ESD, isolation, connector and build-specific wiring reviews are completed."]:
    story.append(P(x,"StepDC"))

story += [PageBreak(),P("Parts references and open gates", "H1DC"),P("Purchasing sources", "H2DC")]
for name,url in [
 ("ST NUCLEO-F031K6 listing and UM1956 board manual","https://estore.st.com/en/products/evaluation-tools/product-evaluation-tools/mcu-mpu-eval-tools/stm32-mcu-mpu-eval-tools/stm32-nucleo-boards/nucleo-f031k6.html"),
 ("Arduino Leonardo board guide and Buy link","https://docs.arduino.cc/hardware/leonardo/"),
 ("Waveshare 2-CH CAN HAT+ specification, schematic, and jumper guide","https://www.waveshare.com/product/2-ch-can-hat-plus.htm"),
 ("Adafruit FT232H product 2264 and current price","https://www.adafruit.com/product/2264"),
 ("Adafruit FT232H pin map","https://learn.adafruit.com/circuitpython-on-any-computer-with-ft232h/pinouts"),
 ("PyFtdi supported device and host matrix","https://eblot.github.io/pyftdi/index.html"),
 ("Microchip MCP2515 in-production status and datasheet","https://www.microchip.com/en-us/product/MCP2515"),
 ("Navistar programming bulletin IK2600282 (2007-09 MaxxForce DT/9/10)","https://static.nhtsa.gov/odi/tsbs/2025/MC-11019110-0001.pdf")]:
    story.append(P(f"• <link href='{url}' color='#087E83'>{name}</link>","SmallDC"))
story += [Spacer(1,6),P("Before checkout", "H2DC")]
for x in ["☐ Confirm the exact board revision and included headers from the listing/manual.","☐ Confirm the HAT's 16 MHz oscillator and 3.3/5 V logic jumper before buying or wiring jumpers.","☐ Check delivery, tax, USB cable ends, and Mac port/hub needs; prices above are snapshots, not quotes.","☐ Buy for three isolated CAN bench prototypes only. Do not purchase these under the assumption they can flash the bus ECU/TCU.","☐ Keep all vehicle connectors physically separate from the bench kit."]:
    story.append(P(x,"StepDC"))
story += [Spacer(1,8),HRFlowable(width="100%",thickness=.8,color=TEAL),Spacer(1,4),P("Prepared for DieselCairn bench prototyping. This is not an automotive-grade design, installation instruction for a vehicle, or permission to transmit to a vehicle network. Complete the VIN/build-specific electrical review and validate all protections before field use. Revision 1 • 18 November 2026.","SmallDC")]

doc=GuideDoc(str(OUT),title="DieselCairn Dual-Link Hardware Builds and Buy Guide",author="DieselCairn")
doc.build(story)
print(OUT)
