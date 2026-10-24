import Foundation
import Combine
import AVFoundation

// One choosable sound for a kit voice: recorded file per dynamic and the level it plays at
struct KitSound: Identifiable, Equatable {
    let id: String
    let name: String
    let detail: String
    let accent: (file: String, gain: Float)
    let normal: (file: String, gain: Float)
    let ghost: (file: String, gain: Float)
    // Hand exercises: the left hand can have its own, slightly lower recording
    var leftAccent: (file: String, gain: Float)? = nil
    var left: (file: String, gain: Float)? = nil

    static func == (lhs: KitSound, rhs: KitSound) -> Bool { lhs.id == rhs.id }

    // Built-in sound recorded once and played at three levels, name and detail come from the string catalog
    static func single(_ id: String, _ name: LocalizedStringResource, _ detail: LocalizedStringResource, file: String, normal: Float, ghost: Float) -> KitSound {
        KitSound(id: id, name: String(localized: name), detail: String(localized: detail), accent: (file, 1), normal: (file, normal), ghost: (file, ghost))
    }
}

enum KitVoice: String, CaseIterable, Identifiable {
    case snare, kick, hiHat, openHat, pad

    var id: String { rawValue }

    var title: String {
        switch self {
        case .snare: return String(localized: "Snare")
        case .kick: return String(localized: "Kick")
        case .hiHat: return String(localized: "Hi-hat")
        case .openHat: return String(localized: "Open hi-hat")
        case .pad: return String(localized: "Practice pad")
        }
    }

    var builtInOptions: [KitSound] {
        switch self {
        case .snare:
            return [
                .single("snare-14maple5", "14x5 Maple", "Warm classic funk snare", file: "snare-14maple5", normal: 0.62, ghost: 0.18),
                KitSound(id: "snare-alu", name: String(localized: "14x8 Aluminium"), detail: String(localized: "Bright and crisp, rimshot accents"),
                         accent: ("snare-accent", 1), normal: ("snare", 0.55), ghost: ("snare-ghost", 0.3)),
                .single("snare-14maple65", "14x6.5 Maple", "Fuller body, round crack", file: "snare-14maple65", normal: 0.62, ghost: 0.18),
                .single("snare-14birch", "14x8 Birch", "Deep and punchy", file: "snare-14birch", normal: 0.62, ghost: 0.18),
                .single("snare-14mystery", "14x5 Vintage", "Dry and woody", file: "snare-14mystery", normal: 0.62, ghost: 0.18),
                .single("snare-13birch", "13x9 Birch", "Tight with long wires", file: "snare-13birch", normal: 0.62, ghost: 0.18),
                .single("snare-12steel", "12x5 Steel", "High, cutting, fusion", file: "snare-12steel", normal: 0.62, ghost: 0.18),
                .single("snare-10in", "10 inch", "Very high, poppy", file: "snare-10in", normal: 0.62, ghost: 0.18)
            ]
        case .kick:
            return [
                KitSound(id: "kick-felt", name: String(localized: "Felt"), detail: String(localized: "Dry and short, soft felt beater"),
                         accent: ("kick-felt", 1), normal: ("kick-felt", 0.85), ghost: ("kick-felt-soft", 0.7)),
                KitSound(id: "kick-funk", name: String(localized: "Funk"), detail: String(localized: "Full and punchy"),
                         accent: ("kick-accent", 1), normal: ("kick", 0.85), ghost: ("kick-soft", 0.6)),
                KitSound(id: "kick-natural", name: String(localized: "Natural"), detail: String(localized: "Close and inside mics, unprocessed"),
                         accent: ("kick-natural-accent", 1), normal: ("kick-natural", 0.85), ghost: ("kick-natural-soft", 0.7)),
                KitSound(id: "kick-room", name: String(localized: "Room"), detail: String(localized: "Kick heard from the room"),
                         accent: ("kick-room-accent", 1), normal: ("kick-room", 0.85), ghost: ("kick-room-soft", 0.7)),
                KitSound(id: "kick-boom", name: String(localized: "Boom"), detail: String(localized: "Big and open, longer tail"),
                         accent: ("kick-boom-accent", 1), normal: ("kick-boom", 0.85), ghost: ("kick-boom-soft", 0.7)),
                KitSound(id: "kick-metal", name: String(localized: "Tight"), detail: String(localized: "Short with a hard beater click"),
                         accent: ("kick-tight", 1), normal: ("kick-tight", 0.85), ghost: ("kick-tight", 0.6))
            ]
        case .hiHat:
            return [
                KitSound(id: "hat-tight", name: String(localized: "Tight"), detail: String(localized: "Short and clean, played on the side"),
                         accent: ("hihat-tight-accent", 0.8), normal: ("hihat-tight", 0.5), ghost: ("hihat-tight-soft", 0.32)),
                KitSound(id: "hat-bright", name: String(localized: "Bright"), detail: String(localized: "Tight closed hats in three strengths"),
                         accent: ("hihat-accent", 0.8), normal: ("hihat", 0.45), ghost: ("hihat-soft", 0.3)),
                KitSound(id: "hat-overhead", name: String(localized: "Overhead"), detail: String(localized: "Closed hat with some air around it"),
                         accent: ("hihat-overhead-accent", 0.8), normal: ("hihat-overhead", 0.5), ghost: ("hihat-overhead-soft", 0.32)),
                KitSound(id: "hat-half", name: String(localized: "Half open"), detail: String(localized: "A little wash on every note"),
                         accent: ("hihat-half-accent", 0.75), normal: ("hihat-half", 0.45), ghost: ("hihat-half-soft", 0.3)),
                KitSound(id: "hat-sloshy", name: String(localized: "Sloshy"), detail: String(localized: "Loose and trashy, rock feel"),
                         accent: ("hihat-sloshy-accent", 0.7), normal: ("hihat-sloshy", 0.42), ghost: ("hihat-sloshy-soft", 0.28))
            ]
        case .openHat:
            return [
                .single("open-room", "Room", "Open hat with natural room sound", file: "hihat-open-room", normal: 0.55, ghost: 0.45),
                .single("open-wash", "Wash", "Open hat with a short sizzle", file: "hihat-open", normal: 0.55, ghost: 0.45),
                .single("open-long", "Long", "Fully open, long ring", file: "hihat-open-long", normal: 0.5, ghost: 0.4),
                .single("open-classic", "Classic", "Bright open hat, orchestral recording", file: "hihat-open-classic", normal: 0.55, ghost: 0.45)
            ]
        case .pad:
            return [
                KitSound(id: "pad-rubber", name: String(localized: "Practice pad"), detail: String(localized: "Rubber pad, left hand a touch lower"),
                         accent: ("pad-right-accent", 0.9), normal: ("pad-right", 0.42), ghost: ("pad-right", 0.3),
                         leftAccent: ("pad-left-accent", 0.9), left: ("pad-left", 0.42)),
                KitSound(id: "pad-wood", name: String(localized: "Woodblock"), detail: String(localized: "Clear wooden knock"),
                         accent: ("woodblock-accent", 0.9), normal: ("woodblock", 0.5), ghost: ("woodblock", 0.35)),
                KitSound(id: "pad-claves", name: String(localized: "Claves"), detail: String(localized: "Bright hardwood click"),
                         accent: ("claves-accent", 0.9), normal: ("claves", 0.5), ghost: ("claves", 0.35))
            ]
        }
    }
}

