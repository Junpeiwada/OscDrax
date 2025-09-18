import Foundation
import OSLog

class PersistenceManager {
    static let shared = PersistenceManager()
    private let fileName = "oscdrax_state.json"
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.oscdrax.app",
        category: "PersistenceManager"
    )
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return encoder
    }()
    private let decoder = JSONDecoder()

    private enum PersistenceError: Error {
        case documentsDirectoryUnavailable
    }

    private var fileURL: URL? {
        guard let documentsDirectory = FileManager.default.urls(for: .documentDirectory,
                                                                in: .userDomainMask).first else {
            log("Documents directory is unavailable", error: PersistenceError.documentsDirectoryUnavailable)
            return nil
        }
        return documentsDirectory.appendingPathComponent(fileName)
    }

    private init() {}

    // Save all tracks data
    func saveTracks(_ tracks: [Track]) {
        do {
            guard let fileURL = fileURL else { return }
            let data = try encoder.encode(tracks)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            log("Failed to save tracks", error: error)
        }
    }

    // Load tracks data
    func loadTracks() -> [Track]? {
        do {
            guard let fileURL = fileURL else { return nil }
            let data = try Data(contentsOf: fileURL)
            let tracks = try decoder.decode([Track].self, from: data)
            return tracks
        } catch {
            log("Failed to load tracks", error: error)
            return nil
        }
    }

    // Delete saved data
    func clearSavedData() {
        do {
            guard let fileURL = fileURL else { return }
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            log("Failed to clear saved data", error: error)
        }
    }

    private func log(_ message: String, error: Error? = nil) {
        #if !DEBUG
        return
        #endif

        if let error {
            logger.error("\(message, privacy: .public): \(String(describing: error), privacy: .public)")
        } else {
            logger.info("\(message, privacy: .public)")
        }
    }
}
