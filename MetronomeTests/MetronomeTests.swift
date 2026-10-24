//
//  MetronomeTests.swift
//  MetronomeTests
//
//  Created by Alexander Friedl on 21.06.25.
//

import Foundation
import Testing
@testable import Metronome

struct PracticeStatsTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        return calendar
    }()

    private func session(_ title: String = "Groove", day: Int, hour: Int = 18, minutes: Double = 10, bpm: Int = 90) -> PracticeSession {
        let start = calendar.date(from: DateComponents(year: 2026, month: 10, day: day, hour: hour))!
        return PracticeSession(kind: .groove, title: title, detail: "Funk", start: start, duration: minutes * 60, bpm: bpm)
    }

    @Test func heatLevelSteps() {
        #expect(PracticeStats.heatLevel(seconds: 0) == 0)
        #expect(PracticeStats.heatLevel(seconds: 30) == 0)
        #expect(PracticeStats.heatLevel(seconds: 5 * 60) == 1)
        #expect(PracticeStats.heatLevel(seconds: 15 * 60) == 2)
        #expect(PracticeStats.heatLevel(seconds: 45 * 60) == 3)
        #expect(PracticeStats.heatLevel(seconds: 90 * 60) == 4)
    }

    @Test func longestStreakCountsConsecutiveDaysOnce() {
        let sessions = [
            session(day: 1), session(day: 2), session(day: 2, hour: 20), session(day: 3),
            session(day: 10), session(day: 11)
        ]
        #expect(PracticeStats.longestStreak(sessions, calendar: calendar) == 3)
        #expect(PracticeStats.longestStreak([], calendar: calendar) == 0)
    }

    @Test func tempoProgressUsesFirstAndLastSession() {
        let sessions = [
            session("Paradiddle", day: 20, bpm: 96),
            session("Paradiddle", day: 5, bpm: 80),
            session("Paradiddle", day: 12, bpm: 88),
            session("Shuffle", day: 7, minutes: 5, bpm: 100)
        ]
        let progress = PracticeStats.tempoProgress(sessions)
        #expect(progress.map(\.title) == ["Paradiddle", "Shuffle"])
        #expect(progress[0].first == 80)
        #expect(progress[0].last == 96)
        #expect(progress[1].first == progress[1].last)
    }

    @Test func pluralUsesSingularForOne() {
        #expect(PracticeStats.pluralized(1, "day") == "1 day")
        #expect(PracticeStats.pluralized(2, "day") == "2 days")
        #expect(PracticeStats.pluralized(0, "day") == "0 days")
    }
}

struct BeatPresetTests {
    private func preset(grid: [Bool], accents: [Bool], bpm: Double = 80) -> BeatPreset {
        BeatPreset(name: "Mine", noteValue: .quarter, bpm: bpm, beatsPerMeasure: 4,
                   gridPattern: grid, accentPattern: accents, gridDisplayMode: .andCounting)
    }

    @Test func matchesByValueIgnoringStepsBeyondTheBar() {
        let saved = preset(grid: [true, true, true, true] + Array(repeating: false, count: 12),
                           accents: [true, false, false, false] + Array(repeating: true, count: 12))
        #expect(saved.matches(noteValue: .quarter, beatsPerMeasure: 4,
                              grid: [true, true, true, true], accents: [true, false, false, false]))
    }

    @Test func differentAccentOrNoteValueDoesNotMatch() {
        let saved = preset(grid: [true, true, true, true], accents: [true, false, false, false])
        #expect(!saved.matches(noteValue: .quarter, beatsPerMeasure: 4,
                               grid: [true, true, true, true], accents: [true, true, false, false]))
        #expect(!saved.matches(noteValue: .eighth, beatsPerMeasure: 4,
                               grid: [true, true, true, true], accents: [true, false, false, false]))
    }
}
