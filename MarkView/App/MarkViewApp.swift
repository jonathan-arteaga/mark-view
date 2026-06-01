import SwiftUI

@main
struct MarkViewApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(width: 520, height: 320)
        }
        .windowStyle(.titleBar)
        .windowResizability(.contentSize)
    }
}
