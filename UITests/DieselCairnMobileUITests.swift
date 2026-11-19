import XCTest

final class DieselCairnMobileUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testSimulatorFaultWorkflowAndNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["Overview"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["2009 International RE300"].exists)
        openSection("CAN / J1708 bench", in: app)

        let startButton = app.buttons["Start virtual session"]
        XCTAssertTrue(startButton.waitForExistence(timeout: 5))
        startButton.tap()
        XCTAssertTrue(app.buttons["Stop session"].waitForExistence(timeout: 5))

        openSection("Diagnostics", in: app)
        XCTAssertTrue(app.staticTexts["Active fault codes"].waitForExistence(timeout: 5))
        let sendButton = app.buttons["Send test fault"]
        reveal(sendButton, in: app)
        XCTAssertTrue(sendButton.isEnabled)
        sendButton.tap()
        app.scrollViews.firstMatch.swipeDown()
        XCTAssertTrue(app.staticTexts["SPN 110 · FMI 0"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Engine Coolant Temperature: Data is valid but above the normal operating range; most severe level."].exists)
        capture("Diagnostics active fault", in: app)

        let clearButton = app.buttons["Clear simulator faults"]
        reveal(clearButton, in: app)
        clearButton.tap()
        app.scrollViews.firstMatch.swipeDown()
        XCTAssertTrue(app.staticTexts["No active faults reported"].waitForExistence(timeout: 5))
        let liveClearBoundary = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "Live vehicle clear commands are not implemented.")).firstMatch
        reveal(liveClearBoundary, in: app)
        capture("Diagnostics simulator controls", in: app)
    }

    func testVehicleProfileAndFlashProjectBoundaryAreReachable() throws {
        let app = XCUIApplication()
        app.launch()
        openSection("Vehicle profile", in: app)

        XCTAssertTrue(app.staticTexts["RE300 · PB305 school bus"].waitForExistence(timeout: 5))
        let vinField = app.textFields["vehicle-vin"]
        XCTAssertTrue(vinField.waitForExistence(timeout: 5))
        let vinIsEmpty = (vinField.value as? String ?? "").isEmpty
        let decodeButton = app.buttons["Decode VIN"]
        reveal(decodeButton, in: app)
        if vinIsEmpty {
            XCTAssertFalse(decodeButton.isEnabled)
        }
        capture("Vehicle profile", in: app)
        let transmissionNote = app.staticTexts.containing(NSPredicate(format: "label BEGINSWITH %@", "Owner reports an Allison 3000 Series 3000PTS.")).firstMatch
        reveal(transmissionNote, in: app)

        openSection("Flash Studio", in: app)
        XCTAssertTrue(app.buttons["Choose file…"].waitForExistence(timeout: 5))
        let buildButton = app.buttons["Build flash project"]
        reveal(buildButton, in: app)
        XCTAssertFalse(buildButton.isEnabled)
        reveal(app.staticTexts["Project is not yet an executable flash program"], in: app)
        capture("Flash Studio", in: app)
    }

    func testAdapterLinkAndVirtualSessionLifecycle() {
        let app = XCUIApplication()
        app.launch()
        openSection("Adapters", in: app)
        app.buttons["Open virtual hardware controls"].tap()
        XCTAssertTrue(app.navigationBars["Virtual hardware"].waitForExistence(timeout: 5))

        openSection("CAN / J1708 bench", in: app)
        app.buttons["Start virtual session"].tap()
        XCTAssertTrue(app.buttons["Stop session"].waitForExistence(timeout: 5))
        capture("Virtual bench running", in: app)
        openSection("Adapters", in: app)
        app.buttons["Stop virtual adapter"].tap()
        XCTAssertTrue(app.buttons["Open virtual hardware controls"].waitForExistence(timeout: 5))
    }

    private func openSection(_ title: String, in app: XCUIApplication) {
        app.buttons["Choose service section"].tap()
        app.buttons[title].tap()
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        let scrollView = app.scrollViews.firstMatch
        for _ in 0..<8 where !element.isHittable {
            scrollView.swipeUp(velocity: .slow)
        }
        XCTAssertTrue(element.isHittable, "Expected visible element: \(element)")
    }

    private func capture(_ name: String, in app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