// The learn kit the user picked, one sound per voice, remembered across launches
final class DrumKit: ObservableObject {
    static let shared = DrumKit()

    @Published private(set) var selection: [KitVoice: String] = [:]
    @Published private(set) var imported: [KitVoice: [UserSounds.Entry]] = [:]

    init() {
        for voice in KitVoice.allCases {
            imported[voice] = UserSounds.entries(for: voice)
            selection[voice] = UserDefaults.standard.string(forKey: "kit.\(voice.rawValue)") ?? voice.builtInOptions[0].id
        }
    }

    func options(for voice: KitVoice) -> [KitSound] {
        voice.builtInOptions + importedSounds(for: voice)
    }

    func importedSounds(for voice: KitVoice) -> [KitSound] {
        let ghost: Float = voice == .snare ? 0.2 : 0.35
        return (imported[voice] ?? []).map {
            let file = UserSounds.prefix + $0.file
            return KitSound(id: $0.id, name: $0.name, detail: String(localized: "Your sound"),
                            accent: (file, 1), normal: (file, 0.65), ghost: (file, ghost))
        }
    }

    func sound(for voice: KitVoice) -> KitSound {
        options(for: voice).first { $0.id == selection[voice] } ?? voice.builtInOptions[0]
    }

    // Copies the picked files into the app, the newest one becomes the selected sound
    func importSounds(_ urls: [URL], for voice: KitVoice) -> Int {
        var added = 0
        for url in urls {
            guard let entry = UserSounds.add(url, for: voice) else { continue }
            imported[voice, default: []].append(entry)
            added += 1
        }
        if added > 0, let last = importedSounds(for: voice).last { select(last, for: voice) }
        return added
    }

    func remove(_ sound: KitSound, for voice: KitVoice) {
        UserSounds.remove(id: sound.id, for: voice)
        imported[voice] = UserSounds.entries(for: voice)
        if selection[voice] == sound.id { select(voice.builtInOptions[0], for: voice) }
    }

    func select(_ sound: KitSound, for voice: KitVoice) {
        selection[voice] = sound.id
        UserDefaults.standard.set(sound.id, forKey: "kit.\(voice.rawValue)")
    }
}

// Sounds the user imported from Files, stored on device only, never bundled or shared
enum UserSounds {
    struct Entry: Codable {
        let id: String
        let name: String
        let file: String
    }

    static let prefix = "user/"

    static var directory: URL {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("UserSounds", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private static func key(_ voice: KitVoice) -> String { "kit.imported.\(voice.rawValue)" }

    static func entries(for voice: KitVoice) -> [Entry] {
        guard let data = UserDefaults.standard.data(forKey: key(voice)),
              let list = try? JSONDecoder().decode([Entry].self, from: data) else { return [] }
        return list.filter { FileManager.default.fileExists(atPath: directory.appendingPathComponent($0.file).path) }
    }

    private static func save(_ list: [Entry], for voice: KitVoice) {
        if let data = try? JSONEncoder().encode(list) { UserDefaults.standard.set(data, forKey: key(voice)) }
    }

    static func add(_ url: URL, for voice: KitVoice) -> Entry? {
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        let id = "user-" + UUID().uuidString
        let file = id + "." + (url.pathExtension.isEmpty ? "wav" : url.pathExtension.lowercased())
        let destination = directory.appendingPathComponent(file)
        do {
            try FileManager.default.copyItem(at: url, to: destination)
        } catch {
            return nil
        }
        // Only keep files the engine can actually play
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        guard Synth.decode(destination, to: format) != nil else {
            try? FileManager.default.removeItem(at: destination)
            return nil
        }
        let entry = Entry(id: id, name: url.deletingPathExtension().lastPathComponent, file: file)
        save(entries(for: voice) + [entry], for: voice)
        return entry
    }

    static func remove(id: String, for voice: KitVoice) {
        var list = entries(for: voice)
        if let entry = list.first(where: { $0.id == id }) {
            try? FileManager.default.removeItem(at: directory.appendingPathComponent(entry.file))
        }
        list.removeAll { $0.id == id }
        save(list, for: voice)
    }
}
