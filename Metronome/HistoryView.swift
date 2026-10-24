import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var log = PracticeLog.shared
    @State private var period: Period = .week
    @State private var anchor = Date()
    @State private var deleted: PracticeSession?
    @State private var undoTask: Task<Void, Never>?

    enum Period: String, CaseIterable {
        case week = "Week"
        case month = "Month"

        var component: Calendar.Component { self == .week ? .weekOfYear : .month }
    }

    private var calendar: Calendar { Calendar.current }

    private var interval: DateInterval {
        calendar.dateInterval(of: period.component, for: anchor) ?? DateInterval(start: anchor, duration: 0)
    }

    private var sessions: [PracticeSession] { log.sessions(in: interval) }
    private var isCurrentPeriod: Bool { interval.contains(Date()) }
    private var canGoBack: Bool { log.sessions.contains { $0.start < interval.start } }

    var body: some View {
        NavigationView {
            List {
                Section {
                    Picker("Period", selection: $period) {
                        ForEach(Period.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                    PeriodNavigator(
                        title: periodTitle,
                        subtitle: periodSubtitle,
                        canGoBack: canGoBack,
                        canGoForward: !isCurrentPeriod,
                        step: step
                    )
                    .listRowBackground(Color.surface)
                }

                if log.sessions.isEmpty && log.live == nil {
                    Section {
                        Text("Your practice shows up here once you have played for 30 seconds. Short pauses of up to 3 minutes stay in the same session. Stored on this device only.")
                            .font(.subheadline)
                            .foregroundColor(Color.textSecondary)
                            .listRowBackground(Color.surface)
                    }
                } else {
                    if period == .week {
                        weekSections
                    } else {
                        monthSections
                    }
                    sessionSections
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.ground)
            .overlay(alignment: .bottom) {
                if deleted != nil {
                    UndoBar(text: "Session deleted", action: undoDelete)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color.textPrimary)
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
    }

    // MARK: - Period

    private var periodTitle: String {
        switch period {
        case .week:
            return "Week \(calendar.component(.weekOfYear, from: interval.start))"
        case .month:
            return interval.start.formatted(.dateTime.month(.wide).year())
        }
    }

    private var periodSubtitle: String {
        switch period {
        case .week:
            let last = calendar.date(byAdding: .day, value: -1, to: interval.end) ?? interval.start
            let sameMonth = calendar.isDate(interval.start, equalTo: last, toGranularity: .month)
            let end = sameMonth ? last.formatted(.dateTime.day()) : last.formatted(.dateTime.month(.abbreviated).day())
            return "\(interval.start.formatted(.dateTime.month(.abbreviated).day())) to \(end)"
        case .month:
            return isCurrentPeriod ? "This month" : PracticeStats.pluralized(practiceDays(in: sessions), "practice day")
        }
    }

    private func step(_ delta: Int) {
        UISelectionFeedbackGenerator().selectionChanged()
        anchor = calendar.date(byAdding: period.component, value: delta, to: anchor) ?? anchor
    }

    private var days: [Date] {
        var result: [Date] = []
        var day = interval.start
        while day < interval.end {
            result.append(day)
            day = calendar.date(byAdding: .day, value: 1, to: day) ?? interval.end
        }
        return result
    }

    private func total(_ list: [PracticeSession]) -> TimeInterval {
        list.reduce(0) { $0 + $1.duration }
    }

    private func practiceDays(in list: [PracticeSession]) -> Int {
        Set(list.map { calendar.startOfDay(for: $0.start) }).count
    }

    private func seconds(on day: Date) -> TimeInterval {
        total(sessions.filter { calendar.isDate($0.start, inSameDayAs: day) })
    }

    // MARK: - Week

    @ViewBuilder
    private var weekSections: some View {
        let total = total(sessions)
        let daysPractised = practiceDays(in: sessions)
        let average = daysPractised > 0 ? total / Double(daysPractised) : 0

        Section {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 0) {
                    Stat(value: Self.format(total), label: "Practice time")
                    Stat(value: "\(daysPractised)/\(days.count)", label: "Practice days")
                    Stat(value: Self.format(average), label: "Per practice day")
                }
                if let comparison = weekComparison(total) {
                    Text(comparison)
                        .font(.caption)
                        .foregroundColor(Color.textSecondary)
                }
            }
            .padding(.vertical, 8)
            .listRowBackground(Color.surface)

            WeekBars(days: days, seconds: days.map(seconds(on:)), calendar: calendar)
                .padding(.vertical, 8)
                .listRowBackground(Color.surface)
        }
    }

    private func weekComparison(_ total: TimeInterval) -> String? {
        guard let previousStart = calendar.date(byAdding: .weekOfYear, value: -1, to: interval.start),
              let previous = calendar.dateInterval(of: .weekOfYear, for: previousStart) else { return nil }
        let before = log.total(in: previous)
        guard before > 0 || total > 0 else { return nil }
        let difference = total - before
        if abs(difference) < 60 { return "Same as the week before" }
        return "\(Self.format(abs(difference))) \(difference > 0 ? "more" : "less") than the week before"
    }

    // MARK: - Month

    @ViewBuilder
    private var monthSections: some View {
        let streak = PracticeStats.longestStreak(sessions, calendar: calendar)
        let progress = PracticeStats.tempoProgress(sessions)

        Section {
            HStack(alignment: .top, spacing: 0) {
                Stat(value: Self.format(total(sessions)), label: "Total")
                Stat(value: "\(practiceDays(in: sessions))/\(days.count)", label: "Practice days")
                Stat(value: PracticeStats.pluralized(streak, "day"), label: "Longest streak")
            }
            .padding(.vertical, 8)
            .listRowBackground(Color.surface)

            MonthHeatmap(days: days, seconds: days.map(seconds(on:)), calendar: calendar)
                .padding(.vertical, 8)
                .listRowBackground(Color.surface)
        }

        if !progress.isEmpty {
            Section("Tempo progress") {
                ForEach(progress, id: \.title) { change in
                    TempoProgressRow(change: change)
                        .listRowBackground(Color.surface)
                }
            }

            Section("Most practised") {
                ForEach(Array(progress.prefix(3).enumerated()), id: \.element.title) { rank, change in
                    HStack(spacing: 12) {
                        Text("\(rank + 1)")
                            .font(.system(size: 13, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color.textSecondary)
                            .frame(width: 16, alignment: .leading)
                        Text(change.title)
                            .foregroundColor(Color.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        Text(Self.format(change.total))
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(Color.textSecondary)
                    }
                    .listRowBackground(Color.surface)
                }
            }
        }
    }

    // MARK: - Sessions

    @ViewBuilder
    private var sessionSections: some View {
        if isCurrentPeriod, log.live != nil {
            Section("Now") {
                // Refreshes on its own while the sheet stays open
                TimelineView(.periodic(from: .now, by: 15)) { _ in
                    if let live = log.live {
                        LiveRow(session: live)
                    }
                }
                .listRowBackground(Color.surface)
            }
        }

        if sessions.isEmpty {
            Section {
                Text(period == .week ? "No practice this week." : "No practice this month.")
                    .font(.subheadline)
                    .foregroundColor(Color.textSecondary)
                    .listRowBackground(Color.surface)
            }
        }

        ForEach(groupedByDay, id: \.day) { group in
            Section(header: Text(dayTitle(group.day))) {
                ForEach(group.sessions) { session in
                    SessionRow(session: session)
                        .listRowBackground(Color.surface)
                        .swipeActions {
                            Button(role: .destructive) { delete(session) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
    }

    private var groupedByDay: [(day: Date, sessions: [PracticeSession])] {
        let groups = Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.start) }
        return groups.keys.sorted(by: >).map { ($0, groups[$0]!.sorted { $0.start > $1.start }) }
    }

    private func dayTitle(_ day: Date) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    // Deleting is instant, the undo bar stays for five seconds
    private func delete(_ session: PracticeSession) {
        log.delete(session)
        undoTask?.cancel()
        withAnimation(.easeOut(duration: 0.2)) { deleted = session }
        undoTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) { deleted = nil }
        }
    }

    private func undoDelete() {
        guard let session = deleted else { return }
        undoTask?.cancel()
        log.restore(session)
        withAnimation(.easeOut(duration: 0.2)) { deleted = nil }
    }

    static func format(_ seconds: TimeInterval) -> String {
        if seconds < 60 { return "\(Int(seconds)) s" }
        let minutes = Int(seconds / 60)
        if minutes < 60 { return "\(minutes) min" }
        return "\(minutes / 60) h \(minutes % 60) min"
    }
}

private struct PeriodNavigator: View {
    let title: String
    let subtitle: String
    let canGoBack: Bool
    let canGoForward: Bool
    let step: (Int) -> Void

    var body: some View {
        HStack {
            arrow("chevron.left", label: "Previous period", enabled: canGoBack) { step(-1) }
            Spacer()
            VStack(spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(Color.textPrimary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
            }
            .accessibilityElement(children: .combine)
            Spacer()
            arrow("chevron.right", label: "Next period", enabled: canGoForward) { step(1) }
        }
    }

    private func arrow(_ symbol: String, label: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(Color.textPrimary.opacity(enabled ? 1 : 0.25))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.borderless)
        .disabled(!enabled)
        .accessibilityLabel(label)
    }
}

private struct Stat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .monospaced))
                .foregroundColor(Color.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text(label)
                .font(.caption)
                .foregroundColor(Color.textSecondary)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

// Seven labelled bars, minutes on top, today outlined in orange, empty days as a short stub
private struct WeekBars: View {
    let days: [Date]
    let seconds: [TimeInterval]
    let calendar: Calendar

    private let maxBar: CGFloat = 96

    var body: some View {
        let peak = max(seconds.max() ?? 0, 60)
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(days.indices, id: \.self) { index in
                let day = days[index]
                let minutes = Self.minutes(seconds[index])
                let isToday = calendar.isDateInToday(day)
                VStack(spacing: 6) {
                    Text(minutes > 0 ? "\(minutes)" : " ")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundColor(isToday ? Color.textPrimary : Color.textSecondary)
                    bar(height: seconds[index] > 0 ? max(8, maxBar * seconds[index] / peak) : 4, isToday: isToday, empty: seconds[index] == 0)
                    Text(weekday(day))
                        .font(.system(size: 11, weight: isToday ? .semibold : .medium))
                        .foregroundColor(isToday ? Color.textPrimary : Color.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("\(day.formatted(.dateTime.weekday(.wide)))\(isToday ? ", today" : ""), \(minutes) min")
            }
        }
        .frame(height: maxBar + 48, alignment: .bottom)
    }

    @ViewBuilder
    private func bar(height: CGFloat, isToday: Bool, empty: Bool) -> some View {
        if isToday {
            RoundedRectangle(cornerRadius: 4)
                .strokeBorder(Color.signal, lineWidth: 2)
                .frame(height: max(height, 8))
        } else {
            RoundedRectangle(cornerRadius: 4)
                .fill(empty ? Color.surfaceRaised : Color.textSecondary)
                .frame(height: height)
        }
    }

    private func weekday(_ day: Date) -> String {
        calendar.shortWeekdaySymbols[calendar.component(.weekday, from: day) - 1]
    }

    // Anything played counts as at least one minute on the bar label
    static func minutes(_ seconds: TimeInterval) -> Int {
        seconds > 0 ? max(1, Int((seconds / 60).rounded())) : 0
    }
}

// Calendar grid, brighter cells mean more practice, today with an orange ring, future days dimmed
private struct MonthHeatmap: View {
    let days: [Date]
    let seconds: [TimeInterval]
    let calendar: Calendar

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(weekdayHeaders.indices, id: \.self) { index in
                    Text(weekdayHeaders[index])
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.textSecondary)
                        .frame(maxWidth: .infinity)
                }
                ForEach(0..<leadingBlanks, id: \.self) { _ in
                    Color.clear.aspectRatio(1, contentMode: .fit)
                }
                ForEach(days.indices, id: \.self) { index in
                    cell(day: days[index], seconds: seconds[index])
                }
            }

            HStack(spacing: 4) {
                Spacer()
                Text("Less")
                ForEach(0..<5, id: \.self) { level in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Self.color(for: level))
                        .frame(width: 12, height: 12)
                }
                Text("More")
            }
            .font(.caption)
            .foregroundColor(Color.textSecondary)
            .accessibilityHidden(true)
        }
    }

    private var weekdayHeaders: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    private var leadingBlanks: Int {
        guard let first = days.first else { return 0 }
        return (calendar.component(.weekday, from: first) - calendar.firstWeekday + 7) % 7
    }

    private func cell(day: Date, seconds: TimeInterval) -> some View {
        let level = PracticeStats.heatLevel(seconds: seconds)
        let isToday = calendar.isDateInToday(day)
        let isFuture = day > Date() && !isToday
        return RoundedRectangle(cornerRadius: 6)
            .fill(Self.color(for: level))
            .aspectRatio(1, contentMode: .fit)
            .overlay(
                Text("\(calendar.component(.day, from: day))")
                    .font(.system(size: 12, weight: isToday ? .bold : .medium, design: .monospaced))
                    .foregroundColor(level >= 3 ? Color.ground : Color.textPrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(isToday ? Color.signal : Color.clear, lineWidth: 2)
            )
            .opacity(isFuture ? 0.35 : 1)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(day.formatted(.dateTime.day().month(.wide)))\(isToday ? ", today" : ""), \(WeekBars.minutes(seconds)) min")
    }

    // Neutral grey steps on the row surface, no orange because brightness alone carries the amount
    static func color(for level: Int) -> Color {
        switch level {
        case 0: return Color.surfaceRaised
        case 1: return Color.textPrimary.opacity(0.2)
        case 2: return Color.textPrimary.opacity(0.35)
        case 3: return Color.textPrimary.opacity(0.55)
        default: return Color.textPrimary.opacity(0.8)
        }
    }
}

private struct TempoProgressRow: View {
    let change: PracticeStats.TempoChange

    var body: some View {
        HStack(spacing: 12) {
            Text(change.title)
                .foregroundColor(Color.textPrimary)
                .lineLimit(1)
            Spacer()
            HStack(spacing: 6) {
                if change.first != change.last {
                    Text("\(change.first)")
                        .foregroundColor(Color.textSecondary)
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.textSecondary)
                }
                Text("\(change.last) BPM")
                    .foregroundColor(Color.textPrimary)
            }
            .font(.system(size: 13, weight: .medium, design: .monospaced))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(change.first == change.last
            ? "\(change.title), \(change.last) BPM"
            : "\(change.title), from \(change.first) to \(change.last) BPM")
    }
}

private struct LiveRow: View {
    let session: PracticeSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.kind == .groove ? "graduationcap" : "metronome")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.textPrimary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.surfaceRaised))
            VStack(alignment: .leading, spacing: 2) {
                Text(session.title)
                    .foregroundColor(Color.textPrimary)
                Text(session.duration < 60 ? "Playing now, under a minute" : "Playing now, \(Int(session.duration / 60)) min")
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
            }
            Spacer()
            Circle()
                .fill(Color.signal)
                .frame(width: 8, height: 8)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 2)
        .accessibilityElement(children: .combine)
    }
}

private struct SessionRow: View {
    let session: PracticeSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.kind == .groove ? "graduationcap" : "metronome")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.textPrimary)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.surfaceRaised))
            VStack(alignment: .leading, spacing: 2) {
                Text(session.title)
                    .foregroundColor(Color.textPrimary)
                Text("\(session.start.formatted(date: .omitted, time: .shortened)) · \(session.detail) · \(session.bpm) BPM")
                    .font(.caption)
                    .foregroundColor(Color.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Text(HistoryView.format(session.duration))
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(Color.textSecondary)
        }
        .padding(.vertical, 2)
    }
}

private struct UndoBar: View {
    let text: String
    let action: () -> Void

    var body: some View {
        HStack {
            Text(text)
                .font(.subheadline)
                .foregroundColor(Color.textPrimary)
            Spacer()
            Button(action: action) {
                Text("Undo")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(Color.signal)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .accessibilityLabel("Undo delete")
        }
        .padding(.leading, 16)
        .padding(.trailing, 8)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.surfaceRaised))
    }
}
