import Foundation

@MainActor
final class iCloudSyncManager {
    static let shared = iCloudSyncManager()
    private let containerID = "iCloud.com.chochesanchez.Balanced"

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
        guard let url = url(for: filename) else {
            Log.sync.warning("iCloud write skipped — no documents URL for \(filename, privacy: .public)")
            return
        }
        do {
            try FileManager.default.createDirectory(
                at: url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
        } catch {
            Log.sync.warning("Failed to create iCloud directory: \(error.localizedDescription, privacy: .public)")
        }
        var coordError: NSError?
        NSFileCoordinator().coordinate(writingItemAt: url, options: .forReplacing, error: &coordError) { coordURL in
            do {
                try data.write(to: coordURL, options: .atomic)
            } catch {
                Log.sync.error("iCloud write failed for \(filename, privacy: .public): \(error.localizedDescription, privacy: .public)")
            }
        }
        if let coordError {
            Log.sync.error("iCloud coordinator (write) error: \(coordError.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Read

    func read(filename: String) -> Data? {
        guard let url = url(for: filename) else { return nil }
        var result: Data?
        var coordError: NSError?
        NSFileCoordinator().coordinate(readingItemAt: url, options: .withoutChanges, error: &coordError) { coordURL in
            do {
                result = try Data(contentsOf: coordURL)
            } catch {
                let nsErr = error as NSError
                if nsErr.code != NSFileReadNoSuchFileError {
                    Log.sync.error("iCloud read failed for \(filename, privacy: .public): \(error.localizedDescription, privacy: .public)")
                }
            }
        }
        if let coordError {
            Log.sync.error("iCloud coordinator (read) error: \(coordError.localizedDescription, privacy: .public)")
        }
        return result
    }

    // MARK: - Metadata

    func modificationDate(filename: String) -> Date? {
        guard let url = url(for: filename) else { return nil }
        return (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
    }
}
