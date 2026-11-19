import Foundation

/// J1587 message carried over the J1708 physical/data-link layer.
/// Bytes include MID, PID/data bytes and the J1587 checksum; maximum 21 bytes.
public struct J1587Message: Codable, Equatable, Sendable {
    public let bytes: [UInt8]
    public let timestamp: Date

    public init(bytes: [UInt8], timestamp: Date = .now) throws {
        guard (2...21).contains(bytes.count), Self.hasValidChecksum(bytes) else {
            throw J1587Error.invalidFrame
        }
        self.bytes = bytes
        self.timestamp = timestamp
    }

    public var mid: UInt8 { bytes[0] }
    public var dataBytes: [UInt8] { Array(bytes.dropFirst().dropLast()) }

    public static func make(mid: UInt8, data: [UInt8], timestamp: Date = .now) throws -> J1587Message {
        guard data.count <= 19 else { throw J1587Error.tooLong }
        let body = [mid] + data
        let checksum = UInt8(truncatingIfNeeded: 0xFF - body.reduce(0) { $0 + Int($1) })
        return try J1587Message(bytes: body + [checksum], timestamp: timestamp)
    }

    public static func hasValidChecksum(_ bytes: [UInt8]) -> Bool {
        (2...21).contains(bytes.count) && UInt8(truncatingIfNeeded: bytes.reduce(0) { $0 + Int($1) }) == 0xFF
    }
}

public enum J1587Error: Error, LocalizedError, Equatable {
    case invalidFrame
    case tooLong
    case busBusy
    case collision

    public var errorDescription: String? {
        switch self {
        case .invalidFrame: "J1587 message length or checksum is invalid."
        case .tooLong: "A J1587 message cannot exceed 21 bytes including MID and checksum."
        case .busBusy: "J1708 transmit requires the specified idle interval and priority delay."
        case .collision: "J1708 collision detected; back off and retry according to priority."
        }
    }
}

/// Deterministic J1708 access timing helpers for simulator/firmware conformance.
/// This does not replace bit-level collision detection in adapter firmware.
public enum J1708Timing {
    public static let baudRate = 9_600
    public static let bitTimeMicroseconds = 1_000_000.0 / Double(baudRate)
    public static let requiredIdleBits = 10

    /// J1708 priority classes are 1...8. P_D = P * 2 * tB.
    public static func priorityDelayMicroseconds(class priority: UInt8) throws -> UInt32 {
        guard (1...8).contains(priority) else { throw J1587Error.invalidFrame }
        return UInt32((Double(priority) * 2 * bitTimeMicroseconds).rounded())
    }

    public static func mayTransmit(idleHighBits: Int, elapsedAfterIdleMicroseconds: UInt32, priority: UInt8) -> Bool {
        guard let delay = try? priorityDelayMicroseconds(class: priority) else { return false }
        return idleHighBits >= requiredIdleBits && elapsedAfterIdleMicroseconds >= delay
    }
}
