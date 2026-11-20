import Foundation
import SpeedKit

/// The trail on disk (BESLUT B16): one file in Application Support, kept out of the phone's backup. Nothing is sent
/// anywhere (BESLUT B3).
enum TrailFile {
    private static var url: URL? {
        try? FileManager.default
            .url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("trail.v1.json")
    }

    static func load() -> Trail? {
        guard let url = TrailFile.url, let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(Trail.self, from: data)
    }

    /// An empty trail removes the file.
    static func save(_ trail: Trail) {
        guard var url = TrailFile.url else { return }
        if trail.isEmpty {
            try? FileManager.default.removeItem(at: url)
            return
        }
        guard let data = try? JSONEncoder().encode(trail) else { return }
        do {
            try data.write(to: url, options: .atomic)
            // An atomic write replaces the file, so the flag is set again each time.
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            try url.setResourceValues(values)
        } catch {
            // Nothing to do: the trail stays in memory and the next save tries again.
        }
    }
}
