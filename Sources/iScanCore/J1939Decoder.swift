import Foundation
import iScanModels

public enum J1939DecodeError: Error, LocalizedError {
    case shortPayload
    case unsupportedParameter
    case invalidIdentifier

    public var errorDescription: String? {
        switch self {
        case .shortPayload: "The J1939 frame does not contain all bytes required for this parameter."
        case .unsupportedParameter: "This parameter is not included in the current RE300 mapping profile."
        case .invalidIdentifier: "The CAN identifier is not a valid 29-bit J1939 identifier."
        }
    }
}

/// Decodes only standard mappings that have been verified against the J1939 data dictionary.
/// Vehicle-specific availability and calibration behavior still require confirmation on this bus.
public enum J1939Decoder {
    public static func value(for parameter: RE300Parameter, in frame: J1939Frame) throws -> Double {
        guard frame.identifier <= 0x1FFF_FFFF else { throw J1939DecodeError.invalidIdentifier }
        guard frame.pgn == parameter.pgn.rawValue else { throw J1939DecodeError.unsupportedParameter }
        let b = frame.payload
        func require(_ count: Int) throws {
            guard b.count >= count else { throw J1939DecodeError.shortPayload }
        }
        func word(_ offset: Int) -> UInt16 { UInt16(b[offset]) | (UInt16(b[offset + 1]) << 8) }

        switch parameter {
        case .engineSpeed:
            try require(5)
            return Double(word(3)) * 0.125
        case .engineLoad:
            try require(3)
            return Double(b[2]) - 125
        case .coolantTemperature:
            try require(1)
            return Double(b[0]) - 40
        case .engineOilTemperature:
            try require(5)
            return Double(word(3)) * 0.03125 - 273
        case .fuelRate:
            try require(2)
            return Double(word(0)) * 0.05
        case .intakeManifoldPressure:
            try require(2)
            return Double(word(0)) * 0.1
        case .intakeAirTemperature:
            try require(5)
            // SPN 171 in Ambient Conditions (PGN 65269) occupies data bytes 4–5.
            return Double(word(3)) * 0.03125 - 273
        }
    }

    public static func reading(for parameter: RE300Parameter, in frame: J1939Frame, source: ReadingSource) throws -> ParameterReading {
        ParameterReading(parameter: parameter, value: try value(for: parameter, in: frame), timestamp: frame.timestamp, source: source)
    }
}
