import Foundation

public struct VehicleProfile: Codable, Equatable, Sendable {
    public var vin: String = ""
    public var year: String = "2009"
    public var make: String = "International"
    public var model: String = "RE300"
    /// Owner/factory-confirmed model code; deliberately distinct from an unverified VIN result.
    public var vinDecodedModel: String = "PB305"
    /// Raw model code reported by NHTSA. Kept separate from owner/factory-confirmed identity.
    public var vinReportedModel: String = ""
    public var vinDecodedSeries: String = ""
    public var vinTransmissionStyle: String = ""
    public var engine: String = "MaxxForce DT"
    public var engineSerial: String = ""
    public var engineECMSerial: String = ""
    public var engineCalibrationID: String = ""
    /// Owner-reported transmission identification; verify the nameplate before target-specific work.
    public var transmissionSeries: String = "Allison 3000 Series"
    public var transmissionModel: String = "3000PTS"
    public var transmissionSerial: String = ""
    public var tcmSerial: String = ""
    public var transmissionCalibrationID: String = ""
    public var notes: String = ""
    public var vinDecodeSource: String = "Owner-confirmed PB305; VIN not yet decoded"

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case vin, year, make, model, vinDecodedModel, vinReportedModel, vinDecodedSeries, vinTransmissionStyle, engine
        case engineSerial, engineECMSerial, engineCalibrationID
        case transmissionSeries, transmissionModel, transmissionSerial, tcmSerial, transmissionCalibrationID
        case notes, vinDecodeSource
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        vin = try values.decodeIfPresent(String.self, forKey: .vin) ?? ""
        year = try values.decodeIfPresent(String.self, forKey: .year) ?? "2009"
        make = try values.decodeIfPresent(String.self, forKey: .make) ?? "International"
        model = try values.decodeIfPresent(String.self, forKey: .model) ?? "RE300"
        vinDecodedModel = try values.decodeIfPresent(String.self, forKey: .vinDecodedModel) ?? "PB305"
        vinReportedModel = try values.decodeIfPresent(String.self, forKey: .vinReportedModel) ?? ""
        vinDecodedSeries = try values.decodeIfPresent(String.self, forKey: .vinDecodedSeries) ?? ""
        vinTransmissionStyle = try values.decodeIfPresent(String.self, forKey: .vinTransmissionStyle) ?? ""
        engine = try values.decodeIfPresent(String.self, forKey: .engine) ?? "MaxxForce DT"
        engineSerial = try values.decodeIfPresent(String.self, forKey: .engineSerial) ?? ""
        engineECMSerial = try values.decodeIfPresent(String.self, forKey: .engineECMSerial) ?? ""
        engineCalibrationID = try values.decodeIfPresent(String.self, forKey: .engineCalibrationID) ?? ""
        transmissionSeries = try values.decodeIfPresent(String.self, forKey: .transmissionSeries) ?? "Allison 3000 Series"
        transmissionModel = try values.decodeIfPresent(String.self, forKey: .transmissionModel) ?? "3000PTS"
        transmissionSerial = try values.decodeIfPresent(String.self, forKey: .transmissionSerial) ?? ""
        tcmSerial = try values.decodeIfPresent(String.self, forKey: .tcmSerial) ?? ""
        transmissionCalibrationID = try values.decodeIfPresent(String.self, forKey: .transmissionCalibrationID) ?? ""
        notes = try values.decodeIfPresent(String.self, forKey: .notes) ?? ""
        vinDecodeSource = try values.decodeIfPresent(String.self, forKey: .vinDecodeSource) ?? "Owner-confirmed PB305; VIN not yet decoded"
    }

    /// Repairs profiles saved by older builds that put the VIN model code in the series field.
    public mutating func normalizeLegacyIdentity() {
        guard vinDecodedModel.caseInsensitiveCompare("PB305") == .orderedSame,
              model.caseInsensitiveCompare("PC305") == .orderedSame else { return }
        if vinReportedModel.isEmpty { vinReportedModel = model }
        model = "RE300"
    }

    public var displayTitle: String {
        if vinDecodedModel.caseInsensitiveCompare("PB305") == .orderedSame {
            return "\(year) International RE300"
        }
        return "\(year) \(make) \(model)"
    }
}
