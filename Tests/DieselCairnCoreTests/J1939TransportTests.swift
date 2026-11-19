import XCTest
@testable import iScanCore
import iScanModels

final class J1939TransportTests: XCTestCase {
    func testReassemblesBAMAndTrimsFinalPacketPadding() {
        var reassembler = J1939BAMReassembler()
        let source: UInt8 = 0x80
        let payload = Array(UInt8(1)...UInt8(9))
        let control = frame(pgn: 0x00ECFF, source: source, bytes: [0x20, 9, 0, 2, 0xFF, 0xCA, 0xFE, 0])

        XCTAssertEqual(reassembler.consume(control), .started(sourceAddress: source, pgn: 0x00FECA, byteCount: 9, packetCount: 2))
        XCTAssertEqual(reassembler.consume(frame(pgn: 0x00EBFF, source: source, bytes: [1] + Array(payload[0..<7]))),
                       .progress(sourceAddress: source, pgn: 0x00FECA, receivedPackets: 1, packetCount: 2))
        XCTAssertEqual(reassembler.consume(frame(pgn: 0x00EBFF, source: source, bytes: [2, payload[7], payload[8], 0xFF, 0xFF, 0xFF, 0xFF, 0xFF])),
                       .completed(sourceAddress: source, pgn: 0x00FECA, payload: payload))
    }

    func testRejectsSequenceMismatchAndDropsTransfer() {
        var reassembler = J1939BAMReassembler()
        _ = reassembler.consume(frame(pgn: 0x00ECFF, source: 0x80, bytes: [0x20, 9, 0, 2, 0xFF, 0xCA, 0xFE, 0]))
        guard case .rejected(let message) = reassembler.consume(frame(pgn: 0x00EBFF, source: 0x80, bytes: [2, 1, 2, 3, 4, 5, 6, 7])) else {
            return XCTFail("Expected sequence error")
        }
        XCTAssertTrue(message.contains("expected 1"))
        XCTAssertEqual(reassembler.consume(frame(pgn: 0x00EBFF, source: 0x80, bytes: [1, 1, 2, 3, 4, 5, 6, 7])), .ignored)
    }

    func testRejectsInconsistentPacketCountAndNonGlobalBAM() {
        var reassembler = J1939BAMReassembler()
        guard case .rejected = reassembler.consume(frame(pgn: 0x00ECFF, source: 0x80, bytes: [0x20, 9, 0, 1, 0xFF, 0xCA, 0xFE, 0])) else {
            return XCTFail("Expected packet-count rejection")
        }
        guard case .rejected = reassembler.consume(frame(pgn: 0x00EC00, source: 0x80, bytes: [0x20, 9, 0, 2, 0xFF, 0xCA, 0xFE, 0])) else {
            return XCTFail("Expected non-global BAM rejection")
        }
    }

    private func frame(pgn: UInt32, source: UInt8, bytes: [UInt8]) -> J1939Frame {
        // PDU1 transport PGNs carry destination in PS; BAM uses global address FF.
        let identifier = (UInt32(3) << 26) | (pgn << 8) | UInt32(source)
        return J1939Frame(identifier: identifier, payload: bytes)
    }
}
