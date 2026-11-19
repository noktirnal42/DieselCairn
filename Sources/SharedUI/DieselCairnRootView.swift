import SwiftUI
import Combine
import CryptoKit
import UniformTypeIdentifiers
import iScanCore
import iScanModels

private enum AppPage: String, CaseIterable, Identifiable {
    case overview = "Overview"
    case diagnostics = "Diagnostics"
    case vehicle = "Vehicle profile"
    case flash = "Flash Studio"
    case bench = "CAN / J1708 bench"
    case hardware = "Virtual hardware"
    case adapters = "Adapters"
    var id: String { rawValue }
    var icon: String {
        switch self {
        case .overview: "gauge.with.needle"
        case .diagnostics: "waveform.path.ecg.rectangle"
        case .vehicle: "bus"
        case .flash: "externaldrive.badge.exclamationmark"
        case .bench: "point.3.connected.trianglepath.dotted"
        case .hardware: "cpu"
        case .adapters: "cable.connector"
        }
    }
}

@MainActor
public struct DieselCairnRootView: View {
    private let simulationTimer = Timer.publish(every: 0.05, on: .main, in: .common).autoconnect()
    @StateObject private var connection = ConnectionManager()
    @State private var selection: AppPage? = .overview
    @State private var profile = VehicleProfile()
    @AppStorage("dieselcairn.vehicleProfile") private var storedProfile = ""
    @State private var profileLoaded = false

    public init() {}

    public var body: some View {
        Group {
#if os(iOS)
        NavigationStack {
            pageContent(.overview)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            ForEach(AppPage.allCases) { page in
                                NavigationLink(value: page) { Label(page.rawValue, systemImage: page.icon) }
                            }
                        } label: {
                            Label("Sections", systemImage: "line.3.horizontal")
                                .labelStyle(.iconOnly)
                        }
                        .accessibilityLabel("Choose service section")
                    }
                }
                .navigationDestination(for: AppPage.self) { pageContent($0) }
                .background(DieselCairnBrand.ink.ignoresSafeArea())
        }
#else
        NavigationSplitView {
            List {
                ForEach(AppPage.allCases) { page in
                    Button {
                        selection = page
                    } label: {
                        Label(page.rawValue, systemImage: page.icon)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(selection == page ? Color.white.opacity(0.10) : Color.clear)
                    .accessibilityAddTraits(selection == page ? .isSelected : [])
                }
            }
            .listStyle(.sidebar)
            .safeAreaInset(edge: .top) {
                HStack(spacing: 10) {
                    BrandMark(size: 34)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("DieselCairn").font(.system(size: 15, weight: .semibold))
                        Text("RE300 DIAGNOSTICS").font(.system(size: 9, weight: .semibold, design: .monospaced)).tracking(0.8).foregroundStyle(DieselCairnBrand.muted)
                    }
                    Spacer(minLength: 0)
                }.padding(.horizontal, 14).padding(.vertical, 10)
            }
            .navigationSplitViewColumnWidth(min: 210, ideal: 230)
        } detail: {
            pageContent(selection ?? .overview)
        }
#endif
        }
        .preferredColorScheme(.dark)
        .tint(DieselCairnBrand.accent)
        .onReceive(simulationTimer) { _ in connection.simulator.advance() }
        .onAppear {
            guard !profileLoaded else { return }
            if let data = storedProfile.data(using: .utf8), let saved = try? JSONDecoder().decode(VehicleProfile.self, from: data) {
                var restored = saved
                restored.normalizeLegacyIdentity()
                profile = restored
            }
            profileLoaded = true
        }
        .onChange(of: profile) { updated in persistProfile(updated) }
    }

    @ViewBuilder
    private func pageContent(_ page: AppPage) -> some View {
        switch page {
        case .overview: OverviewView(connection: connection, profile: profile)
        case .diagnostics: DiagnosticsView(connection: connection)
        case .vehicle: VehicleProfileView(profile: $profile)
        case .flash: FlashStudioView(profile: profile)
        case .bench: BenchSimulatorView(sim: connection.simulator)
        case .hardware: VirtualHardwareView(sim: connection.simulator)
        case .adapters: AdapterView(connection: connection)
        }
    }

    private func persistProfile(_ updated: VehicleProfile) {
        if let data = try? JSONEncoder().encode(updated), let json = String(data: data, encoding: .utf8) {
            storedProfile = json
        }
    }

}

