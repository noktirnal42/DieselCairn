import Foundation
import iScanModels

public struct J1939TransportMessage: Equatable, Sendable {
    public let sourceAddress: UInt8
    public let pgn: UInt32
    public let payload: [UInt8]
    public let timestamp: Date
    public let source: ReadingSource

    public init(sourceAddress: UInt8, pgn: UInt32, payload: [UInt8], timestamp: Date, source: ReadingSource) {
        self.sourceAddress = sourceAddress
        self.pgn = pgn
        self.payload = payload
        self.timestamp = timestamp
        self.source = source
    }
}

/// Reassembles J1939-21 broadcast-announcement (BAM) transfers from classic-CAN frames.
/// Connection-managed RTS/CTS sessions are intentionally not accepted here.
public struct J1939BAMReassembler: Sendable {
    public enum Event: Equatable, Sendable {
        case ignored
        case started(sourceAddress: UInt8, pgn: UInt32, byteCount: Int, packetCount: Int)
        case progress(sourceAddress: UInt8, pgn: UInt32, receivedPackets: Int, packetCount: Int)
        case completed(sourceAddress: UInt8, pgn: UInt32, payload: [UInt8])
        case rejected(String)
    }

    private struct Transfer: Sendable {
        let pgn: UInt32
        let byteCount: Int
        let packetCount: Int
        var nextSequence: UInt8 = 1
        var payload: [UInt8] = []
    }

    private var transfers: [UInt8: Transfer] = [:]
    public let maximumPayloadBytes: Int

    public init(maximumPayloadBytes: Int = 1_785) {
        self.maximumPayloadBytes = min(1_785, max(9, maximumPayloadBytes))
    }

    public mutating func reset() { transfers.removeAll(keepingCapacity: true) }

    public mutating func consume(_ frame: J1939Frame) -> Event {
        guard frame.identifier <= 0x1FFF_FFFF else { return .rejected("Invalid 29-bit identifier.") }
        guard frame.payload.count == 8 else { return .rejected("Transport control and data frames must contain 8 bytes.") }
        switch frame.pgn {
        case 0x00EC00: return consumeControl(frame)
        case 0x00EB00: return consumeData(frame)
        default: return .ignored
        }
    }

    private mutating func consumeControl(_ frame: J1939Frame) -> Event {
        let b = frame.payload
        switch b[0] {
        case 0x20: // BAM
            let byteCount = Int(b[1]) | (Int(b[2]) << 8)
            let packetCount = Int(b[3])
            let pgn = UInt32(b[5]) | (UInt32(b[6]) << 8) | (UInt32(b[7]) << 16)
            guard UInt8((frame.identifier >> 8) & 0xFF) == 0xFF else { return .rejected("BAM must use the global destination address.") }
            guard b[4] == 0xFF else { return .rejected("BAM reserved byte must be 0xFF.") }
            guard (9...maximumPayloadBytes).contains(byteCount) else { return .rejected("BAM byte count is outside the supported range.") }
            guard packetCount == (byteCount + 6) / 7 else { return .rejected("BAM packet count does not match its byte count.") }
            guard pgn <= 0x3_FFFF, pgn != 0x00EC00, pgn != 0x00EB00 else { return .rejected("BAM target PGN is invalid.") }
            transfers[frame.sourceAddress] = Transfer(pgn: pgn, byteCount: byteCount, packetCount: packetCount)
            return .started(sourceAddress: frame.sourceAddress, pgn: pgn, byteCount: byteCount, packetCount: packetCount)
        case 0xFF: // Abort; source address identifies the sender
            transfers.removeValue(forKey: frame.sourceAddress)
            return .ignored
        default:
            // RTS/CTS and other connection-managed controls require a distinct state machine.
            return .ignored
        }
    }

    private mutating func consumeData(_ frame: J1939Frame) -> Event {
        let source = frame.sourceAddress
        guard UInt8((frame.identifier >> 8) & 0xFF) == 0xFF else { return .ignored }
        guard var transfer = transfers[source] else { return .ignored }
        let sequence = frame.payload[0]
        guard sequence == transfer.nextSequence else {
            transfers.removeValue(forKey: source)
            return .rejected("BAM sequence mismatch: expected \(transfer.nextSequence), received \(sequence).")
        }
        transfer.payload.append(contentsOf: frame.payload.dropFirst())
        transfer.nextSequence &+= 1
        if Int(sequence) == transfer.packetCount {
            transfers.removeValue(forKey: source)
            guard transfer.payload.count >= transfer.byteCount else { return .rejected("BAM ended before its announced byte count.") }
            return .completed(sourceAddress: source, pgn: transfer.pgn, payload: Array(transfer.payload.prefix(transfer.byteCount)))
        }
        transfers[source] = transfer
        return .progress(sourceAddress: source, pgn: transfer.pgn, receivedPackets: Int(sequence), packetCount: transfer.packetCount)
    }
}
