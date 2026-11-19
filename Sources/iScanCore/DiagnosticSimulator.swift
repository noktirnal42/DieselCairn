import Foundation
import Combine
import iScanModels

public enum SimulatorScenario: String, CaseIterable, Identifiable {
    case curbsideIdle = "Curbside idle"
    case roadCruise = "Road cruise"
    case loadedClimb = "Loaded climb"
    case hotSoak = "Hot soak"
    public var id: String { rawValue }
}

public enum VirtualAdapterDevice: String, CaseIterable, Identifiable {
    case leonardoMCP2515 = "Leonardo + MCP2515"
    case stm32MCP2515 = "STM32 + MCP2515"
    case ft232hMCP2515 = "FT232H + MCP2515"
    case bleGateway = "BLE CAN gateway"
    public var id: String { rawValue }
}

public enum SimulatedCANBitrate: Int, CaseIterable, Identifiable {
    case kbps125 = 125_000
    case kbps250 = 250_000
    case kbps500 = 500_000
    case mbps1 = 1_000_000
    public var id: Int { rawValue }
    public var label: String { "\(rawValue / 1000) kbit/s" }
}

public enum VirtualBusError: Error, LocalizedError {
    case noSession
    case invalidFrame
    case dropped
    public var errorDescription: String? {
        switch self {
        case .noSession: "Connect the virtual adapter before transmitting on the simulated bus."
        case .invalidFrame: "Enter a valid PGN, source address, priority, and 0–8 byte payload."
        case .dropped: "The virtual adapter did not receive the frame because a modeled bus/transport fault dropped it."
        }
    }
}

@MainActor
public final class DiagnosticSimulator: ObservableObject {
    @Published public private(set) var readings: [RE300Parameter: ParameterReading] = [:]
    @Published public private(set) var framesReceived = 0
    @Published public private(set) var selectedGear: Int?
    @Published public private(set) var selectedRange: String?
    @Published public private(set) var isRunning = false
    @Published public private(set) var virtualAdapterConnected = false
    @Published public private(set) var selectedAdapter: VirtualAdapterDevice = .leonardoMCP2515
    @Published public var bitrate: SimulatedCANBitrate = .kbps250
    @Published public var busBitrate: SimulatedCANBitrate = .kbps250
    @Published public var simulatedBusLoad = 18.0
    @Published public var injectTransportErrors = false
    @Published public private(set) var lastUpdate = Date.now
    @Published public private(set) var faults: [DiagnosticFault] = []
    @Published public private(set) var recentFrames: [J1939Frame] = []
    @Published public private(set) var recentJ1587Messages: [J1587Message] = []
    @Published public var simulatedJ1708IdleBits = 10
    @Published public var simulatedJ1708Priority: UInt8 = 4
    @Published public var j1708TransceiverConnected = true
    @Published public var j1587SimulatorNodeOnline = true
    @Published public var injectJ1708Collision = false
    @Published public var scenario: SimulatorScenario = .curbsideIdle
    @Published public var injectDemoFault = false
    @Published public private(set) var isReplayMode = false
    @Published public private(set) var adapterFramesReceived = 0
    @Published public private(set) var adapterFramesSent = 0
    @Published public private(set) var transportErrors = 0
    @Published public private(set) var lastAdapterTimestampMicros: UInt32 = 0
    @Published public var ecuNodeOnline = true
    @Published public var tcmNodeOnline = true
    @Published public var simulatedSupplyVoltage = 13.8
    @Published public var terminationEnabled = true
    @Published public var simulatedGear = 1
    @Published public var adapterMCUPowered = true
    @Published public var canControllerPowered = true
    @Published public var transceiverConnected = true
    @Published public var adapterFirmwareRunning = true

    private var elapsed = 0.0
    private var schedulerTick = 0
    private var virtualTimestampMicros: UInt32 = 0
    private var replayFrames: [J1939Frame] = []
    private var replayIndex = 0

    public init() {}