private struct OverviewView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @ObservedObject var connection: ConnectionManager
    let profile: VehicleProfile
    private var sim: DiagnosticSimulator { connection.simulator }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if horizontalSizeClass == .compact {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            SectionEyebrow(text: "VEHICLE / RE300")
                            Spacer()
                            StatusPill(text: sim.virtualAdapterConnected ? "VIRTUAL LINK" : "DISCONNECTED", color: sim.virtualAdapterConnected ? DieselCairnBrand.success : DieselCairnBrand.muted)
                        }
                        Text(profile.displayTitle)
                            .font(.system(size: 24, weight: .semibold, design: .default))
                            .lineLimit(2).minimumScaleFactor(0.82)
                        Text("PB305 SCHOOL BUS  ·  MAXXFORCE DT  ·  ALLISON 3000PTS")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundStyle(DieselCairnBrand.muted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.78)
                        Text(sim.virtualAdapterConnected ? "Virtual \(sim.selectedAdapter.rawValue) · isolated" : "No adapter or simulator connected")
                            .font(.caption2).foregroundStyle(DieselCairnBrand.muted)
                    }
                    .padding(.top, 8)
                } else {
                    HStack(alignment: .center, spacing: 14) {
                        VStack(alignment: .leading, spacing: 5) {
                            SectionEyebrow(text: "VEHICLE / RE300 · PB305")
                            Text(profile.displayTitle)
                                .font(.system(size: 25, weight: .semibold, design: .default))
                            Text("PB305 school bus   ·   MaxxForce DT   ·   Allison 3000PTS")
                                .font(.subheadline).foregroundStyle(DieselCairnBrand.muted)
                        }
                        Spacer(minLength: 12)
                        VStack(alignment: .trailing, spacing: 6) {
                            StatusPill(text: sim.virtualAdapterConnected ? "VIRTUAL LINK" : "DISCONNECTED", color: sim.virtualAdapterConnected ? DieselCairnBrand.success : DieselCairnBrand.muted)
                            Text(sim.virtualAdapterConnected ? "Virtual \(sim.selectedAdapter.rawValue) · isolated" : "No adapter or simulator connected").font(.caption2).foregroundStyle(DieselCairnBrand.muted)
                        }
                    }
                    .padding(.top, 8)
                }

                SurfaceCard {
                    if horizontalSizeClass == .compact {
                        VStack(alignment: .leading, spacing: 9) {
                            SectionEyebrow(text: "ENGINE SPEED")
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text(sim.readings[.engineSpeed].map { Int($0.value).formatted() } ?? "—")
                                    .font(.system(size: 38, weight: .medium, design: .monospaced)).monospacedDigit()
                                Text("rpm").font(.subheadline).foregroundStyle(DieselCairnBrand.muted)
                                Spacer(minLength: 4)
                                Button { sim.toggleRunning() } label: {
                                    Label(sim.isRunning ? "Stop" : "Connect virtual", systemImage: sim.isRunning ? "stop.fill" : "play.fill")
                                }
                                .buttonStyle(.bordered).controlSize(.small).tint(DieselCairnBrand.accent)
                            }
                            Text(sim.readings[.engineSpeed].map { "SPN 190  ·  \($0.source.rawValue)" } ?? "No engine data")
                                .font(.system(size: 11, design: .monospaced)).foregroundStyle(DieselCairnBrand.muted)
                            VStack(alignment: .leading, spacing: 5) {
                                SectionEyebrow(text: "SESSION")
                                Text(sim.virtualAdapterConnected ? "Virtual adapter session" : "Waiting for connection").font(.subheadline.weight(.medium))
                            }.padding(.top, 3)
                        }
                    } else {
                        HStack(alignment: .center, spacing: 18) {
                            VStack(alignment: .leading, spacing: 8) {
                                SectionEyebrow(text: "ENGINE SPEED")
                                HStack(alignment: .firstTextBaseline, spacing: 8) {
                                    Text(sim.readings[.engineSpeed].map { Int($0.value).formatted() } ?? "—")
                                        .font(.system(size: 42, weight: .medium, design: .monospaced)).monospacedDigit()
                                    Text("rpm").font(.subheadline).foregroundStyle(DieselCairnBrand.muted)
                                }
                                Text(sim.readings[.engineSpeed].map { "SPN 190  ·  \($0.source.rawValue)" } ?? "No engine data")
                                    .font(.system(size: 11, design: .monospaced)).foregroundStyle(DieselCairnBrand.muted)
                            }
                            Spacer(minLength: 12)
                            Rectangle().fill(DieselCairnBrand.border).frame(width: 1, height: 58)
                            VStack(alignment: .leading, spacing: 7) {
                                SectionEyebrow(text: "SESSION")
                                Text(sim.virtualAdapterConnected ? "Virtual adapter session" : "Waiting for connection").font(.subheadline.weight(.medium))
                                Button { sim.toggleRunning() } label: {
                                    Label(sim.isRunning ? "Stop virtual link" : "Connect virtual", systemImage: sim.isRunning ? "stop.fill" : "play.fill")
                                }
                                .buttonStyle(.bordered).controlSize(.small).tint(DieselCairnBrand.accent)
                            }
                        }
                    }
                }

                SurfaceCard {
                    HStack {
                        SectionEyebrow(text: "ENGINE DATA")
                        Spacer()
                        Text("\(sim.framesReceived) DECODED  ·  \(sim.virtualAdapterConnected ? "VIRTUAL" : "IDLE")")
                            .font(.system(size: 10, weight: .medium, design: .monospaced)).foregroundStyle(DieselCairnBrand.muted)
                    }.padding(.bottom, 8)
                    HStack {
                        Text("PARAMETER")
                        Spacer()
                        Text("VALUE").frame(width: 132, alignment: .trailing)
                        Text("UNIT").frame(width: 62, alignment: .leading)
                    }
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundStyle(DieselCairnBrand.muted)
                    .padding(.vertical, 7)
                    Divider().overlay(DieselCairnBrand.border)
                    ForEach(RE300Parameter.allCases) { parameter in
                        let reading = sim.readings[parameter]
                        HStack(spacing: 8) {
                            Text(parameter.rawValue).font(.subheadline)
                            Spacer(minLength: 10)
                            Text(reading.map { $0.value.formatted(.number.precision(.fractionLength(0...1))) } ?? "—")
                                .font(.system(size: 13, weight: .medium, design: .monospaced)).monospacedDigit()
                                .frame(width: 132, alignment: .trailing)
                            Text(parameter.unit).font(.system(size: 11, design: .monospaced)).foregroundStyle(DieselCairnBrand.muted)
                                .frame(width: 62, alignment: .leading)
                        }
                        .padding(.vertical, 8)
                        if parameter != RE300Parameter.allCases.last { Divider().overlay(DieselCairnBrand.border) }
                    }
                }

                HStack(alignment: .top, spacing: 12) {
                    SurfaceCard {
                        SectionEyebrow(text: "TRANSMISSION · TCM")
                        Text(sim.virtualAdapterConnected && sim.selectedGear != nil ? "Gear \(sim.selectedGear!) · \(sim.selectedRange ?? "Range unavailable")" : "No TCM data").font(.title3.weight(.semibold)).padding(.top, 10)
                        Text(sim.virtualAdapterConnected ? "Virtual J1939 ETC2 status · generic profile" : "Transmission status remains blank until a virtual or physical TCM message is received.")
                            .font(.caption).foregroundStyle(DieselCairnBrand.muted).padding(.top, 4)
                    }
                    SurfaceCard {
                        SectionEyebrow(text: "FAULT SUMMARY")
                        HStack(spacing: 9) {
                            Circle().fill(sim.virtualAdapterConnected ? DieselCairnBrand.success : DieselCairnBrand.muted).frame(width: 8, height: 8)
                            Text(sim.virtualAdapterConnected ? (sim.faults.isEmpty ? "No active faults reported" : "\(sim.faults.count) active fault(s)") : "Fault status unavailable").font(.subheadline.weight(.medium))
                        }.padding(.top, 12)
                        Text(sim.virtualAdapterConnected ? "Virtual adapter · simulated frame stream" : "ECM / TCM not connected")
                            .font(.caption).foregroundStyle(DieselCairnBrand.muted).padding(.top, 3)
                    }
                }
                HStack {
                    Text(sim.virtualAdapterConnected ? "Last virtual frame  \(sim.lastUpdate.formatted(date: .omitted, time: .standard))" : "No data received")
                    Spacer()
                    Text("No live vehicle data").fontWeight(.medium)
                }.font(.system(size: 10, design: .monospaced)).foregroundStyle(DieselCairnBrand.muted)
            }
            .padding(20)
            .frame(maxWidth: 1040)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle("Overview")
    }
}

