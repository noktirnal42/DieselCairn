import Foundation
import SwiftUI
import UniformTypeIdentifiers
import CryptoKit
import iScanModels

public struct FlashProjectManifest: Codable {
    public let format: String
    public let formatVersion: Int
    public let projectID: UUID
    public let createdAt: Date
    public let vehicle: VehicleProfile
    public let module: String
    public let sourceFileName: String
    public let payloadByteCount: Int
    public let sha256: String
    public let payloadBase64: String
    public let executionProfile: String
    public let status: String
    public let notes: String
}

public struct FlashPackageDocument: FileDocument {
    public static var readableContentTypes: [UTType] { [.json] }
    public var data: Data

    public init(data: Data = Data()) { self.data = data }
    public init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    public func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

public struct CanTraceFixture: Codable {
    public let format: String
    public let version: Int
    public let source: String
    public let scenario: String
    public let frames: [J1939Frame]

    public init(scenario: String, frames: [J1939Frame]) {
        format = "DieselCairn CAN Trace"
        version = 1
        source = "SIMULATOR"
        self.scenario = scenario
        self.frames = frames
    }
}

public enum FlashPackageBuilder {
    public static func build(vehicle: VehicleProfile, module: String, filename: String, payload: Data, notes: String) throws -> Data {
        let manifest = FlashProjectManifest(
            format: "DieselCairn Flash Project", formatVersion: 1, projectID: UUID(), createdAt: .now,
            vehicle: vehicle, module: module, sourceFileName: filename, payloadByteCount: payload.count,
            sha256: SHA256.hash(data: payload).map { String(format: "%02x", $0) }.joined(),
            payloadBase64: payload.base64EncodedString(), executionProfile: "UNASSIGNED",
            status: "PROJECT_ONLY — requires verified RE300 module identity, authorized calibration compatibility, and a validated transport profile",
            notes: notes
        )
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(manifest)
    }
}
