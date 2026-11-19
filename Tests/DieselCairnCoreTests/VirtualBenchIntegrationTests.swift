import XCTest
import iScanCore
import iScanModels

@MainActor
final class VirtualBenchIntegrationTests: XCTestCase {
    func testSimulatorIsDisconnectedAndProducesNoDataUntilStarted() {
        let sim = DiagnosticSimulator()
        sim.advance(by: 0.05)
        XCTAssertFalse(sim.virtualAdapterConnected)
        XCTAssertFalse(sim.isRunning)
        XCTAssertTrue(sim.readings.isEmpty)
        XCTAssertTrue(sim.recentFrames.isEmpty)
    }

    func testGeneratedEngineFramesTraverseVirtualAdapterAndDecode() {
        let sim = DiagnosticSimulator()
        sim.startVirtualSession()
        for _ in 0..<20 { sim.advance(by: 0.05) }

        XCTAssertGreaterThan(sim.adapterFramesReceived, 0)
        XCTAssertGreaterThan(sim.framesReceived, 0)
        XCTAssertEqual(sim.readings[.engineSpeed]?.source, .simulator)
        XCTAssertEqual(sim.readings[.coolantTemperature]?.value ?? -999, 88, accuracy: 2)
        XCTAssertEqual(sim.readings[.engineOilTemperature]?.value ?? -999, 101, accuracy: 1)
        XCTAssertEqual(sim.readings[.intakeAirTemperature]?.value ?? -999, 31, accuracy: 1)
        XCTAssertEqual(sim.recentFrames.first(where: { $0.pgn == RE300PGN.engineTemperature1.rawValue })?.payload[0], 128)
    }

    func testGenericTransmissionNodeSendsAndDecodesETC2() {
        let sim = DiagnosticSimulator()
        sim.simulatedGear = 5
        sim.startVirtualSession()
        sim.advance(by: 0.05)
        sim.advance(by: 0.05)

        XCTAssertEqual(sim.selectedGear, 5)
        XCTAssertEqual(sim.selectedRange, "OD")
        XCTAssertTrue(sim.recentFrames.contains { $0.pgn == 0xF005 && $0.sourceAddress == 0x04 })
    }

    func testManualFrameInjectionUsesAdapterPacketCodec() throws {
        let sim = DiagnosticSimulator()
        sim.startVirtualSession()
        var payload = [UInt8](repeating: 0xFF, count: 8)
        let rawRPM = UInt16(1000 / 0.125)
        payload[3] = UInt8(rawRPM & 0xFF)
        payload[4] = UInt8(rawRPM >> 8)

        let frame = try sim.sendManualFrame(pgn: 0xF004, sourceAddress: 0, priority: 3, payload: payload)
        XCTAssertEqual(frame.pgn, 0xF004)
        XCTAssertEqual(sim.readings[.engineSpeed]?.value ?? 0, 1000, accuracy: 0.125)
        XCTAssertEqual(sim.adapterFramesSent, 1)
        XCTAssertEqual(sim.adapterFramesReceived, 1)
    }

    func testJ1587ManualMessageUsesAdapterCodecAndChecksum() throws {
        let sim = DiagnosticSimulator()
        sim.startVirtualSession()
        let message = try sim.sendManualJ1587(mid: 0x80, data: [0x10, 0x2A])

        XCTAssertEqual(message.mid, 0x80)
        XCTAssertEqual(message.dataBytes, [0x10, 0x2A])
        XCTAssertTrue(J1587Message.hasValidChecksum(message.bytes))
        XCTAssertEqual(sim.recentJ1587Messages.first, message)
        XCTAssertEqual(sim.adapterFramesSent, 1)
        XCTAssertEqual(sim.adapterFramesReceived, 1)
    }

    func testJ1708VirtualControlsFailClosedForIdleAndCollision() throws {
        let sim = DiagnosticSimulator()
        sim.startVirtualSession()
        sim.simulatedJ1708IdleBits = 9
        XCTAssertThrowsError(try sim.sendManualJ1587(mid: 0x80, data: [0x10]))

        sim.simulatedJ1708IdleBits = 10
        sim.injectJ1708Collision = true
        XCTAssertThrowsError(try sim.sendManualJ1587(mid: 0x80, data: [0x10])) { error in
            XCTAssertEqual(error as? J1587Error, .collision)
        }
        XCTAssertEqual(sim.transportErrors, 1)
    }

    func testVirtualDM1FaultIsDecodedFromReceivedFrame() {
        let sim = DiagnosticSimulator()
        sim.injectDemoFault = true
        sim.startVirtualSession()
        for _ in 0..<10 { sim.advance(by: 0.05) }

        XCTAssertEqual(sim.faults.first?.code, "SPN 110 · FMI 0")
        XCTAssertTrue(sim.recentFrames.contains { $0.pgn == 0xFECA })
    }