private struct DiagnosticsView: View {
    @ObservedObject var connection: ConnectionManager
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionEyebrow(text: "Engine · ECM · Transmission · TCM")
                SurfaceCard {
                    HStack(spacing: 12) {
                        Image(systemName: "info.circle.fill").font(.title2).foregroundStyle(DieselCairnBrand.accent)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(connection.simulator.virtualAdapterConnected ? "Virtual adapter session" : "No active session").font(.headline)
                            Text("Live ECM/TCM identification, DM1 fault retrieval, and freeze-frame records will appear when a validated adapter profile is connected.").font(.subheadline).foregroundStyle(.white.opacity(0.62))
                        }
                    }
                }
                SurfaceCard {
                    HStack { Text("Active fault codes").font(.headline); Spacer(); StatusPill(text: connection.simulator.virtualAdapterConnected ? "\(connection.simulator.faults.count) VIRTUAL" : "NO LINK", color: connection.simulator.virtualAdapterConnected ? DieselCairnBrand.success : DieselCairnBrand.muted) }
                    Divider().overlay(.white.opacity(0.1)).padding(.vertical, 10)
                    VStack(spacing: 9) {
                        Image(systemName: "checkmark.seal").font(.system(size: 28)).foregroundStyle(DieselCairnBrand.success)
                        if !connection.simulator.virtualAdapterConnected {
                            Text("Not connected").font(.headline)
                            Text("Connect a virtual ECU or validated physical adapter to retrieve module faults.").font(.caption).foregroundStyle(.white.opacity(0.55))
                        } else if connection.simulator.faults.isEmpty {
                            Text("No active faults reported").font(.headline)
                            Text("The virtual ECU did not report active DM1 faults in received frames.").font(.caption).foregroundStyle(.white.opacity(0.55))
                        } else {
                            ForEach(connection.simulator.faults) { fault in
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(fault.code).font(.headline)
                                    Text("\(fault.module) · \(fault.description)").font(.caption).foregroundStyle(.white.opacity(0.55))
                                }.frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }.frame(maxWidth: .infinity, minHeight: 150)
                }
                SurfaceCard {
                    SectionEyebrow(text: "Current data stream")
                    ForEach(RE300Parameter.allCases) { parameter in
                        HStack {
                            Text(parameter.rawValue)
                            Spacer()
                            if connection.simulator.virtualAdapterConnected, let reading = connection.simulator.readings[parameter] {
                                Text("\(reading.value.formatted(.number.precision(.fractionLength(0...1)))) \(parameter.unit)").monospacedDigit().foregroundStyle(.white.opacity(0.75))
                            }
                        }.font(.subheadline).padding(.vertical, 9)
                        if parameter != RE300Parameter.allCases.last { Divider().overlay(.white.opacity(0.08)) }
                    }
                }
            }.padding(26).frame(maxWidth: 900).frame(maxWidth: .infinity, alignment: .leading)
        }.navigationTitle("Diagnostics")
    }
}

private struct VehicleProfileView: View {
    @Binding var profile: VehicleProfile
    @State private var decoding = false
    @State private var decodeMessage: String?
    @State private var decodeSucceeded = false
    @State private var confirmVINSend = false