    public func toggleRunning() {
        if isRunning { stopVirtualSession() } else { startVirtualSession() }
    }
    public func startVirtualSession() {
        virtualAdapterConnected = true
        isRunning = true
        readings.removeAll()
        faults.removeAll()
        selectedGear = nil
        selectedRange = nil
        recentFrames.removeAll()
        recentJ1587Messages.removeAll()
        framesReceived = 0
        adapterFramesSent = 0
        adapterFramesReceived = 0
        transportErrors = 0
        isReplayMode = false
        replayFrames.removeAll()
        replayIndex = 0
        schedulerTick = 0
        elapsed = 0
        virtualTimestampMicros = 0
        lastUpdate = .now
    }
    public func stopVirtualSession() {
        isRunning = false
        virtualAdapterConnected = false
        readings.removeAll()
        faults.removeAll()
        selectedGear = nil
        selectedRange = nil
        isReplayMode = false
        replayFrames.removeAll()
        replayIndex = 0
    }
    public func selectAdapter(_ adapter: VirtualAdapterDevice) { selectedAdapter = adapter }

    @discardableResult
    public func sendManualJ1587(mid: UInt8, data: [UInt8]) throws -> J1587Message {
        guard isRunning, virtualAdapterConnected else { throw VirtualBusError.noSession }
        let delay = try J1708Timing.priorityDelayMicroseconds(class: simulatedJ1708Priority)
        guard J1708Timing.mayTransmit(idleHighBits: simulatedJ1708IdleBits,
                                      elapsedAfterIdleMicroseconds: delay,
                                      priority: simulatedJ1708Priority) else { throw J1587Error.busBusy }
        guard adapterMCUPowered, j1708TransceiverConnected, adapterFirmwareRunning,
              j1587SimulatorNodeOnline,
              simulatedSupplyVoltage >= 10.5 else { throw J1587Error.busBusy }
        if injectJ1708Collision { transportErrors += 1; throw J1587Error.collision }
        let message = try J1587Message.make(mid: mid, data: data)
        let payload = [UInt8(virtualTimestampMicros >> 24), UInt8((virtualTimestampMicros >> 16) & 0xFF),
                       UInt8((virtualTimestampMicros >> 8) & 0xFF), UInt8(virtualTimestampMicros & 0xFF)] + message.bytes
        let sequence = UInt16(truncatingIfNeeded: adapterFramesSent)
        let wire = try AdapterFrameCodec.encode(AdapterMessage(type: .j1587Receive, sequence: sequence, payload: payload))
        let decoded = try AdapterFrameCodec.decode(Array(wire.dropLast()))
        guard decoded.type == .j1587Receive, decoded.sequence == sequence,
              decoded.payload.count >= 6,
              let received = try? J1587Message(bytes: Array(decoded.payload.dropFirst(4))) else {
            transportErrors += 1
            throw J1587Error.invalidFrame
        }
        adapterFramesSent += 1
        adapterFramesReceived += 1
        recentJ1587Messages = Array(([received] + recentJ1587Messages).prefix(100))
        return received
    }
    @discardableResult
    public func sendManualFrame(pgn: UInt32, sourceAddress: UInt8, priority: UInt8, payload: [UInt8]) throws -> J1939Frame {
        guard isRunning, virtualAdapterConnected else { throw VirtualBusError.noSession }
        guard pgn <= 0x3_FFFF, priority <= 7, payload.count <= 8 else { throw VirtualBusError.invalidFrame }
        let frame = J1939Frame(identifier: J1939Frame.makeIdentifier(pgn: pgn, sourceAddress: sourceAddress, priority: priority), payload: payload)
        recentFrames = Array(([frame] + recentFrames).prefix(100))
        guard receive(frame, source: .simulator) else { throw VirtualBusError.dropped }
        return frame
    }
    public func loadReplay(_ frames: [J1939Frame]) {
        guard !frames.isEmpty else { return }
        replayFrames = frames.sorted { $0.timestamp < $1.timestamp }
        replayIndex = 0
        isReplayMode = true
        isRunning = true
        virtualAdapterConnected = true
        readings.removeAll()
        recentFrames.removeAll()
        faults.removeAll()
        framesReceived = 0
        advance()
    }
    public func reset() {
        elapsed = 0
        replayFrames.removeAll()
        replayIndex = 0
        isReplayMode = false
        stopVirtualSession()
        framesReceived = 0
        adapterFramesReceived = 0
        adapterFramesSent = 0
        transportErrors = 0
        readings.removeAll()
        recentFrames.removeAll()
        faults.removeAll()
        advance()
    }

