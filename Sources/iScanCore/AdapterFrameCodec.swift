import Foundation

public enum AdapterMessageType: UInt8, Sendable {
    case hello = 0x01
    case capabilities = 0x02
    case setMode = 0x03
    case canReceive = 0x10
    case canTransmit = 0x11
    case transmitResult = 0x12
    case busStatus = 0x20
    case j1587Receive = 0x30
    case j1587Transmit = 0x31
    case j1708Status = 0x32
    case error = 0x7F
}

public struct AdapterMessage: Equatable, Sendable {
    public let type: AdapterMessageType
    public let sequence: UInt16
    public let payload: [UInt8]
    public init(type: AdapterMessageType, sequence: UInt16, payload: [UInt8] = []) {
        self.type = type
        self.sequence = sequence
        self.payload = payload
    }
}

public enum AdapterCodecError: Error, LocalizedError {
    case invalidCOBS
    case invalidLength
    case unsupportedVersion
    case unknownType
    case checksumMismatch

    public var errorDescription: String? {
        switch self {
        case .invalidCOBS: "Adapter frame has invalid COBS encoding."
        case .invalidLength: "Adapter frame length does not match its header."
        case .unsupportedVersion: "Adapter protocol version is not supported."
        case .unknownType: "Adapter message type is not supported."
        case .checksumMismatch: "Adapter frame checksum did not match."
        }
    }
}

/// Protocol v1 stream codec shared by simulator fixtures and future serial/BLE transports.
/// Raw message: version, type, sequence BE16, payload length BE16, payload, CRC-16/CCITT-FALSE BE16.
/// COBS-encoded message is terminated by a zero delimiter.
public enum AdapterFrameCodec {
    public static let version: UInt8 = 1
    public static let maximumPayload = 48

    public static func encode(_ message: AdapterMessage) throws -> [UInt8] {
        guard message.payload.count <= maximumPayload else { throw AdapterCodecError.invalidLength }
        var raw: [UInt8] = [version, message.type.rawValue, UInt8(message.sequence >> 8), UInt8(message.sequence & 0xFF), UInt8(message.payload.count >> 8), UInt8(message.payload.count & 0xFF)]
        raw.append(contentsOf: message.payload)
        let crc = crc16(raw)
        raw.append(UInt8(crc >> 8))
        raw.append(UInt8(crc & 0xFF))
        return cobsEncode(raw) + [0]
    }

    public static func decode(_ encoded: [UInt8]) throws -> AdapterMessage {
        let raw = try cobsDecode(encoded)
        guard raw.count >= 8 else { throw AdapterCodecError.invalidLength }
        guard raw[0] == version else { throw AdapterCodecError.unsupportedVersion }
        let length = Int(raw[4]) << 8 | Int(raw[5])
        guard length <= maximumPayload, raw.count == 8 + length else { throw AdapterCodecError.invalidLength }
        let received = UInt16(raw[raw.count - 2]) << 8 | UInt16(raw[raw.count - 1])
        guard crc16(Array(raw.dropLast(2))) == received else { throw AdapterCodecError.checksumMismatch }
        guard let type = AdapterMessageType(rawValue: raw[1]) else { throw AdapterCodecError.unknownType }
        let sequence = UInt16(raw[2]) << 8 | UInt16(raw[3])
        return AdapterMessage(type: type, sequence: sequence, payload: Array(raw[6..<(6 + length)]))
    }

    public static func decodeStream(_ buffer: inout [UInt8]) -> [Result<AdapterMessage, AdapterCodecError>] {
        var output: [Result<AdapterMessage, AdapterCodecError>] = []
        while let delimiter = buffer.firstIndex(of: 0) {
            let frame = Array(buffer[..<delimiter])
            buffer.removeFirst(delimiter + 1)
            if !frame.isEmpty {
                do { output.append(.success(try decode(frame))) }
                catch let error as AdapterCodecError { output.append(.failure(error)) }
                catch { output.append(.failure(.invalidLength)) }
            }
        }
        if buffer.count > 128 { buffer.removeAll(keepingCapacity: true) }
        return output
    }

    public static func crc16(_ bytes: [UInt8]) -> UInt16 {
        var crc: UInt16 = 0xFFFF
        for byte in bytes {
            crc ^= UInt16(byte) << 8
            for _ in 0..<8 { crc = (crc & 0x8000) != 0 ? (crc << 1) ^ 0x1021 : crc << 1 }
        }
        return crc
    }

    private static func cobsEncode(_ input: [UInt8]) -> [UInt8] {
        var output = [UInt8]()
        output.reserveCapacity(input.count + 2)
        var codeIndex = 0
        var code: UInt8 = 1
        output.append(0)
        for byte in input {
            if byte == 0 {
                output[codeIndex] = code
                codeIndex = output.count
                output.append(0)
                code = 1
            } else {
                output.append(byte)
                code &+= 1
                if code == 0xFF {
                    output[codeIndex] = code
                    codeIndex = output.count
                    output.append(0)
                    code = 1
                }
            }
        }
        output[codeIndex] = code
        return output
    }

    private static func cobsDecode(_ input: [UInt8]) throws -> [UInt8] {
        guard !input.isEmpty, !input.contains(0) else { throw AdapterCodecError.invalidCOBS }
        var output = [UInt8]()
        var index = 0
        while index < input.count {
            let code = Int(input[index])
            guard code > 0, index + code <= input.count + 1 else { throw AdapterCodecError.invalidCOBS }
            index += 1
            let end = index + code - 1
            guard end <= input.count else { throw AdapterCodecError.invalidCOBS }
            output.append(contentsOf: input[index..<end])
            index = end
            if code != 0xFF && index < input.count { output.append(0) }
        }
        return output
    }
}
