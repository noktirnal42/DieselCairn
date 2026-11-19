import Foundation
import Combine

public enum AdapterPath: String, CaseIterable, Identifiable {
    case stm32 = "STM32 serial adapter"
    case arduino = "Arduino USB adapter"
    case ft232h = "FT232H + MCP2515"
    case ble = "BLE CAN gateway"
    public var id: String { rawValue }
}

public enum ConnectionState: Equatable {
    case disconnected
    case simulated
    case connecting
    case connected(adapter: String)
    case failed(String)
}

/// Connection state keeps the simulator explicit and never reports a stub as a real vehicle link.
@MainActor
public final class ConnectionManager: ObservableObject {
    @Published public private(set) var state: ConnectionState = .disconnected
    public let simulator = DiagnosticSimulator()

    public init() {}
    public func selectSimulator() { simulator.startVirtualSession(); state = .simulated }
    public func connect(adapter: AdapterPath) {
        state = .failed("\(adapter.rawValue) transport is not yet implemented. The RE300 live-bus profile remains in hardware validation.")
    }
    public func disconnect() { simulator.stopVirtualSession(); state = .disconnected }
}
