import DieselCairnUI
import Foundation
import iScanModels
import XCTest

final class CanTraceFixtureTests: XCTestCase {
    func testTraceRoundTripPreservesSubsecondFrameOrder() throws {
        let start = Date(timeIntervalSince1970: 1_700_000_000.125)
        let frames = [
            J1939Frame(identifier: 0x18ECFF00, payload: [0x20, 0x0A, 0], timestamp: start),
            J1939Frame(identifier: 0x18EBFF00, payload: [1, 2, 3], timestamp: start.addingTimeInterval(0.050))
        ]
        let fixture = CanTraceFixture(scenario: "Transport frames", frames: frames)
        let decoded = try CanTraceFixture.decode(fixture.encoded())

        XCTAssertEqual(decoded.version, 1)
        XCTAssertEqual(decoded.source, "SIMULATOR")
        XCTAssertEqual(decoded.frames.map(\.identifier), frames.map(\.identifier))
        XCTAssertEqual(decoded.frames.map(\.payload), frames.map(\.payload))
        XCTAssertEqual(decoded.frames[1].timestamp.timeIntervalSince(decoded.frames[0].timestamp), 0.050, accuracy: 0.001)
    }

    func testReaderAcceptsLegacyISOAndNumericDates() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let frame = J1939Frame(identifier: 0x18F00504, payload: [0], timestamp: date)
        let fixture = CanTraceFixture(scenario: "Legacy trace", frames: [frame])
        let encoder = JSONEncoder()

        let numericTrace = try encoder.encode(fixture)
        XCTAssertEqual(try CanTraceFixture.decode(numericTrace).frames.first?.timestamp, date)

        encoder.dateEncodingStrategy = .iso8601
        let isoTrace = try encoder.encode(fixture)
        XCTAssertEqual(try CanTraceFixture.decode(isoTrace).frames.first?.timestamp, date)
    }
}
