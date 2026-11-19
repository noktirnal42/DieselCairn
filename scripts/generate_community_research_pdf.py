from pathlib import Path
import sys

sys.path.insert(0, "/tmp/dieselcairn_pdfdeps")
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER, TA_LEFT
from reportlab.lib.pagesizes import letter
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import inch
from reportlab.platypus import (
    BaseDocTemplate, Frame, PageTemplate, Paragraph, Spacer, Table, TableStyle,
    PageBreak, KeepTogether, HRFlowable
)

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "output" / "pdf" / "DieselCairn-Independent-School-Bus-Field-Research.pdf"
OUT.parent.mkdir(parents=True, exist_ok=True)

INK = colors.HexColor("#172638")
NAVY = colors.HexColor("#10243A")
TEAL = colors.HexColor("#0C7C82")
MIST = colors.HexColor("#EAF1F4")
AMBER = colors.HexColor("#B77512")
MUTED = colors.HexColor("#586978")

styles = getSampleStyleSheet()
styles.add(ParagraphStyle(name="CoverTitle", parent=styles["Title"], fontName="Helvetica-Bold", fontSize=27, leading=31, textColor=colors.white, alignment=TA_LEFT, spaceAfter=12))
styles.add(ParagraphStyle(name="CoverDeck", parent=styles["BodyText"], fontName="Helvetica", fontSize=12, leading=17, textColor=colors.HexColor("#DBE7EF")))
styles.add(ParagraphStyle(name="H1DC", parent=styles["Heading1"], fontName="Helvetica-Bold", fontSize=19, leading=23, textColor=NAVY, spaceBefore=14, spaceAfter=8, keepWithNext=True))
styles.add(ParagraphStyle(name="H2DC", parent=styles["Heading2"], fontName="Helvetica-Bold", fontSize=12.5, leading=16, textColor=TEAL, spaceBefore=9, spaceAfter=5, keepWithNext=True))
styles.add(ParagraphStyle(name="BodyDC", parent=styles["BodyText"], fontName="Helvetica", fontSize=9.3, leading=13.4, textColor=INK, spaceAfter=6))
styles.add(ParagraphStyle(name="SmallDC", parent=styles["BodyText"], fontName="Helvetica", fontSize=7.7, leading=10, textColor=MUTED, spaceAfter=3))
styles.add(ParagraphStyle(name="TableHeadDC", parent=styles["BodyText"], fontName="Helvetica-Bold", fontSize=8, leading=10, textColor=colors.white))
styles.add(ParagraphStyle(name="TableDC", parent=styles["BodyText"], fontName="Helvetica", fontSize=7.5, leading=10.2, textColor=INK))
styles.add(ParagraphStyle(name="CalloutDC", parent=styles["BodyText"], fontName="Helvetica-Bold", fontSize=10, leading=14, textColor=NAVY, spaceAfter=0))
styles.add(ParagraphStyle(name="StepDC", parent=styles["BodyText"], fontName="Helvetica", fontSize=8.7, leading=12.2, textColor=INK, leftIndent=7, firstLineIndent=-7, spaceAfter=5))

def P(txt, style="BodyDC"):
    return Paragraph(txt, styles[style])

class FieldGuide(BaseDocTemplate):
    def __init__(self, filename, **kwargs):
        super().__init__(filename, pagesize=letter, leftMargin=.66*inch, rightMargin=.66*inch, topMargin=.66*inch, bottomMargin=.62*inch, **kwargs)
        frame = Frame(self.leftMargin, self.bottomMargin, self.width, self.height, id="normal")
        self.addPageTemplates(PageTemplate(id="guide", frames=frame, onPage=self.decorate))

    def decorate(self, canvas, doc):
        canvas.saveState()
        if doc.page == 1:
            canvas.setFillColor(NAVY)
            canvas.rect(0, 0, letter[0], letter[1], fill=1, stroke=0)
            canvas.setFillColor(TEAL)
            canvas.rect(.66*inch, 9.72*inch, .56*inch, .08*inch, fill=1, stroke=0)
            canvas.setFillColor(colors.white)
            canvas.setFont("Helvetica-Bold", 9)
            canvas.drawString(.66*inch, 9.94*inch, "DIESELCAIRN  /  FIELD RESEARCH")
            canvas.setStrokeColor(colors.HexColor("#486175"))
            canvas.line(.66*inch, .5*inch, letter[0]-.66*inch, .5*inch)
            canvas.setFont("Helvetica", 8)
            canvas.setFillColor(colors.HexColor("#B8C9D5"))
            canvas.drawString(.66*inch, .32*inch, "COMMUNITY SOURCES  •  REV 1  •  18 NOV 2026")
        else:
            canvas.setFillColor(NAVY)
            canvas.rect(0, letter[1]-.42*inch, letter[0], .42*inch, fill=1, stroke=0)
            canvas.setFillColor(colors.white)
            canvas.setFont("Helvetica-Bold", 8)
            canvas.drawString(.66*inch, letter[1]-.27*inch, "DIESELCAIRN  /  PB305 SERVICE RESEARCH")
            canvas.setStrokeColor(colors.HexColor("#CFD9DF"))
            canvas.line(.66*inch, .45*inch, letter[0]-.66*inch, .45*inch)
            canvas.setFillColor(MUTED)
            canvas.setFont("Helvetica", 8)
            canvas.drawString(.66*inch, .27*inch, "Independent reports are leads, not calibration approval.")
            canvas.drawRightString(letter[0]-.66*inch, .27*inch, str(doc.page))
        canvas.restoreState()

