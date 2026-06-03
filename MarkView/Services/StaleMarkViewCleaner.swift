import Foundation

enum StaleMarkViewCleaner {
    static func clean() async -> String {
        await Task.detached(priority: .userInitiated) {
            cleanSynchronously()
        }.value
    }

    private static func cleanSynchronously() -> String {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser
        let buildRoot = home.appendingPathComponent("Library/Caches/MarkView")
        let currentAppPath = Bundle.main.bundleURL.standardizedFileURL.path
        let installedApp = home.appendingPathComponent("Applications/MarkView.app")

        let candidates = [
            buildRoot.appendingPathComponent("TestDerivedData"),
            buildRoot.appendingPathComponent("PackageDerivedData"),
            buildRoot.appendingPathComponent("DmgDerivedData"),
            buildRoot.appendingPathComponent("DerivedData/Build/Products/Debug"),
            buildRoot.appendingPathComponent("DerivedData/Build/Products/Release/MarkView.app"),
            buildRoot.appendingPathComponent("DerivedData/Build/Products/Release/MarkViewPreviewExtension.appex")
        ]

        var removedCount = 0
        var failedCount = 0

        for candidate in candidates {
            let path = candidate.standardizedFileURL.path
            guard path != currentAppPath, fileManager.fileExists(atPath: path) else {
                continue
            }

            unregisterBundles(under: candidate)
            unregister(candidate)
            do {
                try fileManager.removeItem(at: candidate)
                removedCount += 1
            } catch {
                failedCount += 1
            }
        }

        if fileManager.fileExists(atPath: installedApp.path) {
            _ = run(
                "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister",
                ["-f", "-R", "-trusted", installedApp.path]
            )
        }
        refreshQuickLook()

        if failedCount > 0 {
            return "Removed \(removedCount), \(failedCount) need manual cleanup"
        }
        return removedCount == 0 ? "No stale copies found" : "Removed \(removedCount) stale copies"
    }

    private static func unregister(_ url: URL) {
        _ = run("/usr/bin/pluginkit", ["-r", url.path])
        _ = run("/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister", ["-u", url.path])
    }

    private static func unregisterBundles(under url: URL) {
        let bundleNames: Set<String> = [
            "MarkView.app",
            "MarkViewPreviewExtension.appex"
        ]
        if bundleNames.contains(url.lastPathComponent) {
            unregister(url)
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory), isDirectory.boolValue else {
            return
        }

        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: nil) else {
            return
        }

        for case let child as URL in enumerator where bundleNames.contains(child.lastPathComponent) {
            unregister(child)
            enumerator.skipDescendants()
        }
    }

    private static func refreshQuickLook() {
        _ = run("/usr/bin/qlmanage", ["-r"])
        _ = run("/usr/bin/qlmanage", ["-r", "cache"])
    }

    private static func run(_ executable: String, _ arguments: [String]) -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
}
