import AppKit
import SwiftUI

struct ContentView: View {
    private let sampleURL = Bundle.main.url(forResource: "sample", withExtension: "md")
    @State private var cleanupMessage = "Ready"
    @State private var isCleaning = false
    @State private var cleanupTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("MarkView")
                    .font(.title.weight(.semibold))
                Text("Local Quick Look previews for Markdown, diagrams, math, code, tables, and images.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            VStack(alignment: .leading, spacing: 10) {
                StatusRow(symbol: "checkmark.seal.fill", title: "Quick Look extension", detail: "Installed locally")
                StatusRow(symbol: "lock.fill", title: "Offline renderer", detail: "Uses bundled assets only")
                StatusRow(symbol: "arrow.triangle.2.circlepath", title: "Extension list", detail: cleanupMessage)
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    revealSample()
                } label: {
                    Label("Reveal Sample", systemImage: "doc.text.magnifyingglass")
                }
                .buttonStyle(.borderedProminent)

                Button {
                    openExtensionsSettings()
                } label: {
                    Label("Open Extensions Settings", systemImage: "gearshape")
                }

                Button {
                    cleanDuplicates()
                } label: {
                    Label(isCleaning ? "Cleaning" : "Clean Duplicates", systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(isCleaning)

                Spacer()
            }
        }
        .padding(28)
        .onDisappear {
            cleanupTask?.cancel()
        }
    }

    private func revealSample() {
        guard let sampleURL else {
            return
        }
        NSWorkspace.shared.activateFileViewerSelecting([sampleURL])
    }

    private func openExtensionsSettings() {
        let urls = [
            URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences")!,
            URL(string: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension")!
        ]

        for url in urls where NSWorkspace.shared.open(url) {
            return
        }
    }

    private func cleanDuplicates() {
        cleanupTask?.cancel()
        isCleaning = true
        cleanupMessage = "Cleaning stale copies..."

        cleanupTask = Task {
            let message = await StaleMarkViewCleaner.clean()
            guard !Task.isCancelled else {
                return
            }
            cleanupMessage = message
            isCleaning = false
        }
    }
}
