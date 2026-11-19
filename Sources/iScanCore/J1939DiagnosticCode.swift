import Foundation
import iScanModels

public struct J1939DTC: Equatable, Sendable {
    public let spn: UInt32
    public let fmi: UInt8
    public let occurrenceCount: UInt8
    public let conversionMethod: Bool

    public var code: String { "SPN \(spn) · FMI \(fmi)" }
    public var plainLanguage: String {
        "\(J1939FaultCatalog.spnName(spn)): \(J1939FaultCatalog.fmiDescription(fmi))"
    }

    public init(spn: UInt32, fmi: UInt8, occurrenceCount: UInt8 = 1, conversionMethod: Bool = false) {
        self.spn = spn
        self.fmi = fmi
        self.occurrenceCount = occurrenceCount & 0x7F
        self.conversionMethod = conversionMethod
    }
}

public enum J1939FaultCatalog {
    private static let fmiDefinitions: [UInt8: String] = [
        0: "Data is valid but above the normal operating range; most severe level.",
        1: "Data is valid but below the normal operating range; most severe level.",
        2: "Data is erratic, intermittent, or incorrect.",
        3: "Voltage is above normal, or the circuit is shorted to a high source.",
        4: "Voltage is below normal, or the circuit is shorted to a low source.",
        5: "Current is below normal, or the circuit is open.",
        6: "Current is above normal, or the circuit is grounded.",
        7: "A mechanical system is not responding or is out of adjustment.",
        8: "Abnormal frequency, pulse width, or period.",
        9: "Abnormal update rate or missing data.",
        10: "Abnormal rate of change.",
        11: "Failure mode or root cause is not identified by this FMI.",
        12: "The intelligent device or component is defective.",
        13: "The item is out of calibration.",
        14: "Special instructions apply; consult the module-specific service procedure.",
        15: "Data is above normal range; least severe level.",
        16: "Data is above normal range; moderately severe level.",
        17: "Data is below normal range; least severe level.",
        18: "Data is below normal range; moderately severe level.",
        19: "Received network data contains an error.",
        20: "Data has drifted high.",
        21: "Data has drifted low.",
        31: "A condition exists; the module does not provide a more specific FMI."
    ]

    public static func spnName(_ spn: UInt32) -> String {
        switch spn {
        case 92: "Engine Percent Load"
        case 100: "Engine Oil Pressure"
        case 102: "Intake Manifold Pressure"
        case 110: "Engine Coolant Temperature"
        case 190: "Engine Speed"
        case 183: "Engine Fuel Rate"
        default: "SPN \(spn) (no local component definition)"
        }
    }

    public static func fmiDescription(_ fmi: UInt8) -> String {
        fmiDefinitions[fmi] ?? "FMI \(fmi) is reserved or undefined in the local generic catalog; check the OEM diagnostic manual."
    }

    /// Decodes the lamp bytes and zero or more four-byte DTC records in DM1 or DM2.
    public static func decodeDTCs(_ payload: [UInt8]) -> [J1939DTC]? {
        guard payload.count >= 2 else { return nil }
        var end = payload.count
        if payload.count == 8 {
            if payload[2...].allSatisfy({ $0 == 0xFF }) { return [] }
            if payload.suffix(2).allSatisfy({ $0 == 0xFF }) { end -= 2 }
        }
        guard (end - 2).isMultiple(of: 4) else { return nil }
        let records = stride(from: 2, to: end, by: 4)
        return records.compactMap { offset in
            let record = Array(payload[offset..<(offset + 4)])
            let spn = UInt32(record[0]) | (UInt32(record[1]) << 8) | (UInt32(record[2] & 0x07) << 16)
            let fmi = (record[2] >> 3) & 0x1F
            let occurrence = record[3] & 0x7F
            let conversionMethod = (record[3] & 0x80) != 0
            return J1939DTC(spn: spn, fmi: fmi, occurrenceCount: occurrence, conversionMethod: conversionMethod)
        }
    }

    public static func encodeDM1(_ dtc: J1939DTC?) -> [UInt8] {
        guard let dtc else { return [0, 0, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF] }
        let spn = dtc.spn & 0x7_FFFF
        let byte2 = UInt8(spn & 0xFF)
        let byte3 = UInt8((spn >> 8) & 0xFF)
        let byte4 = UInt8((spn >> 16) & 0x07) | ((dtc.fmi & 0x1F) << 3)
        let byte5 = (dtc.occurrenceCount & 0x7F) | (dtc.conversionMethod ? 0x80 : 0)
        return [0, 0, byte2, byte3, byte4, byte5, 0xFF, 0xFF]
    }
}
