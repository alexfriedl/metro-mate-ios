import Foundation
import UIKit

struct PracticeSession: Identifiable, Codable {
    enum Kind: String, Codable {
        case metronome, groove
    }

    var id = UUID()
    let kind: Kind
    let title: String
    let detail: String
    let start: Date
    let duration: TimeInterval
    let bpm: Int
}

// Records what was played, when and for how long, stored on device only
final class PracticeLog: ObservableObject {
    static let shared = PracticeLog()

    // Stored sessions include short ones that may still grow, the UI only shows counted ones
    @Published private var stored: [PracticeSession] = []

    var sessions: [PracticeSession] { stored.filter { $0.duration >= Self.countedAfter } }

    static let countedAfter: TimeInterval = 30
    private let mergeGap: TimeInterval = 180

    private struct Running {
        let kind: PracticeSession.Kind
        let title: String
        let detail: String
        let start: Date
        var bpm: Int
    }

    private var running: Running?
    private let minimumDuration: TimeInterval = 3
    private let fileURL: URL = {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("practice-log.json")
    }()

    init() {
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([PracticeSession].self, from: data) {
            stored = saved
        }
        NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: .main) { [weak self] _ in
            self?.end()
        }
    }

    func begin(_ kind: PracticeSession.Kind, title: String, detail: String, bpm: Int) {
        end()
        running = Running(kind: kind, title: title, detail: detail, start: Date(), bpm: bpm)
    }

    // The tempo stored is the last one used, that is where the practice ended up
    func updateTempo(_ bpm: Int) {
        running?.bpm = bpm
    }

    func end() {
        guard let current = running else { return }
        running = nil
        let now = Date()
        let duration = now.timeIntervalSince(current.start)
        guard duration >= minimumDuration else { return }

        // Same thing again after a short pause is one session, only the playing time counts
        if let last = stored.first, last.kind == current.kind, last.title == current.title, last.detail == current.detail,
           current.start.timeIntervalSince(last.start.addingTimeInterval(last.duration)) < mergeGap {
            stored[0] = PracticeSession(id: last.id, kind: last.kind, title: last.title, detail: last.detail,
                                        start: last.start, duration: last.duration + duration, bpm: current.bpm)
            save()
            return
        }

        stored.insert(PracticeSession(
            kind: current.kind,
            title: current.title,
            detail: current.detail,
            start: current.start,
            duration: duration,
            bpm: current.bpm
        ), at: 0)
        save()
    }

    func delete(_ session: PracticeSession) {
        stored.removeAll { $0.id == session.id }
        save()
    }

    func sessions(in interval: DateInterval) -> [PracticeSession] {
        sessions.filter { interval.contains($0.start) }
    }

    func total(in interval: DateInterval) -> TimeInterval {
        sessions(in: interval).reduce(0) { $0 + $1.duration }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(stored) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
