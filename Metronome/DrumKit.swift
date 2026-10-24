import Foundation
import Combine

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

    static func single(_ id: String, _ name: String, _ detail: String, file: String, normal: Float, ghost: Float) -> KitSound {
        KitSound(id: id, name: name, detail: detail, accent: (file, 1), normal: (file, normal), ghost: (file, ghost))
    }
}

enum KitVoice: String, CaseIterable, Identifiable {
    case snare, kick, hiHat, openHat, pad

    var id: String { rawValue }

    var title: String {
        switch self {
        case .snare: return "Snare"
        case .kick: return "Kick"
        case .hiHat: return "Hi-hat"
        case .openHat: return "Open hi-hat"
        case .pad: return "Practice pad"
        }
    }

    var options: [KitSound] {
        switch self {
        case .snare:
            return [
                .single("snare-14maple5", "14x5 Maple", "Warm classic funk snare", file: "snare-14maple5", normal: 0.62, ghost: 0.18),
                KitSound(id: "snare-alu", name: "14x8 Aluminium", detail: "Bright and crisp, rimshot accents",
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
                KitSound(id: "kick-felt", name: "Felt", detail: "Dry and short, soft felt beater",
                         accent: ("kick-felt", 1), normal: ("kick-felt", 0.85), ghost: ("kick-felt-soft", 0.7)),
                KitSound(id: "kick-funk", name: "Funk", detail: "Full and punchy",
                         accent: ("kick-accent", 1), normal: ("kick", 0.85), ghost: ("kick-soft", 0.6)),
                KitSound(id: "kick-metal", name: "Tight", detail: "Short with a hard beater click",
                         accent: ("kick-tight", 1), normal: ("kick-tight", 0.85), ghost: ("kick-tight", 0.6))
            ]
        case .hiHat:
            return [
                KitSound(id: "hat-tight", name: "Tight", detail: "Short and clean, played on the side",
                         accent: ("hihat-tight-accent", 0.8), normal: ("hihat-tight", 0.5), ghost: ("hihat-tight-soft", 0.32)),
                KitSound(id: "hat-bright", name: "Bright", detail: "Tight closed hats in three strengths",
                         accent: ("hihat-accent", 0.8), normal: ("hihat", 0.45), ghost: ("hihat-soft", 0.3))
            ]
        case .openHat:
            return [
                .single("open-room", "Room", "Open hat with natural room sound", file: "hihat-open-room", normal: 0.55, ghost: 0.45),
                .single("open-wash", "Wash", "Open hat with a short sizzle", file: "hihat-open", normal: 0.55, ghost: 0.45)
            ]
        case .pad:
            return [
                KitSound(id: "pad-rubber", name: "Practice pad", detail: "Rubber pad, left hand a touch lower",
                         accent: ("pad-right-accent", 0.9), normal: ("pad-right", 0.42), ghost: ("pad-right", 0.3),
                         leftAccent: ("pad-left-accent", 0.9), left: ("pad-left", 0.42)),
                KitSound(id: "pad-wood", name: "Woodblock", detail: "Clear wooden knock",
                         accent: ("woodblock-accent", 0.9), normal: ("woodblock", 0.5), ghost: ("woodblock", 0.35))
            ]
        }
    }
}

// The learn kit the user picked, one sound per voice, remembered across launches
final class DrumKit: ObservableObject {
    static let shared = DrumKit()

    @Published private(set) var selection: [KitVoice: String] = [:]

    init() {
        for voice in KitVoice.allCases {
            selection[voice] = UserDefaults.standard.string(forKey: "kit.\(voice.rawValue)") ?? voice.options[0].id
        }
    }

    func sound(for voice: KitVoice) -> KitSound {
        voice.options.first { $0.id == selection[voice] } ?? voice.options[0]
    }

    func select(_ sound: KitSound, for voice: KitVoice) {
        selection[voice] = sound.id
        UserDefaults.standard.set(sound.id, forKey: "kit.\(voice.rawValue)")
    }
}