story=[]
story += [Spacer(1, 1.35*inch), P("COMMUNITY &<br/>INDEPENDENT FIELD RESEARCH", "CoverTitle"), P("Allison gear-range changes, school-bus conversion practice, and what the evidence means for a 2009 International RE300 / PB305.", "CoverDeck"), Spacer(1, .38*inch)]
coverbox=Table([[P("FIELD TAKEAWAY", "TableHeadDC")],[P("Some school buses have received an Allison calibration that permits another forward range. That does not prove this PB305 has the required transmission hardware, is approved for the change, or will benefit from it. Identify the installed unit first.", "CalloutDC")]], colWidths=[6.98*inch])
coverbox.setStyle(TableStyle([("BACKGROUND",(0,0),(-1,0),TEAL),("BACKGROUND",(0,1),(-1,1),colors.white),("BOX",(0,0),(-1,-1),0,colors.white),("LEFTPADDING",(0,0),(-1,-1),12),("RIGHTPADDING",(0,0),(-1,-1),12),("TOPPADDING",(0,0),(-1,-1),10),("BOTTOMPADDING",(0,0),(-1,-1),10)]))
story += [coverbox, Spacer(1, .28*inch), P("A practical companion to the technical service research. Community accounts are preserved as owner or specialist reports, with their limits made explicit.", "CoverDeck"), PageBreak()]

story += [P("What conversion owners and independent specialists report", "H1DC"), P("Independent sources agree that some buses have restricted maximum gear ranges and that a specialist may be able to obtain or install another calibration. Their evidence varies from business guidance to single-owner outcomes. It cannot establish eligibility for this specific International bus.")]
rows=[[P("SOURCE", "TableHeadDC"),P("USEFUL FIELD DETAIL", "TableHeadDC"),P("EVIDENCE LIMIT", "TableHeadDC")]]
items=[
 ("<link href='https://bgaschoolbuses.blogspot.com/2021/'>BGA School Buses (2021)</link>","Discusses MD3060 / Allison 2000 requests, OEM approval, authorized Allison service, and risk of gear hunting.","Independent business post; broad claims are not model/year-specific."),
 ("<link href='https://www.youtube.com/watch?v=pIW2BvTwToQ'>TSLABUS / Guy From Iowa (2022)</link>","Owner documents a 3000PTS project and TCM handling for a gear-range change.","Video description is not proof of exact calibration, eligibility, or repeatable road-test result."),
 ("<link href='https://forums.schoolbusfleet.com/topic.asp?TOPIC_ID=21029'>School Bus Fleet forum</link>","Operators report buses with both five- and six-range configurations and describe dealer/rebuilder support.","Forum thread from 2010; discovery lead only."),
 ("<link href='https://www.reddit.com/r/skoolies/comments/1qvyw2w/got_6th_unlocked/'>Skoolie owner case (2026)</link>","Owner reports Blue Bird approval, Allison-file request through a shop, a replacement TCM, and a post-change RPM observation.","One different bus/OEM; reported ~300 RPM reduction is not a PB305 prediction."),
 ("<link href='https://www.youtube.com/watch?v=V4Xh6ur246k'>Parish Skoolie (2021)</link>","Conversion overview of AT545, MT643, MD3060, Allison 2000 and swap considerations.","Educational conversion overview, not a programming procedure."),
 ("<link href='https://www.caconversions.com/allison-conversions'>CA Conversions</link>","Commercial conversion specialist lists school buses and Allison families in its service scope.","Does not establish service on this installed unit or an authorized calibration path."),
]
for a,b,c in items: rows.append([P(a,"TableDC"),P(b,"TableDC"),P(c,"TableDC")])
t=Table(rows,colWidths=[1.48*inch,2.78*inch,2.72*inch],repeatRows=1,hAlign="LEFT")
t.setStyle(TableStyle([("BACKGROUND",(0,0),(-1,0),NAVY),("ROWBACKGROUNDS",(0,1),(-1,-1),[colors.white,MIST]),("GRID",(0,0),(-1,-1),.35,colors.HexColor("#C9D4DB")),("VALIGN",(0,0),(-1,-1),"TOP"),("LEFTPADDING",(0,0),(-1,-1),7),("RIGHTPADDING",(0,0),(-1,-1),7),("TOPPADDING",(0,0),(-1,-1),7),("BOTTOMPADDING",(0,0),(-1,-1),7)]))
story += [t, Spacer(1,10), P("The strongest corroborating control is Allison's published gear-range policy: <link href='https://static.nhtsa.gov/odi/tsbs/2020/MC-10185305-0001.pdf' color='#0C7C82'>SIL 19-TR-08</link> says a maximum-range increase requires OEM approval documentation before Allison releases a new calibration. Community success stories do not waive that requirement.")]

