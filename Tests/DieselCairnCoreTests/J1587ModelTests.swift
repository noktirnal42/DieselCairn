import XCTest
import iScanModels

final class J1587ModelTests: XCTestCase {
    func testChecksumConstructionAndValidation() throws {
        let message = try J1587Message.make(mid: 128, data: [0x10, 0x2A])
        XCTAssertEqual(message.mid, 128)
        XCTAssertEqual(message.dataBytes, [0x10, 0x2A])
        XCTAssertEqual(message.bytes.reduce(0) { $0 + Int($1) } & 0xFF, 0xFF)
        XCTAssertTrue(J1587Message.hasValidChecksum(message.bytes))
    }

    func testRejectsInvalidChecksumAndOversizeMessage() throws {
        XCTAssertThrowsError(try J1587Message(bytes: [0x80, 0x01]))
        XCTAssertThrowsError(try J1587Message.make(mid: 0x80, data: [UInt8](repeating: 0, count: 20)))
    }

    func testJ1708IdleAndPriorityDelay() throws {
        let delay = try J1708Timing.priorityDelayMicroseconds(class: 3)
        XCTAssertEqual(delay, 625)
        XCTAssertFalse(J1708Timing.mayTransmit(idleHighBits: 9, elapsedAfterIdleMicroseconds: delay, priority: 3))
        XCTAssertFalse(J1708Timing.mayTransmit(idleHighBits: 10, elapsedAfterIdleMicroseconds: delay - 1, priority: 3))
        XCTAssertTrue(J1708Timing.mayTransmit(idleHighBits: 10, elapsedAfterIdleMicroseconds: delay, priority: 3))
    }
}
