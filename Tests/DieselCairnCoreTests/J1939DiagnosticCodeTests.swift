import XCTest
@testable import iScanCore

final class J1939DiagnosticCodeTests: XCTestCase {
    func testDM1DTCEncodingAndDecodingPreservesExtendedSPNFMIAndOccurrence() {
        let source = J1939DTC(spn: 0x23456, fmi: 16, occurrenceCount: 23, conversionMethod: true)
        let payload = J1939FaultCatalog.encodeDM1(source)
        let decoded = J1939FaultCatalog.decodeDTCs(payload)

        XCTAssertEqual(decoded, [source])
        XCTAssertTrue(source.plainLanguage.contains("SPN 144470"))
        XCTAssertTrue(J1939FaultCatalog.fmiDescription(16).contains("moderately severe"))
    }

    func testEmptyDM1HasNoDTCAndMalformedPayloadIsRejected() {
        XCTAssertEqual(J1939FaultCatalog.decodeDTCs(J1939FaultCatalog.encodeDM1(nil)), [])
        XCTAssertNil(J1939FaultCatalog.decodeDTCs([0, 0, 1]))
    }

    func testGenericCatalogLabelsKnownSPNAndDoesNotInventUnknownDefinition() {
        XCTAssertEqual(J1939FaultCatalog.spnName(110), "Engine Coolant Temperature")
        XCTAssertTrue(J1939FaultCatalog.spnName(500_000).contains("no local component definition"))
        XCTAssertTrue(J1939FaultCatalog.fmiDescription(30).contains("reserved or undefined"))
    }
}
