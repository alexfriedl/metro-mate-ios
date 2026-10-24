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

    // Published so the history can show what is playing right now
    @Published private var running: Running?

    // The session that is playing right now, its duration measured up to this moment
    var live: PracticeSession? {
        guard let running else { return nil }
        return PracticeSession(kind: running.kind, title: running.title, detail: running.detail,
                               start: running.start, duration: Date().timeIntervalSince(running.start), bpm: running.bpm)
    }
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

    // Puts a deleted session back, newest first as before
    func restore(_ session: PracticeSession) {
        guard !stored.contains(where: { $0.id == session.id }) else { return }
        stored.append(session)
        stored.sort { $0.start > $1.start }
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

// Numbers for the history screen, kept free of UI so they can be tested
enum PracticeStats {
    // Five steps from nothing to an hour or more, fixed so a day reads the same in every month
    static func heatLevel(seconds: TimeInterval) -> Int {
        switch seconds / 60 {
        case ..<1: return 0
        case ..<15: return 1
        case ..<30: return 2
        case ..<60: return 3
        default: return 4
        }
    }

    // Longest run of days in a row with practice
    static func longestStreak(_ sessions: [PracticeSession], calendar: Calendar) -> Int {
        let days = Set(sessions.map { calendar.startOfDay(for: $0.start) }).sorted()
        var longest = 0
        var current = 0
        var previous: Date?
        for day in days {
            if let previous, calendar.date(byAdding: .day, value: 1, to: previous) == day {
                current += 1
            } else {
                current = 1
            }
            longest = max(longest, current)
            previous = day
        }
        return longest
    }

    struct TempoChange: Equatable {
        let title: String
        let first: Int
        let last: Int
        let total: TimeInterval
    }

    // Tempo of the first and the last session per groove or preset, most practised first
    static func tempoProgress(_ sessions: [PracticeSession], limit: Int = 5) -> [TempoChange] {
        Dictionary(grouping: sessions, by: \.title)
            .compactMap { title, group -> TempoChange? in
                let ordered = group.sorted { $0.start < $1.start }
                guard let first = ordered.first, let last = ordered.last else { return nil }
                return TempoChange(title: title, first: first.bpm, last: last.bpm,
                                   total: group.reduce(0) { $0 + $1.duration })
            }
            .sorted { $0.total == $1.total ? $0.title < $1.title : $0.total > $1.total }
            .prefix(limit)
            .map { $0 }
    }

    // Plural forms come from the string catalog, tests pass a language bundle to stay independent of the device language
    static func days(_ count: Int, bundle: Bundle = .main) -> String {
        String(localized: "\(count) days", bundle: bundle)
    }

    static func practiceDays(_ count: Int, bundle: Bundle = .main) -> String {
        String(localized: "\(count) practice days", bundle: bundle)
    }
}