    var body: some View {
        Form {
            Section {
                HStack {
                    BrandMark(size: 40)
                    VStack(alignment: .leading) { Text("RE300 · PB305 school bus").font(.headline); Text("Saved locally on this device").font(.caption).foregroundStyle(.secondary) }
                }.padding(.vertical, 6)
            }
            Section("Vehicle identity") {
                TextField("VIN", text: $profile.vin).textCase(.uppercase).autocorrectionDisabled()
                HStack {
                    Button { confirmVINSend = true } label: {
                        if decoding { ProgressView().controlSize(.small) } else { Label("Decode VIN", systemImage: "barcode.viewfinder") }
                    }.disabled(decoding || profile.vin.count < 11).confirmationDialog("Send VIN to NHTSA vPIC?", isPresented: $confirmVINSend, titleVisibility: .visible) {
                        Button("Send VIN and decode") { Task { await decodeVIN() } }
                        Button("Cancel", role: .cancel) { }
                    } message: {
                        Text("DieselCairn will send this VIN and model year to the public NHTSA VIN decoder over HTTPS. The result only fills basic vehicle details; module IDs and calibrations still need to be verified.")
                    }
                    if let decodeMessage { Text(decodeMessage).font(.caption).foregroundStyle(decodeSucceeded ? DieselCairnBrand.success : DieselCairnBrand.accent) }
                }
                TextField("Model year", text: $profile.year)
                TextField("Make", text: $profile.make)
                TextField("Model", text: $profile.model)
                TextField("Owner / factory-confirmed model number", text: $profile.vinDecodedModel)
                TextField("NHTSA-reported model code", text: $profile.vinReportedModel)
                TextField("NHTSA series", text: $profile.vinDecodedSeries)
                TextField("NHTSA transmission style", text: $profile.vinTransmissionStyle)
                TextField("Engine", text: $profile.engine)
                Text("RE300 is the rear-engine series badge; PB305 is the school-bus model number. VIN positions 4–5 and the factory label can confirm it.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Engine / ECM identifiers") {
                TextField("Engine serial number", text: $profile.engineSerial)
                TextField("ECM serial / part number", text: $profile.engineECMSerial)
                TextField("ECM calibration ID / code", text: $profile.engineCalibrationID)
            }
            Section("Transmission / TCM identifiers") {
                TextField("Allison series (owner-reported; verify tag)", text: $profile.transmissionSeries)
                TextField("Transmission model (owner-reported; verify tag)", text: $profile.transmissionModel)
                Text("Owner reports an Allison 3000 Series 3000PTS. Confirm the transmission nameplate and TCM identity before selecting target-specific procedures or calibrations.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("Transmission serial number", text: $profile.transmissionSerial)
                TextField("TCM serial / part number", text: $profile.tcmSerial)
                TextField("TCM calibration ID / CIN", text: $profile.transmissionCalibrationID)
            }
            Section("Service notes") { TextEditor(text: $profile.notes).frame(minHeight: 100) }
            Section {
                Label("VIN decoding fills basic vehicle fields when NHTSA has submitted data. Verify every field against the vehicle labels and module reports before building a flash project.", systemImage: "checkmark.shield")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Decode source: \(profile.vinDecodeSource)").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .scrollContentBackground(.hidden).background(DieselCairnBrand.ink).navigationTitle("Vehicle profile")
    }

    @MainActor private func decodeVIN() async {
        decoding = true
        decodeSucceeded = false
        defer { decoding = false }
        do {
            let decoded = try await VINDecoder.decode(profile.vin, modelYear: Int(profile.year))
            let reportedModelCode = decoded.model.trimmingCharacters(in: .whitespacesAndNewlines)
            let confirmedModelCode = profile.vinDecodedModel.trimmingCharacters(in: .whitespacesAndNewlines)
            let modelCodeMismatch = !reportedModelCode.isEmpty && !confirmedModelCode.isEmpty &&
                reportedModelCode.caseInsensitiveCompare(confirmedModelCode) != .orderedSame
            if !reportedModelCode.isEmpty { profile.vinReportedModel = reportedModelCode }
            if modelCodeMismatch {
                profile.vinDecodeSource = "Owner-confirmed \(confirmedModelCode) retained; NHTSA reports \(reportedModelCode) · verify VIN and factory label · \(decoded.source)"
                decodeMessage = "Model-code mismatch: VIN reports \(reportedModelCode); retained \(confirmedModelCode). Verify VIN characters 4–5 and the factory label."
                decodeSucceeded = false
            } else {
                if !decoded.modelYear.isEmpty { profile.year = decoded.modelYear }
                if !decoded.make.isEmpty { profile.make = decoded.make }
                if !reportedModelCode.isEmpty { profile.vinDecodedModel = reportedModelCode }
                if !decoded.series.isEmpty { profile.vinDecodedSeries = decoded.series }
                if !decoded.transmissionStyle.isEmpty { profile.vinTransmissionStyle = decoded.transmissionStyle }
                if !decoded.engine.isEmpty { profile.engine = decoded.engine }
                profile.vinDecodeSource = decoded.source
                decodeMessage = "VIN fields updated · \([reportedModelCode, decoded.series].filter { !$0.isEmpty }.joined(separator: " / ")) · verify physical bus and module data"
                decodeSucceeded = true
            }
        } catch { decodeMessage = error.localizedDescription }
    }
}

private struct BenchSimulatorView: View {
    @ObservedObject var sim: DiagnosticSimulator
    @State private var showingTraceImporter = false
    @State private var showingTraceExporter = false
    @State private var traceDocument = FlashPackageDocument()
    @State private var traceError: String?
    @State private var manualPGN = "F005"
    @State private var manualSource = "04"
    @State private var manualPriority = "6"
    @State private var manualPayload = "FE FF FF FE 20 31 20 31"
    @State private var manualFrameStatus: String?
    @State private var manualFrameError = false
    @State private var manualMID = "80"
    @State private var manualJ1587Data = "10 2A"
    @State private var j1587Status: String?
    @State private var j1587StatusIsError = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        SectionEyebrow(text: "Software / firmware bench")
                        Text("Datalink simulator").font(.largeTitle.bold())
                        Text("Synthetic J1939 + J1587 traffic · isolated from the vehicle bus")
                            .font(.subheadline).foregroundStyle(DieselCairnBrand.success)
                    }
                    Spacer()
                    BrandMark(size: 46)
                }
                SurfaceCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Scenario").font(.headline)
                            Text("Start isolated virtual J1939 and J1708/J1587 links. Synthetic nodes emit through the virtual adapter transport before DieselCairn decodes them.").font(.caption).foregroundStyle(.white.opacity(0.58))
                        }
                        Spacer()
                        Button(sim.isRunning ? "Stop session" : "Start virtual session") { sim.toggleRunning() }.buttonStyle(.borderedProminent)
                        Button("Reset") { sim.reset() }.buttonStyle(.bordered)
                    }
                    Picker("Scenario", selection: $sim.scenario) {
                        ForEach(SimulatorScenario.allCases) { scenario in Text(scenario.rawValue).tag(scenario) }
                    }.pickerStyle(.segmented).padding(.top, 12)
                    Toggle("Virtual ECM transmits DM1 fault (SPN 110 · FMI 0)", isOn: $sim.injectDemoFault).tint(DieselCairnBrand.accent).padding(.top, 8)
                }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), alignment: .leading)], spacing: 12) {
                    BenchMetric(title: "Frames processed", value: sim.framesReceived.formatted())
                    BenchMetric(title: "Modeled rates", value: sim.isRunning ? "ECM 20 Hz · TCM 10 Hz" : "Stopped")
                    BenchMetric(title: "Active virtual faults", value: sim.virtualAdapterConnected ? sim.faults.count.formatted() : "—")
                    BenchMetric(title: "Adapter RX / TX", value: "\(sim.adapterFramesReceived) / \(sim.adapterFramesSent)")
                    BenchMetric(title: "Transport errors", value: sim.transportErrors.formatted())
                }
                SurfaceCard {
                    SectionEyebrow(text: "J1708 / J1587 VIRTUAL LINK")
                    Text("Software fixture · 9,600 baud · 8N1 · separate from J1939 CAN")
                        .font(.caption).foregroundStyle(.white.opacity(0.58)).padding(.top, 4)
                    Text("Build a J1587 message from MID and raw PID/data bytes. DieselCairn calculates the checksum and routes it through the adapter packet codec. This does not emulate electrical signaling or prove J1708 firmware timing.")
                        .font(.caption).foregroundStyle(.white.opacity(0.58)).padding(.top, 2)
                    HStack {
                        TextField("MID hex", text: $manualMID).textFieldStyle(.roundedBorder).frame(width: 110)
                        TextField("PID/data bytes (hex)", text: $manualJ1587Data).textFieldStyle(.roundedBorder)
                    }.padding(.top, 8)
                    Stepper("Idle-high bits: \(sim.simulatedJ1708IdleBits)", value: $sim.simulatedJ1708IdleBits, in: 0...20)
                    Stepper("Priority class: \(sim.simulatedJ1708Priority)", value: $sim.simulatedJ1708Priority, in: 1...8)
                    Button("Send J1587 message to virtual link") { transmitManualJ1587() }
                        .buttonStyle(.borderedProminent).disabled(!sim.virtualAdapterConnected)
                    if let j1587Status {
                        Text(j1587Status).font(.caption.monospaced()).foregroundStyle(j1587StatusIsError ? DieselCairnBrand.warning : DieselCairnBrand.success)
                    }
                    if let message = sim.recentJ1587Messages.first {
                        Text("Latest SIMULATOR message · MID \(String(format: "%02X", message.mid)) · \(message.bytes.map { String(format: "%02X", $0) }.joined(separator: " "))")
                            .font(.caption.monospaced()).textSelection(.enabled)
                    } else {
                        Text("No J1587 messages received.").font(.caption).foregroundStyle(.white.opacity(0.48))
                    }
                }
                SurfaceCard {
                    SectionEyebrow(text: "MANUAL FRAME INJECTION")
                    Text("Construct and send a classic-CAN J1939 frame onto the virtual bus. It will cross the virtual adapter codec before DieselCairn sees it.")
                        .font(.caption).foregroundStyle(.white.opacity(0.58)).padding(.top, 4)
                    HStack(spacing: 8) {
                        TextField("PGN hex", text: $manualPGN).textFieldStyle(.roundedBorder).frame(minWidth: 75)
                        TextField("SA hex", text: $manualSource).textFieldStyle(.roundedBorder).frame(width: 72)
                        TextField("Prio", text: $manualPriority).textFieldStyle(.roundedBorder).frame(width: 64)
                    }.padding(.top, 8)
                    TextField("Payload bytes (hex, space separated)", text: $manualPayload).textFieldStyle(.roundedBorder).font(.system(.body, design: .monospaced))
                    Button("Send frame to virtual bus") { transmitManualFrame() }
                        .buttonStyle(.borderedProminent).disabled(!sim.virtualAdapterConnected)
                    if let manualFrameStatus {
                        Text(manualFrameStatus).font(.caption.monospaced()).foregroundStyle(manualFrameError ? DieselCairnBrand.warning : DieselCairnBrand.success)
                    }
                }
                SurfaceCard {
                    HStack { SectionEyebrow(text: "Recent raw frames"); Spacer(); Text("29-bit J1939 · classic CAN").font(.caption2).foregroundStyle(.white.opacity(0.5)) }
                    HStack {
                        Button("Export trace") { exportTrace() }.buttonStyle(.bordered)
                        Button("Replay fixture…") { showingTraceImporter = true }.buttonStyle(.bordered)
                        if sim.isReplayMode { StatusPill(text: "REPLAY", color: DieselCairnBrand.accent) }
                    }.padding(.vertical, 7)
                    if let traceError { Text(traceError).font(.caption).foregroundStyle(DieselCairnBrand.accent) }
                    if sim.recentFrames.isEmpty {
                        Text("Run the scenario to create frames.").font(.subheadline).foregroundStyle(.white.opacity(0.55)).padding(.vertical, 24)
                    } else {
                        ForEach(Array(sim.recentFrames.prefix(24).enumerated()), id: \.offset) { _, frame in
                            HStack(spacing: 10) {
                                Text(String(format: "%08X", frame.identifier)).font(.system(size: 11, weight: .semibold, design: .monospaced)).foregroundStyle(DieselCairnBrand.success).frame(width: 82, alignment: .leading)
                                Text("PGN \(frame.pgn.formatted())").font(.system(size: 10, design: .monospaced)).foregroundStyle(.white.opacity(0.58)).frame(width: 70, alignment: .leading)
                                Text(frame.payload.map { String(format: "%02X", $0) }.joined(separator: " ")).font(.system(size: 10, design: .monospaced)).foregroundStyle(.white.opacity(0.78)).lineLimit(1)
                                Spacer(minLength: 0)
                            }.padding(.vertical, 7)
                            Divider().overlay(.white.opacity(0.07))
                        }
                    }
                }
                SurfaceCard {
                    Label("Hardware emulation limits", systemImage: "info.circle.fill").font(.headline).foregroundStyle(DieselCairnBrand.accent)
                    Text("This fixture tests app decoding and UI flow. It does not model MCP2515 registers, USB/MPSSE timing, BLE fragmentation, transceiver electrical faults, or real ECM/TCM programming. Those need matching emulators or bench hardware.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.64)).padding(.top, 6)
                }
            }.padding(26).frame(maxWidth: 1000).frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("CAN / J1708 bench")
        .fileImporter(isPresented: $showingTraceImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            do {
                guard let url = try result.get().first else { return }
                let hasAccess = url.startAccessingSecurityScopedResource()
                defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
                let fixture = try JSONDecoder().decode(CanTraceFixture.self, from: Data(contentsOf: url))
                guard fixture.format == "DieselCairn CAN Trace", fixture.version == 1,
                      fixture.frames.allSatisfy({ $0.identifier <= 0x1FFF_FFFF && $0.payload.count <= 8 }) else {
                    throw TraceFailure.invalid
                }
                sim.loadReplay(fixture.frames)
                traceError = nil
            } catch { traceError = error.localizedDescription }
        }
        .fileExporter(isPresented: $showingTraceExporter, document: traceDocument, contentType: .json, defaultFilename: "DieselCairn-CANTrace") { result in
            if case .failure(let error) = result { traceError = error.localizedDescription }
        }
    }

    private func exportTrace() {
        do {
            let fixture = CanTraceFixture(scenario: sim.isReplayMode ? "Imported replay" : sim.scenario.rawValue, frames: Array(sim.recentFrames.suffix(100)))
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            encoder.dateEncodingStrategy = .iso8601
            traceDocument = FlashPackageDocument(data: try encoder.encode(fixture))
            traceError = nil
            showingTraceExporter = true
        } catch { traceError = error.localizedDescription }
    }

    private func transmitManualFrame() {
        do {
            guard let pgn = UInt32(manualPGN.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "0x", with: "", options: .caseInsensitive), radix: 16),
                  let source = UInt8(manualSource.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "0x", with: "", options: .caseInsensitive), radix: 16),
                  let priority = UInt8(manualPriority),
                  let bytes = parseHexBytes(manualPayload), bytes.count <= 8 else {
                throw VirtualBusError.invalidFrame
            }
            let frame = try sim.sendManualFrame(pgn: pgn, sourceAddress: source, priority: priority, payload: bytes)
            manualFrameStatus = "Transmitted \(String(format: "%08X", frame.identifier)) · PGN \(frame.pgn) · \(bytes.count) bytes"
            manualFrameError = false
        } catch {
            manualFrameStatus = error.localizedDescription
            manualFrameError = true
        }
    }

    private func transmitManualJ1587() {
        do {
            guard let mid = UInt8(manualMID.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "0x", with: "", options: .caseInsensitive), radix: 16) else {
                throw J1587Error.invalidFrame
            }
            let tokens = manualJ1587Data.split(whereSeparator: { $0.isWhitespace || $0 == "," })
            guard tokens.count <= 19 else { throw J1587Error.tooLong }
            var data: [UInt8] = []
            for token in tokens {
                guard let byte = UInt8(token.replacingOccurrences(of: "0x", with: "", options: .caseInsensitive), radix: 16) else {
                    throw J1587Error.invalidFrame
                }
                data.append(byte)
            }
            let message = try sim.sendManualJ1587(mid: mid, data: data)
            j1587Status = "J1587 SIMULATOR · MID \(String(format: "%02X", message.mid)) · \(message.bytes.count) bytes incl. checksum"
            j1587StatusIsError = false
        } catch {
            j1587Status = error.localizedDescription
            j1587StatusIsError = true
        }
    }

    private func parseHexBytes(_ text: String) -> [UInt8]? {
        let components = text.split(whereSeparator: { $0.isWhitespace || $0 == "," })
        guard components.count <= 8 else { return nil }
        var bytes: [UInt8] = []
        for token in components {
            guard let byte = UInt8(token.replacingOccurrences(of: "0x", with: "", options: .caseInsensitive), radix: 16) else { return nil }
            bytes.append(byte)
        }
        return bytes
    }

    private enum TraceFailure: LocalizedError {
        case invalid
        var errorDescription: String? { "This file is not a supported DieselCairn CAN trace." }
    }
}

