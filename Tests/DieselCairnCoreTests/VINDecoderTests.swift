import Foundation
import XCTest
import iScanCore
import iScanModels

final class VINDecoderTests: XCTestCase {
    func testDefaultVehicleProfileUsesOwnerConfirmedSchoolBusModelNumber() {
        let profile = VehicleProfile()
        XCTAssertEqual(profile.model, "RE300")
        XCTAssertEqual(profile.vinDecodedModel, "PB305")
        XCTAssertEqual(profile.vinDecodeSource, "Owner-confirmed PB305; VIN not yet decoded")
    }

    func testLegacyCommercialCodeDoesNotOverrideOwnerConfirmedSchoolBusIdentity() {
        var profile = VehicleProfile()
        profile.make = "IC BUS"
        profile.model = "PC305"

        profile.normalizeLegacyIdentity()

        XCTAssertEqual(profile.model, "RE300")
        XCTAssertEqual(profile.vinDecodedModel, "PB305")
        XCTAssertEqual(profile.vinReportedModel, "PC305")
        XCTAssertEqual(profile.displayTitle, "2009 International RE300")
    }

    func testAuctionCommercialVINMapsNHTSAFieldsWithoutOverwritingOwnersRE300Model() async throws {
        MockVINProtocol.responseBody = #"{"Results":[{"ModelYear":"2009","Make":"IC BUS","Model":"PC305","EngineModel":"International DT466/Maxxforce DT","TransmissionStyle":"","Series":"RE","ErrorCode":"0","ErrorText":"0 - VIN decoded clean. Check Digit (9th position) is correct"}]}"#.data(using: .utf8)!
        let session = mockedSession()

        let result = try await VINDecoder.decode("4DRBXAAN39A652442", modelYear: 2009, session: session)

        XCTAssertEqual(result.modelYear, "2009")
        XCTAssertEqual(result.make, "IC BUS")
        XCTAssertEqual(result.model, "PC305")
        XCTAssertEqual(result.series, "RE")
        XCTAssertEqual(result.engine, "International DT466/Maxxforce DT")
        XCTAssertEqual(result.errorCode, "0")
        let profile = try JSONDecoder().decode(VehicleProfile.self, from: Data(#"{"vin":"OLDVIN","model":"RE300","engine":"MaxxForce DT"}"#.utf8))
        XCTAssertEqual(profile.model, "RE300")
        XCTAssertEqual(profile.vinDecodedModel, "PB305")
    }

    func testAuctionSchoolBusVINDecodesAsPB305() async throws {
        MockVINProtocol.responseBody = #"{"Results":[{"ModelYear":"2009","Make":"IC BUS","Model":"PB305","EngineModel":"International DT466/Maxxforce DT","BodyClass":"Bus - School Bus","TransmissionStyle":"","Series":"RE","ErrorCode":"0","ErrorText":"0 - VIN decoded clean. Check Digit (9th position) is correct"}]}"#.data(using: .utf8)!

        let result = try await VINDecoder.decode("4DRBWAAR99A047234", modelYear: 2009, session: mockedSession())

        XCTAssertEqual(result.modelYear, "2009")
        XCTAssertEqual(result.model, "PB305")
        XCTAssertEqual(result.series, "RE")
        XCTAssertEqual(result.engine, "International DT466/Maxxforce DT")
    }

    func testSecondAuctionSchoolBusVINDecodesAsPB305() async throws {
        MockVINProtocol.responseBody = #"{"Results":[{"ModelYear":"2009","Make":"IC BUS","Model":"PB305","EngineModel":"International DT466/Maxxforce DT","BodyClass":"Bus - School Bus","Series":"RE","ErrorCode":"0","ErrorText":"0 - VIN decoded clean. Check Digit (9th position) is correct"}]}"#.data(using: .utf8)!
        let result = try await VINDecoder.decode("4DRBWAAR09A072989", modelYear: 2009, session: mockedSession())
        XCTAssertEqual(result.model, "PB305")
        XCTAssertEqual(result.series, "RE")
    }

    func testNHTSAReportedCheckDigitMismatchIsRejected() async {
        MockVINProtocol.responseBody = #"{"Results":[{"ModelYear":"2009","Make":"IC BUS","Model":"PB305","Series":"RE","ErrorCode":"1","ErrorText":"1 - Check Digit (9th position) does not calculate properly"}]}"#.data(using: .utf8)!

        do {
            _ = try await VINDecoder.decode("4DRBWAAR09A047234", modelYear: 2009, session: mockedSession())
            XCTFail("A VIN flagged with check-digit error should not be auto-applied to the profile.")
        } catch let error as VINDecodeError {
            guard case .invalidCheckDigit = error else { return XCTFail("Unexpected error: \(error)") }
        } catch { XCTFail("Unexpected error: \(error)") }
    }

    private func mockedSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockVINProtocol.self]
        return URLSession(configuration: configuration)
    }
}

private final class MockVINProtocol: URLProtocol {
    static var responseBody = Data()

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.responseBody)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
