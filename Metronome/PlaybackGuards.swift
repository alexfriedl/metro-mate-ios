import AVFoundation
import UIKit

// Keeps the display on while the metronome or a groove plays, each player reports itself
enum ScreenAwake {
    private static var playing: Set<String> = []

    static func set(_ source: String, playing isPlaying: Bool) {
        if isPlaying {
            playing.insert(source)
        } else {
            playing.remove(source)
        }
        UIApplication.shared.isIdleTimerDisabled = !playing.isEmpty
    }
}

// Calls back on the main queue when a call, an alarm or another app takes the audio session away
func observeAudioInterruptions(_ handler: @escaping () -> Void) -> NSObjectProtocol {
    NotificationCenter.default.addObserver(
        forName: AVAudioSession.interruptionNotification,
        object: AVAudioSession.sharedInstance(),
        queue: .main
    ) { notification in
        guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              AVAudioSession.InterruptionType(rawValue: raw) == .began else { return }
        handler()
    }
}