private struct BenchMetric: View {
    let title: String
    let value: String
    var body: some View {
        SurfaceCard {
            Text(title.uppercased()).font(.system(size: 9, weight: .bold, design: .rounded)).tracking(1.1).foregroundStyle(.white.opacity(0.5))
            Text(value).font(.system(size: 23, weight: .bold, design: .rounded)).padding(.top, 6)
        }
    }
}

private struct FlashStudioView: View {
    let profile: VehicleProfile
    @State private var module = "Engine ECM"
    @State private var fileName = ""
    @State private var payload: Data?
    @State private var notes = ""
    @State private var importError: String?
    @State private var showingImporter = false
    @State private var showingExporter = false
    @State private var packageDocument = FlashPackageDocument()
    @State private var packageError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionEyebrow(text: "Offline project builder · RE300")
                Text("Build an auditable project for an authorized ECM or TCM calibration. The project records the original payload and its SHA-256 fingerprint.")
                    .foregroundStyle(.white.opacity(0.65)).fixedSize(horizontal: false, vertical: true)
                SurfaceCard {
                    SectionEyebrow(text: "1 · Target record")
                    Text("\(profile.year) \(profile.make) \(profile.model)").font(.headline).padding(.top, 5)
                    Text("VIN \(profile.vin.isEmpty ? "not entered" : profile.vin)").font(.caption).foregroundStyle(.white.opacity(0.6))
                    Picker("Module", selection: $module) { Text("Engine ECM").tag("Engine ECM"); Text("Transmission TCM").tag("Transmission TCM") }.pickerStyle(.segmented).padding(.top, 8)
                    Text(module == "Engine ECM" ? "ECM ID: \(profile.engineECMSerial.isEmpty ? "not recorded" : profile.engineECMSerial)  ·  Cal: \(profile.engineCalibrationID.isEmpty ? "not recorded" : profile.engineCalibrationID)" : "TCM ID: \(profile.tcmSerial.isEmpty ? "not recorded" : profile.tcmSerial)  ·  Cal: \(profile.transmissionCalibrationID.isEmpty ? "not recorded" : profile.transmissionCalibrationID)")
                        .font(.caption).foregroundStyle(.white.opacity(0.55)).textSelection(.enabled)
                }
                SurfaceCard {
                    SectionEyebrow(text: "2 · Source image")
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(fileName.isEmpty ? "No image selected" : fileName).font(.headline).lineLimit(1)
                            Text(payload.map { ByteCountFormatter.string(fromByteCount: Int64($0.count), countStyle: .file) } ?? "OEM package or raw image · format support depends on documented profile")
                                .font(.caption).foregroundStyle(.white.opacity(0.58))
                        }
                        Spacer()
                        Button("Choose file…") { showingImporter = true }.buttonStyle(.borderedProminent)
                    }
                    if let payload {
                        Text("SHA-256  \(SHA256.hash(data: payload).map { String(format: "%02x", $0) }.joined())")
                            .font(.system(size: 10, design: .monospaced)).foregroundStyle(DieselCairnBrand.success).textSelection(.enabled)
                    }
                    if let importError { Text(importError).font(.caption).foregroundStyle(DieselCairnBrand.accent) }
                }
                SurfaceCard {
                    SectionEyebrow(text: "3 · Build project")
                    TextField("Operator notes, source, and intended service action", text: $notes, axis: .vertical).lineLimit(3...6).textFieldStyle(.roundedBorder).padding(.top, 6)
                    Button { buildPackage() } label: { Label("Build flash project", systemImage: "shippingbox.fill") }
                        .buttonStyle(.borderedProminent).disabled(payload == nil).padding(.top, 6)
                    if let packageError { Text(packageError).font(.caption).foregroundStyle(DieselCairnBrand.accent) }
                }
                SurfaceCard {
                    Label("Project is not yet an executable flash program", systemImage: "exclamationmark.triangle.fill").font(.headline).foregroundStyle(DieselCairnBrand.accent)
                    Text("Live writes remain gated on confirmed ECM/TCM identity, a matching authorized calibration, documented module programming protocol, supported adapter firmware, recovery procedure, and validated bench/vehicle tests. A VIN alone cannot establish calibration compatibility.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.66)).padding(.top, 6)
                }
            }.padding(26).frame(maxWidth: 900).frame(maxWidth: .infinity, alignment: .leading)
        }
        .navigationTitle("Flash Studio")
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.data], allowsMultipleSelection: false) { result in
            do {
                guard let url = try result.get().first else { return }
                let hasAccess = url.startAccessingSecurityScopedResource()
                defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                guard data.count <= 64 * 1024 * 1024 else { throw ImportFailure.tooLarge }
                payload = data
                fileName = url.lastPathComponent
                importError = nil
            } catch { importError = error.localizedDescription }
        }
        .fileExporter(isPresented: $showingExporter, document: packageDocument, contentType: .json, defaultFilename: "DieselCairn-FlashProject") { result in
            if case .failure(let error) = result { packageError = error.localizedDescription }
        }
    }

    private func buildPackage() {
        guard let payload else { return }
        do {
            packageDocument = FlashPackageDocument(data: try FlashPackageBuilder.build(vehicle: profile, module: module, filename: fileName, payload: payload, notes: notes))
            packageError = nil
            showingExporter = true
        } catch { packageError = error.localizedDescription }
    }

    private enum ImportFailure: LocalizedError {
        case tooLarge
        var errorDescription: String? { "For this first builder version, source files must be 64 MB or smaller." }
    }
}

