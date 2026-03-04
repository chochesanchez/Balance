import Foundation

// MARK: - iCloud Sync Manager
/// Handles reading and writing JSON data to the app's iCloud ubiquity container.
/// Works alongside UserDefaults — UserDefaults remains the fast local cache,
/// iCloud files serve as the cross-device sync layer.
@MainActor
final class iCloudSyncManager {
    static let shared = iCloudSyncManager()
    private let containerID = "iCloud.com.chochesanchez.Balance"

    // MARK: - Availability

    var isAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    // MARK: - URLs

    var documentsURL: URL? {
        FileManager.default.url(forUbiquityContainerIdentifier: containerID)?
            .appendingPathComponent("Documents", isDirectory: true)
    }

    func url(for filename: String) -> URL? {
        documentsURL?.appendingPathComponent(filename)
    }

    // MARK: - Write

    func write(_ data: Data, filename: String) {
        guard let url = url(for: filename) else { return }
        // Ensure the Documents directory exists in iCloud container
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        var error: NSError?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forReplacing, error: &error) { coordURL in
            try? data.write(to: coordURL, options: .atomic)
        }
    }

    // MARK: - Read

    func read(filename: String) -> Data? {
        guard let url = url(for: filename) else { return nil }
        var result: Data?
        var error: NSError?
        NSFileCoordinator().coordinate(readingItemAt: url, options: .withoutChanges, error: &error) { coordURL in
            result = try? Data(contentsOf: coordURL)
        }
        return result
    }

    // MARK: - Metadata

    func modificationDate(filename: String) -> Date? {
        guard let url = url(for: filename) else { return nil }
        return (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
    }
}
