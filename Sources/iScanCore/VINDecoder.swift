import Foundation

public struct VINDecodeResult: Sendable {
    public let modelYear: String
    public let make: String
    public let model: String
    public let series: String
    public let engine: String
    public let transmissionStyle: String
    public let source: String
    public let errorCode: String
}

public enum VINDecodeError: Error, LocalizedError {
    case invalidLength
    case invalidCharacters
    case noData
    case serviceUnavailable
    case serviceTimedOut
    case invalidCheckDigit(String)

    public var errorDescription: String? {
        switch self {
        case .invalidLength: "Enter a 17-character VIN."
        case .invalidCharacters: "Use letters and digits from the vehicle label. VINs exclude I, O, and Q."
        case .noData: "NHTSA returned no usable vehicle details."
        case .serviceUnavailable: "VIN decoding is temporarily unavailable. You can still enter the profile manually."
        case .serviceTimedOut: "NHTSA took too long to respond. Try again or enter the vehicle details manually."
        case .invalidCheckDigit(let detail): "NHTSA flagged this VIN's check digit. Verify the auction listing or vehicle label before using decoded details. \(detail)"
        }
    }
}

/// Uses the public NHTSA vPIC decoder. Returned values are suggestions; ECM/TCM identifiers must be read from the modules.
public enum VINDecoder {
    private static let allowedCharacters = CharacterSet(charactersIn: "0123456789ABCDEFGHJKLMNPRSTUVWXYZabcdefghjklmnprstuvwxyz")

    private struct Envelope: Decodable { let Results: [Result] }
    private struct Result: Decodable {
        let ModelYear: String?
        let Make: String?
        let Model: String?
        let EngineModel: String?
        let TransmissionStyle: String?
        let Series: String?
        let ErrorCode: String?
        let ErrorText: String?
    }

    public static func unformattedVIN(_ rawVIN: String) -> String {
        String(rawVIN.filter { !$0.isWhitespace && $0 != "-" })
    }

    public static func validatedVIN(_ rawVIN: String) throws -> String {
        let vin = unformattedVIN(rawVIN)
        guard vin.count == 17 else { throw VINDecodeError.invalidLength }
        guard vin.unicodeScalars.allSatisfy(allowedCharacters.contains) else { throw VINDecodeError.invalidCharacters }
        return vin.uppercased()
    }

    public static func decode(_ rawVIN: String, modelYear: Int? = nil, session: URLSession = .shared) async throws -> VINDecodeResult {
        let vin = try validatedVIN(rawVIN)
        var components = URLComponents()
        components.scheme = "https"
        components.host = "vpic.nhtsa.dot.gov"
        components.path = "/api/vehicles/DecodeVinValuesExtended/\(vin)"
        var query = [URLQueryItem(name: "format", value: "json")]
        if let modelYear { query.append(URLQueryItem(name: "modelyear", value: String(modelYear))) }
        components.queryItems = query
        guard let url = components.url else { throw VINDecodeError.serviceUnavailable }
        do {
            var request = URLRequest(url: url)
            request.timeoutInterval = 30
            let (data, response) = try await session.data(for: request)
            guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw VINDecodeError.serviceUnavailable }
            let result = try JSONDecoder().decode(Envelope.self, from: data).Results.first
            guard let result else { throw VINDecodeError.noData }
            let errorCode = result.ErrorCode?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let errorText = nonempty(result.ErrorText)
            if errorCode.split(separator: ",").contains(where: { $0.trimmingCharacters(in: .whitespaces) == "1" }) {
                throw VINDecodeError.invalidCheckDigit(errorText)
            }
            return VINDecodeResult(
                modelYear: nonempty(result.ModelYear), make: nonempty(result.Make), model: nonempty(result.Model), series: nonempty(result.Series),
                engine: nonempty(result.EngineModel), transmissionStyle: nonempty(result.TransmissionStyle),
                source: "NHTSA vPIC · \(Date.now.formatted(date: .abbreviated, time: .omitted))",
                errorCode: errorCode
            )
        } catch let error as VINDecodeError {
            throw error
        } catch let error as URLError where error.code == .timedOut {
            throw VINDecodeError.serviceTimedOut
        } catch {
            throw VINDecodeError.serviceUnavailable
        }
    }

    private static func nonempty(_ value: String?) -> String { guard let value, !value.isEmpty, value != "Not Applicable", value != "0" else { return "" }; return value }
}
