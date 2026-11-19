import SwiftUI
import DieselCairnUI

@main
struct DieselCairnMac: App {
    var body: some Scene {
        WindowGroup {
            DieselCairnRootView().frame(minWidth: 980, minHeight: 720)
        }
        .windowStyle(.titleBar)
    }
}
