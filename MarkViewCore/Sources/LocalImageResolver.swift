import Foundation

public struct LocalImageResolver {
    public init() {}

    public func htmlSource(for destination: String, markdownFileURL: URL?) -> String? {
        let trimmed = destination.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        guard !trimmed.hasPrefix("/"), URLComponents(string: trimmed)?.scheme == nil, let markdownFileURL else {
            return nil
        }

        let baseDirectory = markdownFileURL.deletingLastPathComponent().standardizedFileURL
        let candidate = baseDirectory
            .appendingPathComponent(trimmed.removingPercentEncoding ?? trimmed)
            .standardizedFileURL

        guard isDescendant(candidate, of: baseDirectory) else {
            return nil
        }

        guard let data = try? Data(contentsOf: candidate), let mimeType = mimeType(for: candidate) else {
            return nil
        }

        return "data:\(mimeType);base64,\(data.base64EncodedString())"
    }

    private func mimeType(for url: URL) -> String? {
        switch url.pathExtension.lowercased() {
        case "png":
            return "image/png"
        case "jpg", "jpeg":
            return "image/jpeg"
        case "gif":
            return "image/gif"
        case "webp":
            return "image/webp"
        case "svg":
            return "image/svg+xml"
        default:
            return nil
        }
    }

    private func isDescendant(_ url: URL, of directory: URL) -> Bool {
        let directoryPath = directory.path.hasSuffix("/") ? directory.path : "\(directory.path)/"
        return url.path.hasPrefix(directoryPath)
    }
}