private struct AdapterView: View {
    @ObservedObject var connection: ConnectionManager
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                SectionEyebrow(text: "Hardware pathways")
                Text("Adapter setup").font(.largeTitle.bold())
                SurfaceCard {
                    Label(connection.simulator.virtualAdapterConnected ? "Virtual adapter connected" : "No adapter connected", systemImage: connection.simulator.virtualAdapterConnected ? "checkmark.circle.fill" : "cable.connector").font(.headline).foregroundStyle(connection.simulator.virtualAdapterConnected ? DieselCairnBrand.success : DieselCairnBrand.muted)
                    Text("All live paths remain disabled until their transport, receive-only startup, bus timing, error handling, and safe write recovery are validated.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.62)).padding(.top, 5)
                    if connection.simulator.virtualAdapterConnected {
                        Button("Stop virtual adapter") { connection.disconnect() }.buttonStyle(.bordered).padding(.top, 8)
                    } else {
                        NavigationLink(value: AppPage.hardware) {
                            Label("Open virtual hardware controls", systemImage: "cpu")
                        }.buttonStyle(.bordered).padding(.top, 8)
                    }
                }
                ForEach(AdapterPath.allCases) { path in
                    SurfaceCard {
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: path == .ble ? "dot.radiowaves.left.and.right" : "cable.connector").font(.title2).foregroundStyle(DieselCairnBrand.accent)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(path.rawValue).font(.headline)
                                Text(adapterDescription(path)).font(.subheadline).foregroundStyle(.white.opacity(0.62))
                                Text("NOT VALIDATED").font(.system(size: 9, weight: .bold, design: .rounded)).tracking(1.2).foregroundStyle(DieselCairnBrand.accent).padding(.top, 3)
                            }
                            Spacer()
                        }
                    }
                }
            }.padding(26).frame(maxWidth: 900).frame(maxWidth: .infinity, alignment: .leading)
        }.navigationTitle("Adapters")
    }

    private func adapterDescription(_ path: AdapterPath) -> String {
        switch path {
        case .stm32: "STM32 firmware bridge with external CAN controller/transceiver and a separately validated USB serial interface."
        case .arduino: "Arduino USB CDC bridge with external CAN controller/transceiver; board and SPI pin map must match the selected variant."
        case .ft232h: "FT232H MPSSE-to-SPI host for an external MCP2515 CAN controller and automotive-grade transceiver."
        case .ble: "BLE gateway path for iPhone/iPad; requires a documented GATT protocol and a compatible CAN interface."
        }
    }
}