    public func advance(by interval: Double = 0.05) {
        guard isRunning, virtualAdapterConnected else { return }
        if isReplayMode {
            advanceReplay()
            return
        }
        elapsed += interval
        schedulerTick += 1
        virtualTimestampMicros &+= UInt32(max(0, interval * 1_000_000))
        let wave = sin(elapsed / 4.5)
        let rpm: Double
        let load: Double
        switch scenario {
        case .curbsideIdle: rpm = 730 + 45 * sin(elapsed / 3) + 22 * sin(elapsed * 1.7); load = 18 + 5 * wave
        case .roadCruise: rpm = 1550 + 90 * sin(elapsed / 6); load = 42 + 9 * wave
        case .loadedClimb: rpm = 2050 + 140 * sin(elapsed / 5); load = 78 + 8 * wave
        case .hotSoak: rpm = 760 + 35 * sin(elapsed / 3); load = 12 + 3 * wave
        }
        let coolant = (scenario == .hotSoak ? 116 : 88) + min(8, elapsed / 45) + 0.8 * sin(elapsed / 12)
        let oilTemp = 101 + 2 * sin(elapsed / 18)
        let fuel = 11 + 2.5 * max(0, sin(elapsed / 5)) + load / 12
        let manifold = 105 + load * 1.7
        let intake = 31 + 1.5 * sin(elapsed / 10)
        let t = Date.now

        // Virtual ECU nodes transmit onto the simulated J1939 bus. The virtual adapter
        // then serializes each frame using the same COBS/CRC protocol as firmware. Only
        // valid frames received back through that adapter reach the application decoder.
        var tickFrames: [J1939Frame] = []
        if ecuNodeOnline && simulatedSupplyVoltage >= 10.5 {
            let engineSpeed = frameBytes(for: .engineSpeed, value: rpm)
            let engineLoad = frameBytes(for: .engineLoad, value: load)
            var temperatures = [UInt8](repeating: 0xFF, count: 8)
            temperatures[0] = UInt8(clamping: Int((coolant + 40).rounded()))
            let oilRaw = UInt16(clamping: Int(((oilTemp + 273) / 0.03125).rounded()))
            temperatures[3] = UInt8(oilRaw & 0xFF)
            temperatures[4] = UInt8(oilRaw >> 8)
            var frames: [(UInt32, [UInt8])] = [
                (RE300PGN.electronicEngineController1.rawValue, engineSpeed),
                (RE300PGN.electronicEngineController2.rawValue, engineLoad),
            ]
            if schedulerTick.isMultiple(of: 20) {
                frames.append((RE300PGN.engineTemperature1.rawValue, temperatures))
                frames.append((RE300PGN.ambientConditions.rawValue, frameBytes(for: .intakeAirTemperature, value: intake)))
            }
            if schedulerTick.isMultiple(of: 2) {
                frames.append((RE300PGN.fuelEconomy.rawValue, frameBytes(for: .fuelRate, value: fuel)))
                frames.append((RE300PGN.intakeManifold1.rawValue, frameBytes(for: .intakeManifoldPressure, value: manifold)))
            }
            tickFrames.append(contentsOf: frames.map { J1939Frame(identifier: J1939Frame.makeIdentifier(pgn: $0.0, sourceAddress: 0x00), payload: $0.1, timestamp: t) })
        }
        if ecuNodeOnline && simulatedSupplyVoltage >= 10.5 && injectDemoFault && schedulerTick.isMultiple(of: 10) {
            // DM1 with one active SPN 110 / FMI 0 DTC. This is generated by the virtual
            // ECU and must traverse the same virtual adapter packet path as other frames.
            tickFrames.append(J1939Frame(identifier: J1939Frame.makeIdentifier(pgn: 0x00FECA, sourceAddress: 0x00), payload: [0x00, 0x00, 110, 0, 0, 1, 0xFF, 0xFF], timestamp: t))
        }
        if tcmNodeOnline && simulatedSupplyVoltage >= 10.5 && schedulerTick.isMultiple(of: 2) {
            let gearCode = UInt8(0x7D + min(6, max(1, simulatedGear)))
            let rangeName = rangeLabel(for: simulatedGear)
            let rangeBytes = Array(rangeName.utf8.prefix(2))
            let paddedRange = rangeBytes.count == 1 ? [UInt8(32), rangeBytes[0]] : Array(rangeBytes.prefix(2))
            let tcmData: [UInt8] = [gearCode, 0xFF, 0xFF, gearCode, paddedRange[0], paddedRange[1], paddedRange[0], paddedRange[1]]
            tickFrames.append(J1939Frame(identifier: J1939Frame.makeIdentifier(pgn: 0x00F005, sourceAddress: 0x04, priority: 6), payload: tcmData, timestamp: t))
        }
        for frame in tickFrames {
            _ = receive(frame, source: .simulator)
        }
        recentFrames = (tickFrames + recentFrames).prefix(100).map { $0 }
        if !injectDemoFault || !ecuNodeOnline || simulatedSupplyVoltage < 10.5 { faults = [] }
        if !ecuNodeOnline || simulatedSupplyVoltage < 10.5 { readings.removeAll() }
        if !tcmNodeOnline || simulatedSupplyVoltage < 10.5 { selectedGear = nil; selectedRange = nil }
        lastUpdate = t
    }

