import Foundation
import CryptoKit
import Dispatch
import Darwin
import iScanCore
import iScanModels
import DieselCairnUI

private struct RPCRequest: Decodable {
    let jsonrpc: String?
    let id: JSONValue?
    let method: String
    let params: [String: JSONValue]?
}

private enum JSONValue: Decodable {
    case string(String), number(Double), bool(Bool), object([String: JSONValue]), array([JSONValue]), null
    init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let value = try? c.decode(Bool.self) { self = .bool(value) }
        else if let value = try? c.decode(Double.self) { self = .number(value) }
        else if let value = try? c.decode(String.self) { self = .string(value) }
        else if let value = try? c.decode([String: JSONValue].self) { self = .object(value) }
        else if let value = try? c.decode([JSONValue].self) { self = .array(value) }
        else { throw DecodingError.dataCorruptedError(in: c, debugDescription: "Unsupported JSON value") }
    }
    var any: Any {
        switch self {
        case .string(let v): v
        case .number(let v): v
        case .bool(let v): v
        case .object(let v): v.mapValues(\.any)
        case .array(let v): v.map(\.any)
        case .null: NSNull()
        }
    }
    var string: String? { if case .string(let v) = self { v } else { nil } }
    var number: Double? { if case .number(let v) = self { v } else { nil } }
    var bool: Bool? { if case .bool(let v) = self { v } else { nil } }
    var object: [String: JSONValue]? { if case .object(let v) = self { v } else { nil } }
    var array: [JSONValue]? { if case .array(let v) = self { v } else { nil } }
}

