import XCTest
import iScanModels

final class VehicleProfileTests: XCTestCase {
    func testOwnerReportedAllisonIdentityIsPresentInNewProfiles() {
        let profile = VehicleProfile()
        XCTAssertEqual(profile.transmissionSeries, "Allison 3000 Series")
        XCTAssertEqual(profile.transmissionModel, "3000PTS")
    }

    func testLegacyProfilesWithoutTransmissionFieldsUseOwnerReportedDefaults() throws {
        let data = Data("{\"year\":\"2009\",\"model\":\"RE300\"}".utf8)
        let profile = try JSONDecoder().decode(VehicleProfile.self, from: data)
        XCTAssertEqual(profile.transmissionSeries, "Allison 3000 Series")
        XCTAssertEqual(profile.transmissionModel, "3000PTS")
    }
}