    func testSyntheticFaultFixtureCanBeClearedWithoutVehicleSession() throws {
        let sim = DiagnosticSimulator()
        sim.startVirtualSession()
        let fault = try sim.sendSyntheticFault(spn: 190, fmi: 2, occurrenceCount: 7)

        XCTAssertEqual(fault.code, "SPN 190 · FMI 2")
        XCTAssertEqual(fault.description, "Engine Speed: Data is erratic, intermittent, or incorrect.")
        XCTAssertEqual(fault.occurrenceCount, 7)
        XCTAssertTrue(sim.injectDemoFault)

        sim.clearSimulatorFaults()
        XCTAssertTrue(sim.faults.isEmpty)
        XCTAssertFalse(sim.injectDemoFault)
    }

    func testDM2FrameIsShownAsPreviouslyActive() throws {
        let sim = DiagnosticSimulator()
        sim.startVirtualSession()
        let dtc = J1939DTC(spn: 110, fmi: 1, occurrenceCount: 4)
        _ = try sim.sendManualFrame(pgn: 0x00FECC, sourceAddress: 0, priority: 6, payload: J1939FaultCatalog.encodeDM1(dtc))

        XCTAssertTrue(sim.faults.isEmpty)
        XCTAssertEqual(sim.previouslyActiveFaults.first?.code, "SPN 110 · FMI 1")
        XCTAssertEqual(sim.previouslyActiveFaults.first?.isActive, false)
    }

    func testReplayReassemblesBroadcastJ1939TransportMessage() {
        let sim = DiagnosticSimulator()
        let source: UInt8 = 0x80
        let payload = Array(UInt8(1)...UInt8(9))
        let start = Date(timeIntervalSince1970: 10)
        let frames = [
            J1939Frame(identifier: (UInt32(3) << 26) | (UInt32(0x00ECFF) << 8) | UInt32(source), payload: [0x20, 9, 0, 2, 0xFF, 0xCA, 0xFE, 0], timestamp: start),
            J1939Frame(identifier: (UInt32(3) << 26) | (UInt32(0x00EBFF) << 8) | UInt32(source), payload: [1] + Array(payload[0..<7]), timestamp: start.addingTimeInterval(0.01)),
            J1939Frame(identifier: (UInt32(3) << 26) | (UInt32(0x00EBFF) << 8) | UInt32(source), payload: [2, payload[7], payload[8], 0xFF, 0xFF, 0xFF, 0xFF, 0xFF], timestamp: start.addingTimeInterval(0.02)),
        ]
        sim.loadReplay(frames)

        XCTAssertEqual(sim.recentTransportMessages.count, 1)
        XCTAssertEqual(sim.recentTransportMessages.first?.pgn, 0x00FECA)
        XCTAssertEqual(sim.recentTransportMessages.first?.payload, payload)
        XCTAssertEqual(sim.recentTransportMessages.first?.source, .replay)
    }

    func testTerminationFaultDropsFramesAndCountsErrors() {
        let sim = DiagnosticSimulator()
        sim.terminationEnabled = false
        sim.startVirtualSession()
        sim.advance(by: 0.05)

        XCTAssertGreaterThan(sim.transportErrors, 0)
        XCTAssertLessThan(sim.adapterFramesReceived, sim.adapterFramesSent)
    }

    func testAdapterAndBusBitrateMismatchBlocksReception() {
        let sim = DiagnosticSimulator()
        sim.bitrate = .kbps500
        sim.busBitrate = .kbps250
        sim.startVirtualSession()
        sim.advance(by: 0.05)

        XCTAssertEqual(sim.adapterFramesSent, 2)
        XCTAssertEqual(sim.adapterFramesReceived, 0)
        XCTAssertEqual(sim.transportErrors, 2)
        XCTAssertTrue(sim.readings.isEmpty)
    }

    func testUnpoweredECUDoesNotProduceEngineReadings() {
        let sim = DiagnosticSimulator()
        sim.simulatedSupplyVoltage = 9.0
        sim.startVirtualSession()
        for _ in 0..<20 { sim.advance(by: 0.05) }

        XCTAssertTrue(sim.readings.isEmpty)
        XCTAssertNil(sim.selectedGear)
    }

    func testManualFrameRequiresConnectedVirtualAdapterAndValidPayload() {
        let sim = DiagnosticSimulator()
        XCTAssertThrowsError(try sim.sendManualFrame(pgn: 0xF004, sourceAddress: 0, priority: 3, payload: [0xFF]))

        sim.startVirtualSession()
        XCTAssertThrowsError(try sim.sendManualFrame(pgn: 0xF004, sourceAddress: 0, priority: 3, payload: [UInt8](repeating: 0, count: 9)))
    }

    func testStoppingVirtualAdapterClearsLiveReadings() {
        let sim = DiagnosticSimulator()
        sim.startVirtualSession()
        sim.advance(by: 0.05)
        XCTAssertFalse(sim.readings.isEmpty)
        sim.stopVirtualSession()

        XCTAssertFalse(sim.virtualAdapterConnected)
        XCTAssertTrue(sim.readings.isEmpty)
        XCTAssertNil(sim.selectedGear)
    }
}
