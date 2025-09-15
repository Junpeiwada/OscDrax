import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()
    private let fileName = "oscdrax_state.json"

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory,
                                  in: .userDomainMask).first!
    }

    private var fileURL: URL {
        documentsDirectory.appendingPathComponent(fileName)
    }

    private init() {}

    // Save all tracks data
    func saveTracks(_ tracks: [Track]) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(tracks)
            try data.write(to: fileURL)
            print("Tracks saved successfully to: \(fileURL)")
        } catch {
            print("Failed to save tracks: \(error)")
        }
    }

    // Load tracks data
    func loadTracks() -> [Track]? {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let tracks = try decoder.decode([Track].self, from: data)
            print("Tracks loaded successfully")
            return tracks
        } catch {
            print("Failed to load tracks: \(error)")
            return nil
        }
    }

    // Delete saved data
    func clearSavedData() {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                print("Saved data cleared")
            }
        } catch {
            print("Failed to clear saved data: \(error)")
        }
    }
}