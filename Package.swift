// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DieselCairn",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .executable(name: "DieselCairnMac", targets: ["DieselCairnMac"]),
        .executable(name: "DieselCairnMobile", targets: ["DieselCairnMobile"]),
        .executable(name: "DieselCairnMCP", targets: ["DieselCairnMCP"]),
        .library(name: "DieselCairnCore", targets: ["iScanCore"]),
        .library(name: "DieselCairnUI", targets: ["DieselCairnUI"]),
    ],
    targets: [
        .target(name: "iScanModels", path: "Sources/iScanModels", sources: ["VehicleModel.swift", "VehicleProfile.swift", "J1708Model.swift"]),
        .target(name: "iScanCore", dependencies: ["iScanModels"], path: "Sources/iScanCore", sources: ["AdapterFrameCodec.swift", "ConnectionManager.swift", "DiagnosticSimulator.swift", "J1939Decoder.swift", "VINDecoder.swift"]),
        .target(name: "DieselCairnUI", dependencies: ["iScanCore", "iScanModels"], path: "Sources/SharedUI", sources: ["DieselCairnRootView.swift", "Brand.swift", "FlashPackage.swift"]),
        .executableTarget(name: "DieselCairnMac", dependencies: ["DieselCairnUI", "iScanCore"], path: "Sources/MacOS", sources: ["AppMain.swift"]),
        .executableTarget(name: "DieselCairnMobile", dependencies: ["DieselCairnUI", "iScanCore"], path: "Sources/iOS", sources: ["AppEntry.swift"]),
        .executableTarget(name: "DieselCairnMCP", dependencies: ["DieselCairnUI", "iScanCore", "iScanModels"], path: "Sources/MCP", sources: ["main.swift"]),
        .testTarget(name: "DieselCairnCoreTests", dependencies: ["iScanCore", "iScanModels"], path: "Tests/DieselCairnCoreTests"),
    ]
)