@MainActor
private final class DieselCairnMCPServer {
    private let simulator = DiagnosticSimulator()
    private var profile = VehicleProfile()
    private var parser = MCPFrameParser()
    private let writer = MCPStdout()
    private var timer: Timer?
    private var inputSource: DispatchSourceRead?
    private let docs: [(String, String, String)] = [
        ("overview", "DieselCairn product overview", "README.md"),
        ("simulator", "Virtual CAN and hardware simulator", "docs/SIMULATOR.md"),
        ("protocol", "Adapter protocol", "AdapterProtocol.md"),
        ("flash", "Flash project format and write boundary", "FlashStudioSpec.md"),
        ("hardware", "Hardware design", "HardwareDesign.md"),
        ("firmware", "Firmware research and evidence", "docs/FIRMWARE_RESEARCH.md")
    ]

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.simulator.advance() }
        }
        let source = DispatchSource.makeReadSource(fileDescriptor: STDIN_FILENO, queue: .global(qos: .userInitiated))
        source.setEventHandler { [weak self] in
            var bytes = [UInt8](repeating: 0, count: 16_384)
            let count = read(STDIN_FILENO, &bytes, bytes.count)
            if count > 0 {
                let data = Data(bytes.prefix(count))
                Task { @MainActor in self?.parser.append(data) }
            } else if count == 0 {
                Task { @MainActor in self?.inputSource?.cancel() }
                exit(0)
            }
        }
        source.resume()
        inputSource = source
    }

    func receive(_ message: Data) {
        guard let request = try? JSONDecoder().decode(RPCRequest.self, from: message), request.jsonrpc == "2.0" else { return }
        guard let id = request.id else { return }
        Task { @MainActor in
            do {
                let result = try await handle(method: request.method, params: request.params ?? [:])
                writer.send(["jsonrpc": "2.0", "id": id.any, "result": result])
            } catch {
                writer.send(["jsonrpc": "2.0", "id": id.any, "error": ["code": -32000, "message": error.localizedDescription]])
            }
        }
    }

    private func handle(method: String, params: [String: JSONValue]) async throws -> [String: Any] {
        switch method {
        case "initialize":
            return [
                "protocolVersion": params["protocolVersion"]?.string ?? "2025-03-26",
                "capabilities": ["tools": ["listChanged": false], "resources": ["subscribe": false, "listChanged": false]],
                "serverInfo": ["name": "dieselcairn", "version": "1.0.0"]
            ]
        case "ping": return [:]
        case "tools/list": return ["tools": Self.toolDefinitions]
        case "resources/list":
            return ["resources": docs.map { id, title, _ in ["uri": "dieselcairn://docs/\(id)", "name": title, "mimeType": "text/markdown"] }]
        case "resources/read":
            guard let uri = params["uri"]?.string, let id = uri.split(separator: "/").last,
                  let item = docs.first(where: { $0.0 == String(id) }) else { throw MCPError.invalid("Unknown DieselCairn document URI.") }
            let fileURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(item.2)
            let text = try String(contentsOf: fileURL, encoding: .utf8)
            return ["contents": [["uri": uri, "mimeType": "text/markdown", "text": text]]]
        case "tools/call":
            let name = params["name"]?.string ?? ""
            let args = params["arguments"]?.object ?? [:]
            let result = try await callTool(name, args)
            return ["content": [["type": "text", "text": result]], "isError": false]
        default: throw MCPError.invalid("Unsupported MCP method: \(method)")
        }
    }

    private func callTool(_ name: String, _ a: [String: JSONValue]) async throws -> String {
        switch name {
        case "vehicle_get_profile": return json(profile)
        case "vehicle_update_profile":
            guard let changes = a["fields"]?.object else { throw MCPError.invalid("Pass a fields object containing the profile properties to update.") }
            try updateProfile(changes)
            profile.normalizeLegacyIdentity()
            return json(profile)
        case "vehicle_decode_vin":
            let vin = a["vin"]?.string ?? profile.vin
            guard !vin.isEmpty else { throw MCPError.invalid("Pass a VIN explicitly, or save one in the MCP vehicle profile first.") }
            let year = Int(a["modelYear"]?.string ?? "") ?? Int(profile.year)
            profile.vin = vin
            let decoded = try await VINDecoder.decode(vin, modelYear: year)
            let reported = decoded.model.trimmingCharacters(in: .whitespacesAndNewlines)
            let confirmed = profile.vinDecodedModel.trimmingCharacters(in: .whitespacesAndNewlines)
            profile.vinReportedModel = reported
            let mismatch = !reported.isEmpty && !confirmed.isEmpty && reported.caseInsensitiveCompare(confirmed) != .orderedSame
            if mismatch {
                profile.vinDecodeSource = "Owner-confirmed \(confirmed) retained; NHTSA reports \(reported) · verify VIN and factory label · \(decoded.source)"
                return json(["status": "model_code_mismatch", "reportedModelCode": reported, "confirmedModelCode": confirmed, "profile": try jsonObject(profile), "source": decoded.source])
            }
            if !decoded.modelYear.isEmpty { profile.year = decoded.modelYear }
            if !decoded.make.isEmpty { profile.make = decoded.make }
            if !reported.isEmpty { profile.vinDecodedModel = reported }
            if !decoded.series.isEmpty { profile.vinDecodedSeries = decoded.series }
            if !decoded.transmissionStyle.isEmpty { profile.vinTransmissionStyle = decoded.transmissionStyle }
            if !decoded.engine.isEmpty { profile.engine = decoded.engine }
            profile.vinDecodeSource = decoded.source
            return json(["status": "decoded", "profile": try jsonObject(profile), "source": decoded.source, "notice": "VIN data does not identify ECM/TCM serials or establish calibration compatibility."])
        case "simulator_get_state", "diagnostics_get_state": return json(simulatorState())
        case "simulator_connect":
            if let scenario = a["scenario"]?.string, let value = SimulatorScenario(rawValue: scenario) { simulator.scenario = value }
            simulator.startVirtualSession()
            for _ in 0..<8 { simulator.advance() }
            return json(simulatorState())
        case "simulator_stop": simulator.stopVirtualSession(); return json(simulatorState())
        case "simulator_reset": simulator.reset(); return json(simulatorState())
        case "simulator_set_controls", "virtual_hardware_configure":
            try configureSimulator(a)
            return json(simulatorState())
        case "simulator_inject_fault":
            guard simulator.isRunning else { throw MCPError.invalid("Connect the isolated virtual bench before injecting an ECU fault.") }
            simulator.injectDemoFault = a["enabled"]?.bool ?? true
            simulator.advance()
            return json(simulatorState())
        case "simulator_send_frame":
            let pgn = try uint32(a["pgn"], field: "pgn")
            let source = UInt8(try uint32(a["sourceAddress"], field: "sourceAddress"))
            let priority = UInt8(try uint32(a["priority"], field: "priority"))
            let payload = try bytePayload(a["payload"])
            let frame = try simulator.sendManualFrame(pgn: pgn, sourceAddress: source, priority: priority, payload: payload)
            return json(["accepted": true, "frame": frameObject(frame), "state": simulatorState()])
        case "simulator_send_j1587":
            let midValue = try uint32(a["mid"], field: "mid")
            guard midValue <= 255 else { throw MCPError.invalid("MID must be a byte.") }
            let message = try simulator.sendManualJ1587(mid: UInt8(midValue), data: j1587Payload(a["data"]))
            return json(["accepted": true, "source": "SIMULATOR", "network": "J1587 over virtual J1708", "mid": String(format: "%02X", message.mid), "bytes": message.bytes.map { String(format: "%02X", $0) }.joined(separator: " "), "state": simulatorState()])
        case "simulator_load_replay":
            guard let array = a["frames"]?.array, !array.isEmpty else { throw MCPError.invalid("Pass a non-empty array of frame objects.") }
            let frames = try array.map { item -> J1939Frame in
                guard let row = item.object else { throw MCPError.invalid("Each frame must be an object.") }
                let identifier = try uint32(row["identifier"], field: "identifier")
                return J1939Frame(identifier: identifier, payload: try bytePayload(row["payload"]))
            }
            simulator.loadReplay(frames)
            return json(simulatorState())
        case "simulator_export_trace":
            guard simulator.virtualAdapterConnected else { throw MCPError.invalid("Start a virtual session before exporting a simulator trace.") }
            let fixture = CanTraceFixture(scenario: simulator.scenario.rawValue, frames: simulator.recentFrames)
            let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys]; encoder.dateEncodingStrategy = .iso8601
            return String(decoding: try encoder.encode(fixture), as: UTF8.self)
        case "flash_build_project":
            guard let base64 = a["payloadBase64"]?.string, let payload = Data(base64Encoded: base64), !payload.isEmpty else { throw MCPError.invalid("Pass a non-empty payloadBase64 value.") }
            guard payload.count <= 64 * 1024 * 1024 else { throw MCPError.invalid("Flash source files must be 64 MiB or smaller.") }
            let module = a["module"]?.string ?? "unassigned"
            let filename = a["filename"]?.string ?? "source.bin"
            let notes = a["notes"]?.string ?? ""
            let data = try FlashPackageBuilder.build(vehicle: profile, module: module, filename: filename, payload: payload, notes: notes)
            return String(decoding: data, as: UTF8.self)
        case "flash_validate_project":
            guard let raw = a["projectJSON"]?.string, let data = raw.data(using: .utf8),
                  let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let payload64 = object["payloadBase64"] as? String, let payload = Data(base64Encoded: payload64),
                  let expected = object["sha256"] as? String else { throw MCPError.invalid("Project JSON is missing a valid payloadBase64 or SHA-256.") }
            let actual = SHA256.hash(data: payload).map { String(format: "%02x", $0) }.joined()
            let format = object["format"] as? String ?? ""
            let version = object["formatVersion"] as? Int ?? 0
            let valid = format == "DieselCairn Flash Project" && version == 1 && actual.caseInsensitiveCompare(expected) == .orderedSame
            return json(["validProject": valid, "format": format, "formatVersion": version, "payloadBytes": payload.count, "sha256Matches": actual.caseInsensitiveCompare(expected) == .orderedSame, "execution": "PROJECT_ONLY; this server has no live ECM/TCM write tool."])
        case "flash_write_capability":
            return json(["available": false, "reason": "No authorized RE300 ECM/TCM programming transport, verified calibration, module identity, or recovery workflow is implemented. No live write command is exposed."])
        case "app_get_sections":
            return json(["sections": ["Overview", "Diagnostics", "Vehicle profile", "Flash Studio", "CAN / J1708 bench", "Virtual hardware", "Adapters"], "controlSurface": "DieselCairn domain MCP tools", "guiControl": false, "note": "The MCP server runs the same DieselCairn core simulator and profile logic; it does not remote-click a Mac or iPhone screen."])
        default: throw MCPError.invalid("Unknown DieselCairn tool: \(name)")
        }
    }

    private func configureSimulator(_ a: [String: JSONValue]) throws {
        if let raw = a["scenario"]?.string { guard let value = SimulatorScenario(rawValue: raw) else { throw MCPError.invalid("Unknown simulator scenario.") }; simulator.scenario = value }
        if let raw = a["adapter"]?.string { guard let value = VirtualAdapterDevice(rawValue: raw) else { throw MCPError.invalid("Unknown virtual adapter profile.") }; simulator.selectAdapter(value) }
        if let n = a["bitrate"]?.number { guard let value = SimulatedCANBitrate(rawValue: Int(n)) else { throw MCPError.invalid("Unsupported bitrate; use 125000, 250000, 500000, or 1000000.") }; simulator.bitrate = value }
        if let n = a["busBitrate"]?.number { guard let value = SimulatedCANBitrate(rawValue: Int(n)) else { throw MCPError.invalid("Unsupported bus bitrate.") }; simulator.busBitrate = value }
        if let n = a["busLoad"]?.number { guard (0...100).contains(n) else { throw MCPError.invalid("busLoad must be between 0 and 100 percent.") }; simulator.simulatedBusLoad = n }
        if let n = a["supplyVoltage"]?.number { guard (0...24).contains(n) else { throw MCPError.invalid("supplyVoltage must be between 0 and 24 volts.") }; simulator.simulatedSupplyVoltage = n }
        setBool(a, "ecuOnline", to: &simulator.ecuNodeOnline)
        setBool(a, "tcmOnline", to: &simulator.tcmNodeOnline)
        setBool(a, "mcuPowered", to: &simulator.adapterMCUPowered)
        setBool(a, "controllerPowered", to: &simulator.canControllerPowered)
        setBool(a, "transceiverConnected", to: &simulator.transceiverConnected)
        setBool(a, "firmwareRunning", to: &simulator.adapterFirmwareRunning)
        setBool(a, "j1708TransceiverConnected", to: &simulator.j1708TransceiverConnected)
        setBool(a, "j1587NodeOnline", to: &simulator.j1587SimulatorNodeOnline)
        setBool(a, "injectJ1708Collision", to: &simulator.injectJ1708Collision)
        setBool(a, "termination", to: &simulator.terminationEnabled)
        setBool(a, "injectTransportErrors", to: &simulator.injectTransportErrors)
        setBool(a, "injectDemoFault", to: &simulator.injectDemoFault)
        if let n = a["gear"]?.number { guard (1...6).contains(Int(n)) else { throw MCPError.invalid("Virtual gear must be 1 through 6.") }; simulator.simulatedGear = Int(n) }
        if let n = a["j1708IdleBits"]?.number { guard (0...20).contains(Int(n)) else { throw MCPError.invalid("j1708IdleBits must be 0 through 20.") }; simulator.simulatedJ1708IdleBits = Int(n) }
        if let n = a["j1708Priority"]?.number { guard (1...8).contains(Int(n)) else { throw MCPError.invalid("j1708Priority must be 1 through 8.") }; simulator.simulatedJ1708Priority = UInt8(n) }
    }

    private func setBool(_ args: [String: JSONValue], _ key: String, to value: inout Bool) { if let v = args[key]?.bool { value = v } }

    private func updateProfile(_ fields: [String: JSONValue]) throws {
        for (key, value) in fields {
            guard let text = value.string else { throw MCPError.invalid("Vehicle profile fields must be strings.") }
            switch key {
            case "vin": profile.vin = text
            case "year": profile.year = text
            case "make": profile.make = text
            case "model": profile.model = text
            case "vinDecodedModel": profile.vinDecodedModel = text
            case "vinReportedModel": profile.vinReportedModel = text
            case "vinDecodedSeries": profile.vinDecodedSeries = text
            case "vinTransmissionStyle": profile.vinTransmissionStyle = text
            case "engine": profile.engine = text
            case "engineSerial": profile.engineSerial = text
            case "engineECMSerial": profile.engineECMSerial = text
            case "engineCalibrationID": profile.engineCalibrationID = text
            case "transmissionSeries": profile.transmissionSeries = text
            case "transmissionModel": profile.transmissionModel = text
            case "transmissionSerial": profile.transmissionSerial = text
            case "tcmSerial": profile.tcmSerial = text
            case "transmissionCalibrationID": profile.transmissionCalibrationID = text
            case "notes": profile.notes = text
            default: throw MCPError.invalid("Unsupported vehicle profile property: \(key)")
            }
        }
    }

    private func simulatorState() -> [String: Any] {
        [
            "connected": simulator.virtualAdapterConnected, "running": simulator.isRunning,
            "scenario": simulator.scenario.rawValue, "adapter": simulator.selectedAdapter.rawValue,
            "busBitrate": simulator.busBitrate.rawValue, "adapterBitrate": simulator.bitrate.rawValue,
            "busLoadPercent": simulator.simulatedBusLoad, "supplyVoltage": simulator.simulatedSupplyVoltage,
            "termination": simulator.terminationEnabled, "ecuOnline": simulator.ecuNodeOnline,
            "tcmOnline": simulator.tcmNodeOnline, "gear": simulator.selectedGear as Any? ?? NSNull(),
            "j1708TransceiverConnected": simulator.j1708TransceiverConnected,
            "j1587NodeOnline": simulator.j1587SimulatorNodeOnline,
            "injectJ1708Collision": simulator.injectJ1708Collision,
            "range": simulator.selectedRange as Any? ?? NSNull(), "framesReceived": simulator.framesReceived,
            "adapterFramesReceived": simulator.adapterFramesReceived, "adapterFramesSent": simulator.adapterFramesSent,
            "transportErrors": simulator.transportErrors, "replayMode": simulator.isReplayMode,
            "j1708Baud": J1708Timing.baudRate, "j1708IdleHighBits": simulator.simulatedJ1708IdleBits,
            "j1708PriorityClass": simulator.simulatedJ1708Priority,
            "j1587Messages": simulator.recentJ1587Messages.map { ["mid": String(format: "%02X", $0.mid), "bytes": $0.bytes.map { String(format: "%02X", $0) }.joined(separator: " "), "timestamp": ISO8601DateFormatter().string(from: $0.timestamp)] },
            "readings": simulator.readings.values.sorted { $0.parameter.rawValue < $1.parameter.rawValue }.map { [
                "parameter": $0.parameter.rawValue, "value": $0.value, "unit": $0.parameter.unit,
                "source": $0.source.rawValue, "timestamp": ISO8601DateFormatter().string(from: $0.timestamp)
            ] as [String: Any] },
            "faults": simulator.faults.map { ["code": $0.code, "module": $0.module, "description": $0.description, "active": $0.isActive] as [String: Any] },
            "frames": simulator.recentFrames.map(frameObject)
        ]
    }

    private func frameObject(_ frame: J1939Frame) -> [String: Any] {
        ["identifier": String(format: "%08X", frame.identifier), "pgn": String(format: "%05X", frame.pgn),
         "priority": frame.priority, "sourceAddress": String(format: "%02X", frame.sourceAddress),
         "payload": frame.payload.map { String(format: "%02X", $0) }.joined(separator: " "),
         "timestamp": ISO8601DateFormatter().string(from: frame.timestamp)]
    }

    private func uint32(_ value: JSONValue?, field: String) throws -> UInt32 {
        guard let value else { throw MCPError.invalid("Missing \(field).") }
        if let n = value.number, n >= 0, n <= Double(UInt32.max) { return UInt32(n) }
        if let s = value.string {
            let trimmed = s.hasPrefix("0x") ? String(s.dropFirst(2)) : s
            if let n = UInt32(trimmed, radix: 16) { return n }
            if let n = UInt32(trimmed) { return n }
        }
        throw MCPError.invalid("\(field) must be an unsigned integer or hexadecimal string.")
    }

    private func bytePayload(_ value: JSONValue?) throws -> [UInt8] {
        guard let value else { throw MCPError.invalid("Missing payload byte array or space-separated hex string.") }
        if let arr = value.array {
            let bytes = try arr.map { item -> UInt8 in
                guard let n = item.number, (0...255).contains(n) else { throw MCPError.invalid("Payload array values must be bytes (0-255).") }
                return UInt8(n)
            }
            guard bytes.count <= 8 else { throw MCPError.invalid("Classic CAN payload cannot exceed 8 bytes.") }
            return bytes
        }
        if let raw = value.string {
            let parts = raw.split(whereSeparator: { $0 == " " || $0 == "," || $0 == ":" })
            let bytes = try parts.map { part -> UInt8 in
                guard let byte = UInt8(part, radix: 16) else { throw MCPError.invalid("Payload must be space-separated hexadecimal bytes.") }
                return byte
            }
            guard bytes.count <= 8 else { throw MCPError.invalid("Classic CAN payload cannot exceed 8 bytes.") }
            return bytes
        }
        throw MCPError.invalid("Payload must be an array of bytes or a hexadecimal string.")
    }

    private func j1587Payload(_ value: JSONValue?) throws -> [UInt8] {
        guard let value else { throw MCPError.invalid("Pass J1587 PID/data bytes as an array or hex string.") }
        let tokens: [String]
        if let array = value.array {
            let bytes = try array.map { item -> UInt8 in
                guard let number = item.number, (0...255).contains(number) else { throw MCPError.invalid("J1587 values must be bytes (0-255).") }
                return UInt8(number)
            }
            guard bytes.count <= 19 else { throw MCPError.invalid("J1587 PID/data is limited to 19 bytes in this fixture profile.") }
            return bytes
        } else if let string = value.string {
            tokens = string.split(whereSeparator: { $0.isWhitespace || $0 == "," || $0 == ":" }).map(String.init)
        } else { throw MCPError.invalid("J1587 payload must be a byte array or hex string.") }
        guard tokens.count <= 19 else { throw MCPError.invalid("J1587 PID/data is limited to 19 bytes in this fixture profile.") }
        return try tokens.map { token in
            guard let byte = UInt8(token.hasPrefix("0x") ? String(token.dropFirst(2)) : token, radix: 16) else { throw MCPError.invalid("J1587 payload must contain hexadecimal bytes.") }
            return byte
        }
    }

    private func json<T: Encodable>(_ value: T) -> String { (try? String(decoding: JSONEncoder().encode(value), as: UTF8.self)) ?? "{}" }
    private func json(_ value: [String: Any]) -> String {
        guard JSONSerialization.isValidJSONObject(value),
              let data = try? JSONSerialization.data(withJSONObject: value, options: [.sortedKeys]) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }
    private func jsonObject<T: Encodable>(_ value: T) throws -> Any { try JSONSerialization.jsonObject(with: JSONEncoder().encode(value)) }

    private static func tool(_ name: String, _ description: String, _ properties: [String: Any] = [:], _ required: [String] = []) -> [String: Any] {
        ["name": name, "description": description, "inputSchema": ["type": "object", "properties": properties, "required": required, "additionalProperties": false]]
    }
    private static let toolDefinitions: [[String: Any]] = [
        tool("app_get_sections", "List app areas and MCP control scope."),
        tool("vehicle_get_profile", "Read the agent-side RE300/PB305 vehicle record."),
        tool("vehicle_update_profile", "Update the local MCP vehicle record; no device is contacted.", ["fields": ["type": "object", "description": "Only explicitly supplied string fields are changed."]], ["fields"]),
        tool("vehicle_decode_vin", "Decode a supplied VIN with NHTSA vPIC over HTTPS. VIN is sent to NHTSA only when this tool is called; mismatch preserves owner-confirmed identity.", ["vin": ["type": "string"], "modelYear": ["type": "string"]]),
        tool("simulator_get_state", "Read virtual CAN readings, faults, frames, nodes and transport counters."),
        tool("diagnostics_get_state", "Read diagnostic values and active synthetic faults from the isolated virtual bench."),
        tool("simulator_connect", "Start the isolated in-process virtual CAN session and generate protocol frames.", ["scenario": ["type": "string", "enum": SimulatorScenario.allCases.map(\.rawValue)]]),
        tool("simulator_stop", "Stop the virtual session and clear session readings/faults."),
        tool("simulator_reset", "Reset virtual session, frames and counters."),
        tool("simulator_set_controls", "Configure the virtual bus and ECU/TCM nodes. Only software simulator state is changed.", [
            "scenario": ["type": "string", "enum": SimulatorScenario.allCases.map(\.rawValue)],
            "adapter": ["type": "string", "enum": VirtualAdapterDevice.allCases.map(\.rawValue)],
            "bitrate": ["type": "integer", "enum": SimulatedCANBitrate.allCases.map(\.rawValue)],
            "busBitrate": ["type": "integer", "enum": SimulatedCANBitrate.allCases.map(\.rawValue)],
            "busLoad": ["type": "number", "minimum": 0, "maximum": 100], "supplyVoltage": ["type": "number", "minimum": 0, "maximum": 24],
            "termination": ["type": "boolean"], "ecuOnline": ["type": "boolean"], "tcmOnline": ["type": "boolean"],
            "mcuPowered": ["type": "boolean"], "controllerPowered": ["type": "boolean"], "transceiverConnected": ["type": "boolean"],
            "firmwareRunning": ["type": "boolean"], "injectTransportErrors": ["type": "boolean"],
            "j1708TransceiverConnected": ["type": "boolean"], "j1587NodeOnline": ["type": "boolean"], "injectJ1708Collision": ["type": "boolean"],
            "injectDemoFault": ["type": "boolean"], "gear": ["type": "integer", "minimum": 1, "maximum": 6],
            "j1708IdleBits": ["type": "integer", "minimum": 0, "maximum": 20], "j1708Priority": ["type": "integer", "minimum": 1, "maximum": 8]
        ]),
        tool("virtual_hardware_configure", "Alias for simulator_set_controls, corresponding to the Virtual hardware screen."),
        tool("simulator_inject_fault", "Enable or clear the virtual ECU's synthetic DM1 fault on the isolated bus.", ["enabled": ["type": "boolean"]]),
        tool("simulator_send_frame", "Inject a classic-CAN J1939 frame through the virtual adapter protocol and app decoder.", ["pgn": ["oneOf": [["type": "integer"], ["type": "string"]]], "sourceAddress": ["type": "integer", "minimum": 0, "maximum": 255], "priority": ["type": "integer", "minimum": 0, "maximum": 7], "payload": ["oneOf": [["type": "array", "items": ["type": "integer", "minimum": 0, "maximum": 255], "maxItems": 8], ["type": "string"]]]], ["pgn", "sourceAddress", "priority", "payload"]),
        tool("simulator_send_j1587", "Send a checksum-valid synthetic J1587 message over the isolated virtual J1708 model; this is not physical bus output.", ["mid": ["type": "integer", "minimum": 0, "maximum": 255], "data": ["oneOf": [["type": "array", "items": ["type": "integer", "minimum": 0, "maximum": 255], "maxItems": 19], ["type": "string"]]]], ["mid", "data"]),
        tool("simulator_load_replay", "Replay frames through the virtual adapter path; frames must contain identifier and payload.", ["frames": ["type": "array", "items": ["type": "object"]]], ["frames"]),
        tool("simulator_export_trace", "Return a JSON DieselCairn CAN Trace v1 fixture for the current virtual session."),
        tool("flash_build_project", "Build a non-executable, project-only flash manifest from a supplied base64 file. No ECU/TCM programming occurs.", ["module": ["type": "string"], "filename": ["type": "string"], "payloadBase64": ["type": "string"], "notes": ["type": "string"]], ["payloadBase64"]),
        tool("flash_validate_project", "Validate project format and payload SHA-256; this does not validate OEM calibration compatibility or write to a module.", ["projectJSON": ["type": "string"]], ["projectJSON"]),
        tool("flash_write_capability", "Report whether live module programming is implemented and its required evidence."),
    ]
}