story += [P("The PB305-specific unknown", "H1DC"), P("The owner reports an Allison 3000 Series 3000PTS; verify the model against the transmission nameplate. The push-button selector and LED display show electronic controls but do not identify the TCM generation, calibration/CIN, internal gear hardware, or whether sixth range is available and appropriate. A dashboard showing a maximum of five is a clue to record, not proof of the hardware or calibration story."), P("Collect before requesting a gear-range change", "H2DC")]
for txt in [
"1. Transmission data plate: family/model, assembly number, serial number, configuration codes.",
"2. TCM label and authorized read-only identity report: part/assembly and serial numbers, control generation, CIN/calibration, current maximum range, DTCs.",
"3. Vehicle configuration: VIN, engine ESN/rating, axle ratio, tire size and speed rating, governed speed, brake/ABS configuration, and build options.",
"4. Written International/IC Bus engineering disposition and Allison service-channel feasibility, including any hardware requirements and safety/warranty implications."]:
    story.append(P(txt,"StepDC"))

story += [PageBreak(), P("A disciplined service-request path", "H1DC"), P("Use this as an intake and referral workflow. It is intentionally not a DIY reflash procedure.")]
for txt in [
"1. Preserve the as-found condition. Photograph tags; save an authorized diagnostic identity/DTC report; record what range the selector displays.",
"2. Identify the actual transmission and control generation. Do not infer them from the selector, model year, another bus, or an online parts listing.",
"3. State the request precisely: gear-range increase, shift schedule change, enable an approved feature, or repair a fault. These are different jobs.",
"4. Ask International/IC Bus for a VIN/configuration-specific written engineering disposition.",
"5. Ask an Allison distributor/dealer to confirm eligibility, required identifiers, and whether the job is in-vehicle or requires a module exchange.",
"6. Get a work order naming the target calibration/CIN, as-found backup, recovery plan, charges, and warranty limits.",
"7. After service, read back calibration/range, inspect DTCs, and follow the shop's controlled road-test and verification plan. Retain before/after reports."]:
    story.append(P(txt,"StepDC"))

story += [P("Implications for DieselCairn", "H1DC"), P("The app should distinguish installed transmission family, physical gear capability, configured maximum range, current gear, and shift schedule. Treating them as one 'sixth locked' flag would hide important uncertainty."), P("A useful first release can gather labels, preserve diagnostic reports, build a calibration-request packet, validate completeness, and track the OEM/service response. A simulator can exercise five-/six-range states, missing-approval rejection, hardware mismatch, and verified read-back while clearly labelling every generated result as simulated."), P("Do not use a reported 300-RPM change at 65 mph to predict fuel savings. Tire rolling radius, ratios, load, speed, road, and measured baseline differ.")]

story += [P("Source quality and references", "H1DC"), P("Evidence order for decisions: vehicle-specific records and actual module readout; published manufacturer policy/procedure; named independent specialist evidence; first-person conversion cases; forum anecdotes. Resolve conflicts upward in that order. Community material here informs questions to ask, not a calibration image or live-write recipe.")]
refs=[
 ("Allison SIL 19-TR-08 Rev. D (policy copy hosted by NHTSA)","https://static.nhtsa.gov/odi/tsbs/2020/MC-10185305-0001.pdf"),
 ("BGA School Buses: Unlocking 6th Gear on an Allison Transmission (2021)","https://bgaschoolbuses.blogspot.com/2021/"),
 ("TSLABUS / Guy From Iowa: 3000PTS project video (2022)","https://www.youtube.com/watch?v=pIW2BvTwToQ"),
 ("School Bus Fleet forum: Do any school buses have the 6th gear unlocked?","https://forums.schoolbusfleet.com/topic.asp?TOPIC_ID=21029"),
 ("r/skoolies owner-reported Blue Bird case (2026)","https://www.reddit.com/r/skoolies/comments/1qvyw2w/got_6th_unlocked/"),
 ("Parish Skoolie: School bus Allison families and swaps (2021)","https://www.youtube.com/watch?v=V4Xh6ur246k"),
 ("CA Conversions: Allison conversion services","https://www.caconversions.com/allison-conversions"),
 ("CA Conversions: Allison swap overview","https://www.caconversions.com/blog/allison-5-or-6-speed-transmission-swap"),
]
for name,url in refs: story.append(P(f"• <link href='{url}' color='#0C7C82'>{name}</link>","SmallDC"))
story += [Spacer(1,8), HRFlowable(width="100%", thickness=.8, color=TEAL), Spacer(1,5), P("Prepared for DieselCairn research. This field guide is not a service procedure, engineering approval, or authorization to alter a vehicle calibration. Revision 1 • 18 November 2026.","SmallDC")]

doc=FieldGuide(str(OUT), title="DieselCairn Independent School Bus Field Research", author="DieselCairn")
doc.build(story)
print(OUT)
