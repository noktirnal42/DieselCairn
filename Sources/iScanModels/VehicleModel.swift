import Foundation

/// Public J1939 parameter groups represented by this app's first, RE300-specific profile.
public enum RE300PGN: UInt32, CaseIterable, Identifiable, Sendable {
    case electronicEngineController1 = 0xF004
    case electronicEngineController2 = 0xF003
    case engineTemperature1 = 0xFEEE
    case fuelEconomy = 0xFEF2
    case intakeManifold1 = 0xFEF6
    case ambientConditions = 0xFEF5

    public var id: UInt32 { rawValue }
    public var title: String {
        switch self {
        case .electronicEngineController1: "EEC1"
        case .electronicEngineController2: "EEC2"
        case .engineTemperature1: "ET1"
        case .fuelEconomy: "Fuel economy"
        case .intakeManifold1: "IM1"
        case .ambientConditions: "Ambient conditions"
        }
    }
}

public enum RE300Parameter: String, CaseIterable, Identifiable, Sendable {
    case engineSpeed = "Engine speed"
    case engineLoad = "Engine load"
    case coolantTemperature = "Coolant temperature"
    case engineOilTemperature = "Engine oil temperature"
    case fuelRate = "Fuel rate"
    case intakeManifoldPressure = "Intake manifold pressure"
    case intakeAirTemperature = "Intake air temperature"

    public var id: String { rawValue }
    public var unit: String {
        switch self {
        case .engineSpeed: "rpm"
        case .engineLoad: "%"
        case .coolantTemperature, .engineOilTemperature, .intakeAirTemperature: "°C"
        case .fuelRate: "L/h"
        case .intakeManifoldPressure: "kPa"
        }
    }
    public var pgn: RE300PGN {
        switch self {
        case .engineSpeed: .electronicEngineController1
        case .engineLoad: .electronicEngineController2
        case .coolantTemperature, .engineOilTemperature: .engineTemperature1
        case .fuelRate: .fuelEconomy
        case .intakeManifoldPressure: .intakeManifold1
        case .intakeAirTemperature: .ambientConditions
        }
    }
}

/// A classic-CAN J1939 frame. Payloads must contain at most eight bytes.
public struct J1939Frame: Codable, Equatable, Sendable {
    public let identifier: UInt32
    public let payload: [UInt8]
    public let timestamp: Date

    public init(identifier: UInt32, payload: [UInt8], timestamp: Date = .now) {
        self.identifier = identifier & 0x1FFF_FFFF
        self.payload = Array(payload.prefix(8))
        self.timestamp = timestamp
    }

    public var priority: UInt8 { UInt8((identifier >> 26) & 0x7) }
    public var sourceAddress: UInt8 { UInt8(identifier & 0xFF) }
    public var pgn: UInt32 {
        let raw = (identifier >> 8) & 0x3_FFFF
        let pduFormat = (raw >> 8) & 0xFF
        return pduFormat < 240 ? raw & 0x3_FF00 : raw
    }

    public static func makeIdentifier(pgn: UInt32, sourceAddress: UInt8 = 0x00, priority: UInt8 = 3) -> UInt32 {
        let normalizedPGN = pgn & 0x3_FFFF
        return (UInt32(priority & 0x7) << 26) | (normalizedPGN << 8) | UInt32(sourceAddress)
    }
}

public struct ParameterReading: Identifiable, Equatable, Sendable {
    public let parameter: RE300Parameter
    public let value: Double
    public let timestamp: Date
    public let source: ReadingSource
    public var id: String { parameter.id }

    public init(parameter: RE300Parameter, value: Double, timestamp: Date = .now, source: ReadingSource) {
        self.parameter = parameter
        self.value = value
        self.timestamp = timestamp
        self.source = source
    }
}

public enum ReadingSource: String, Sendable {
    case simulator = "SIMULATOR"
    case vehicle = "VEHICLE"
    case replay = "REPLAY"
}

public struct DiagnosticFault: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let code: String
    public let module: String
    public let description: String
    public let isActive: Bool

    public init(id: UUID = UUID(), code: String, module: String, description: String, isActive: Bool = true) {
        self.id = id
        self.code = code
        self.module = module
        self.description = description
        self.isActive = isActive
    }
}