    private static func adapterPayload(for frame: J1939Frame, timestampMicros: UInt32) -> [UInt8] {
        let id = frame.identifier
        let length = UInt8(frame.payload.count)
        let timestamp = [UInt8(timestampMicros >> 24), UInt8((timestampMicros >> 16) & 0xFF), UInt8((timestampMicros >> 8) & 0xFF), UInt8(timestampMicros & 0xFF)]
        return [UInt8(id >> 24), UInt8((id >> 16) & 0xFF), UInt8((id >> 8) & 0xFF), UInt8(id & 0xFF), length] + frame.payload + timestamp
    }

    private static func frame(fromAdapterPayload payload: [UInt8]) -> (frame: J1939Frame, timestampMicros: UInt32)? {
        guard payload.count >= 9 else { return nil }
        let id = UInt32(payload[0]) << 24 | UInt32(payload[1]) << 16 | UInt32(payload[2]) << 8 | UInt32(payload[3])
        let dlc = Int(payload[4])
        guard id <= 0x1FFF_FFFF, dlc <= 8, payload.count == 9 + dlc else { return nil }
        let offset = 5 + dlc
        let micros = UInt32(payload[offset]) << 24 | UInt32(payload[offset + 1]) << 16 | UInt32(payload[offset + 2]) << 8 | UInt32(payload[offset + 3])
        return (J1939Frame(identifier: id, payload: Array(payload[5..<offset]), timestamp: .now), micros)
    }

    private func advanceReplay() {
        guard !replayFrames.isEmpty else { isReplayMode = false; return }
        let nextCount = min(12, replayFrames.count - replayIndex)
        let nextFrames = Array(replayFrames[replayIndex..<(replayIndex + nextCount)])
        replayIndex += nextCount
        var receivedFrames: [J1939Frame] = []
        for frame in nextFrames where receive(frame, source: .replay) { receivedFrames.append(frame) }
        recentFrames = Array((receivedFrames + recentFrames).prefix(100))
        lastUpdate = Date.now
        if replayIndex >= replayFrames.count { replayIndex = 0 }
    }