private struct VirtualHardwareView: View {
    @ObservedObject var sim: DiagnosticSimulator
    private var selectedAdapter: Binding<VirtualAdapterDevice> {
        Binding(get: { sim.selectedAdapter }, set: { sim.selectAdapter($0) })
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SectionEyebrow(text: "ISOLATED SOFTWARE BENCH")
                Text("Virtual hardware").font(.largeTitle.bold())
                Text("Model the diagnostic path from ECU node, across a virtual CAN bus, through an adapter transport, and into DieselCairn. This bench cannot access a physical CAN interface.")
                    .foregroundStyle(.white.opacity(0.65)).fixedSize(horizontal: false, vertical: true)

                SurfaceCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            SectionEyebrow(text: "VIRTUAL CONNECTION")
                            Text(sim.virtualAdapterConnected ? "Connected · isolated" : "Stopped · no data")
                                .font(.headline).foregroundStyle(sim.virtualAdapterConnected ? DieselCairnBrand.success : DieselCairnBrand.muted)
                        }
                        Spacer()
                        Button(sim.isRunning ? "Stop" : "Connect") { sim.toggleRunning() }.buttonStyle(.borderedProminent)
                    }
                    Text("Application data is shown only while this virtual session is active. Stopping it drops the virtual link.")
                        .font(.caption).foregroundStyle(.white.opacity(0.58)).padding(.top, 6)
                }

                SurfaceCard {
                    SectionEyebrow(text: "ADAPTER DEVICE MODEL")
                    Picker("Virtual adapter device", selection: selectedAdapter) {
                        ForEach(VirtualAdapterDevice.allCases) { device in Text(device.rawValue).tag(device) }
                    }.pickerStyle(.menu).padding(.top, 8)
                    Picker("Simulated bus bitrate", selection: $sim.busBitrate) {
                        ForEach(SimulatedCANBitrate.allCases) { rate in Text(rate.label).tag(rate) }
                    }.pickerStyle(.segmented).padding(.top, 8)
                    Picker("Adapter CAN bitrate", selection: $sim.bitrate) {
                        ForEach(SimulatedCANBitrate.allCases) { rate in Text(rate.label).tag(rate) }
                    }.pickerStyle(.segmented).padding(.top, 8)
                    Text("The current virtual host link uses DieselCairn protocol v1 framing (COBS + CRC-16). The selected device profile controls the bench's declared hardware type; this software does not execute that board's firmware or emulate MCU registers, USB, BLE RF, SPI timing, or CAN transceiver silicon.")
                        .font(.caption).foregroundStyle(.white.opacity(0.58)).padding(.top, 7)
                }

                SurfaceCard {
                    SectionEyebrow(text: "VIRTUAL ADAPTER DEVICE CONTROLS")
                    Toggle("Adapter MCU powered", isOn: $sim.adapterMCUPowered).tint(DieselCairnBrand.accent).padding(.top, 8)
                    Toggle("CAN controller online", isOn: $sim.canControllerPowered).tint(DieselCairnBrand.accent)
                    Toggle("CAN transceiver connected", isOn: $sim.transceiverConnected).tint(DieselCairnBrand.accent)
                    Toggle("J1708 transceiver connected", isOn: $sim.j1708TransceiverConnected).tint(DieselCairnBrand.accent)
                    Toggle("Adapter firmware running", isOn: $sim.adapterFirmwareRunning).tint(DieselCairnBrand.accent)
                    Text("Turning off the selected protocol's virtual hardware stage blocks that channel. These controls alter software state only; there is no physical simulator node attached yet.")
                        .font(.caption).foregroundStyle(.white.opacity(0.58)).padding(.top, 6)
                }

                SurfaceCard {
                    SectionEyebrow(text: "ECU / TCM NODES")
                    Toggle("MaxxForce engine ECU node", isOn: $sim.ecuNodeOnline).tint(DieselCairnBrand.accent).padding(.top, 8)
                    Toggle("Transmission TCU test node (generic ETC2 profile)", isOn: $sim.tcmNodeOnline).tint(DieselCairnBrand.accent)
                    Toggle("J1587 virtual source node", isOn: $sim.j1587SimulatorNodeOnline).tint(DieselCairnBrand.accent)
                    Stepper("Virtual current gear: \(sim.simulatedGear)", value: $sim.simulatedGear, in: 1...6).padding(.top, 5)
                    Toggle("Engine ECU transmits simulated DM1 fault", isOn: $sim.injectDemoFault).tint(DieselCairnBrand.accent)
                    Text("The transmission test node sends a generic ETC2 frame with a user-selected sample gear. This does not claim Allison TCM compatibility, identify your transmission, or prove that sixth range is supported. VIN-specific calibration, proprietary commands, and flash behavior are not modeled.")
                        .font(.caption).foregroundStyle(.white.opacity(0.58)).padding(.top, 7)
                }

                SurfaceCard {
                    SectionEyebrow(text: "BUS / POWER FAULT INJECTION")
                    HStack { Text("Virtual supply voltage"); Spacer(); Text("\(sim.simulatedSupplyVoltage, specifier: "%.1f") V").monospacedDigit() }
                    Slider(value: $sim.simulatedSupplyVoltage, in: 9...16, step: 0.1).tint(DieselCairnBrand.accent)
                    HStack { Text("Virtual bus load"); Spacer(); Text("\(sim.simulatedBusLoad, specifier: "%.0f") %").monospacedDigit() }
                    Slider(value: $sim.simulatedBusLoad, in: 0...100, step: 1).tint(DieselCairnBrand.accent)
                    Toggle("CAN bus termination present", isOn: $sim.terminationEnabled).tint(DieselCairnBrand.accent)
                    Toggle("Inject adapter transport frame loss", isOn: $sim.injectTransportErrors).tint(DieselCairnBrand.accent)
                    Toggle("Inject J1708 echo collision", isOn: $sim.injectJ1708Collision).tint(DieselCairnBrand.accent)
                    Text("These are software fault controls. The current model does not calculate analog bus voltage, waveform/reflections, arbitration timing, EMC/noise, physical bus-off recovery, or power supply transients.")
                        .font(.caption).foregroundStyle(.white.opacity(0.58)).padding(.top, 7)
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), alignment: .leading)], spacing: 12) {
                    BenchMetric(title: "Bus frames", value: sim.recentFrames.count.formatted())
                    BenchMetric(title: "Adapter RX", value: sim.adapterFramesReceived.formatted())
                    BenchMetric(title: "Transport errors", value: sim.transportErrors.formatted())
                }
                SurfaceCard {
                    Label("Simulation fidelity", systemImage: "info.circle.fill").font(.headline).foregroundStyle(DieselCairnBrand.accent)
                    Text("This exercises generated J1939 frames, the virtual adapter packet codec and CRC check, the frame parser, and DieselCairn's shared decoder. It is a protocol/software integration bench—not an ECU firmware emulator, an electrical CAN simulator, or evidence of compatibility with your bus.")
                        .font(.subheadline).foregroundStyle(.white.opacity(0.64)).padding(.top, 6)
                }
            }.padding(26).frame(maxWidth: 900).frame(maxWidth: .infinity, alignment: .leading)
        }.navigationTitle("Virtual hardware")
    }
}