private enum MCPError: LocalizedError {
    case invalid(String)
    var errorDescription: String? {
        if case .invalid(let text) = self { return text }
        return nil
    }
}

@MainActor
private final class MCPFrameParser {
    private var data = Data()
    func append(_ incoming: Data) {
        data.append(incoming)
        while let headerEnd = data.range(of: Data("\r\n\r\n".utf8)) {
            let header = String(decoding: data[..<headerEnd.lowerBound], as: UTF8.self)
            guard let line = header.components(separatedBy: "\r\n").first(where: { $0.lowercased().hasPrefix("content-length:") }),
                  let length = Int(line.components(separatedBy: ":").last?.trimmingCharacters(in: .whitespaces) ?? ""), length >= 0 else {
                data.removeSubrange(..<headerEnd.upperBound); continue
            }
            let bodyStart = headerEnd.upperBound
            guard data.count >= bodyStart + length else { return }
            let body = data.subdata(in: bodyStart..<(bodyStart + length))
            data.removeSubrange(..<(bodyStart + length))
            if let owner = MCPRuntime.shared { owner.receive(body) }
        }
    }
}

private final class MCPStdout {
    private let lock = NSLock()
    func send(_ object: [String: Any]) {
        guard let body = try? JSONSerialization.data(withJSONObject: object, options: [.fragmentsAllowed]) else { return }
        lock.lock(); defer { lock.unlock() }
        FileHandle.standardOutput.write(Data("Content-Length: \(body.count)\r\n\r\n".utf8))
        FileHandle.standardOutput.write(body)
    }
}

@MainActor
private enum MCPRuntime { static weak var shared: DieselCairnMCPServer? }

@main
private struct Main {
    @MainActor static func main() {
        let server = DieselCairnMCPServer()
        MCPRuntime.shared = server
        server.start()
        RunLoop.main.run()
    }
}