    private func receive(_ frame: J1939Frame, source: ReadingSource) -> Bool {
        let sequence = adapterFramesSent
        adapterFramesSent += 1
        guard adapterMCUPowered, canControllerPowered, transceiverConnected, adapterFirmwareRunning,
              bitrate == busBitrate else {
            transportErrors += 1
            return false
        }
        do {
            let wire = try AdapterFrameCodec.encode(AdapterMessage(type: .canReceive, sequence: UInt16(truncatingIfNeeded: sequence), payload: Self.adapterPayload(for: frame, timestampMicros: virtualTimestampMicros)))
            let modeledDrop = (injectTransportErrors && sequence % 17 == 8)
                || (!terminationEnabled && sequence % 5 == 0)
                || (simulatedBusLoad >= 90 && sequence % 4 == 0)
            if modeledDrop { transportErrors += 1; return false }
            let packet = try AdapterFrameCodec.decode(Array(wire.dropLast()))
            guard packet.type == .canReceive, packet.sequence == UInt16(truncatingIfNeeded: sequence),
                  let packetFrame = Self.frame(fromAdapterPayload: packet.payload) else {
                transportErrors += 1
                return false
            }
            adapterFramesReceived += 1
            lastAdapterTimestampMicros = packetFrame.timestampMicros
            let receivedFrame = packetFrame.frame
            for parameter in RE300Parameter.allCases where parameter.pgn.rawValue == receivedFrame.pgn {
                if let reading = try? J1939Decoder.reading(for: parameter, in: receivedFrame, source: source) {
                    readings[parameter] = reading
                    framesReceived += 1
                }
            }
            if receivedFrame.pgn == 0x00FECA {
                faults = receivedFrame.payload.count >= 6 && receivedFrame.payload[2] != 0xFF
                    ? [DiagnosticFault(code: "SPN \(receivedFrame.payload[2]) · FMI \((receivedFrame.payload[4] >> 5) & 0x1F)", module: "Virtual engine ECM", description: "Virtual ECU reports a simulated diagnostic trouble code", isActive: true)]
                    : []
            }
            if receivedFrame.pgn == 0x00F005, receivedFrame.sourceAddress == 0x04, receivedFrame.payload.count == 8 {
                let rawGear = receivedFrame.payload[3]
                selectedGear = (0x7E...0x83).contains(rawGear) ? Int(rawGear - 0x7D) : nil
                let rangeBytes = Array(receivedFrame.payload[6...7]).filter { $0 >= 32 && $0 <= 126 }
                selectedRange = rangeBytes.isEmpty ? nil : String(bytes: rangeBytes, encoding: .ascii)?.trimmingCharacters(in: .whitespaces)
            }
            return true
        } catch { transportErrors += 1; return false }
    }

    private func frameBytes(for parameter: RE300Parameter, value: Double) -> [UInt8] {
        var bytes = [UInt8](repeating: 0xFF, count: 8)
        func putWord(_ offset: Int, _ raw: Int) {
            let v = UInt16(clamping: raw)
            bytes[offset] = UInt8(v & 0xFF)
            bytes[offset + 1] = UInt8(v >> 8)
        }
        switch parameter {
        case .engineSpeed:
            putWord(3, Int((value / 0.125).rounded()))
        case .engineLoad:
            bytes[2] = UInt8(clamping: Int((value + 125).rounded()))
        case .coolantTemperature:
            bytes[0] = UInt8(clamping: Int((value + 40).rounded()))
        case .engineOilTemperature:
            putWord(3, Int(((value + 273) / 0.03125).rounded()))
        case .fuelRate:
            putWord(0, Int((value / 0.05).rounded()))
        case .intakeManifoldPressure:
            putWord(0, Int((value / 0.1).rounded()))
        case .intakeAirTemperature:
            putWord(3, Int(((value + 273) / 0.03125).rounded()))
        }
        return bytes
    }

    private func rangeLabel(for gear: Int) -> String {
        switch gear {
        case 1...3: "\(gear)"
        case 4: "D"
        case 5: "OD"
        default: "6"
        }
    }
}
