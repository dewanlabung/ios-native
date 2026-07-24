#if DEBUG
import Foundation
import DebugBridgeCore
#if canImport(UIKit)
import DebugBridgeUI
#endif

@MainActor
func startGstackDebugBridge<State>(
    appState: State,
    register: (State) -> Void
) {
    let recording = ProcessInfo.processInfo.arguments.contains("--gstack-recording")

    #if canImport(UIKit)
    DebugBridgeUIWiring.installAll()
    #endif

    DebugBridgeManager.shared.start(appState: appState, register: register)

    #if canImport(UIKit)
    DebugOverlayWindow.shared.install(recording: recording)
    #endif
}
#endif
