import SwiftUI

struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var log = PracticeLog.shared
    @State private var range: SummaryRange = .week

    enum SummaryRange: String, CaseIterable {
        case week = "This week"
        case month = "This month"
    }

    private var calendar: Calendar { Calendar.current }

    private var interval: DateInterval {
        let component: Calendar.Component = range == .week ? .weekOfYear : .month
        return calendar.dateInterval(of: component, for: Date()) ?? DateInterval(start: Date(), duration: 0)
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

    var body: some View {
        NavigationView {
            List {
                Section {
                    Picker("Range", selection: $range) {
                        ForEach(SummaryRange.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)

                    summary
                        .listRowBackground(Color(hex: "#242424"))
                }

                if log.sessions.isEmpty {
                    Section {
                        Text("Your practice shows up here once you have played for 30 seconds. Short pauses of up to 3 minutes stay in the same session. Stored on this device only.")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "#DDDDDD").opacity(0.6))
                            .listRowBackground(Color(hex: "#242424"))
                    }
                }

                ForEach(groupedByDay, id: \.day) { group in
                    Section(header: Text(dayTitle(group.day))) {
                        ForEach(group.sessions) { session in
                            SessionRow(session: session)
                                .listRowBackground(Color(hex: "#242424"))
                                .swipeActions {
                                    Button(role: .destructive) { log.delete(session) } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: "#1C1C1B"))
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "#DDDDDD"))
                }
            }
        }
        .navigationViewStyle(.stack)
        .preferredColorScheme(.dark)
    }

    private var summary: some View {
        let sessions = log.sessions(in: interval)
        let total = sessions.reduce(0) { $0 + $1.duration }
        let practiceDays = Set(sessions.map { calendar.startOfDay(for: $0.start) }).count
        let perDay = days.map { day in
            sessions.filter { calendar.isDate($0.start, inSameDayAs: day) }.reduce(0) { $0 + $1.duration }
        }
        let peak = max(perDay.max() ?? 0, 60)
        let favourite = Dictionary(grouping: sessions, by: \.title)
            .mapValues { $0.reduce(0) { $0 + $1.duration } }
            .max { $0.value < $1.value }?.key

        return VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 0) {
                Stat(value: Self.format(total), label: "Practised")
                Stat(value: "\(sessions.count)", label: "Sessions")
                Stat(value: "\(practiceDays)", label: "Days")
            }

            // One bar per day, today in orange
            HStack(alignment: .bottom, spacing: range == .week ? 8 : 3) {
                ForEach(Array(days.enumerated()), id: \.offset) { index, day in
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(calendar.isDateInToday(day) ? Color(hex: "#F54206") : Color(hex: "#DDDDDD").opacity(perDay[index] > 0 ? 0.7 : 0.12))
                            .frame(height: max(3, 80 * perDay[index] / peak))
                        if range == .week {
                            Text(day.formatted(.dateTime.weekday(.narrow)))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(Color(hex: "#DDDDDD").opacity(0.5))
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: range == .week ? 100 : 84, alignment: .bottom)
            .accessibilityElement()
            .accessibilityLabel("Practice time per day")

            if let favourite {
                Text("Most practised: \(favourite)")
                    .font(.caption)
                    .foregroundColor(Color(hex: "#DDDDDD").opacity(0.6))
            }
        }
        .padding(.vertical, 8)
    }

    private var groupedByDay: [(day: Date, sessions: [PracticeSession])] {
        let groups = Dictionary(grouping: log.sessions) { calendar.startOfDay(for: $0.start) }
        return groups.keys.sorted(by: >).map { ($0, groups[$0]!.sorted { $0.start > $1.start }) }
    }

    private func dayTitle(_ day: Date) -> String {
        if calendar.isDateInToday(day) { return "Today" }
        if calendar.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide).day().month(.wide))
    }

    static func format(_ seconds: TimeInterval) -> String {
        if seconds < 60 { return "\(Int(seconds)) s" }
        let minutes = Int(seconds / 60)
        if minutes < 60 { return "\(minutes) min" }
        return "\(minutes / 60) h \(minutes % 60) min"
    }
}

private struct Stat: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundColor(Color(hex: "#DDDDDD"))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundColor(Color(hex: "#DDDDDD").opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SessionRow: View {
    let session: PracticeSession

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.kind == .groove ? "graduationcap" : "metronome")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color(hex: "#F54206"))
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color(hex: "#303030")))
            VStack(alignment: .leading, spacing: 2) {
                Text(session.title)
                    .foregroundColor(Color(hex: "#DDDDDD"))
                Text("\(session.start.formatted(date: .omitted, time: .shortened)) · \(session.detail) · \(session.bpm) BPM")
                    .font(.caption)
                    .foregroundColor(Color(hex: "#DDDDDD").opacity(0.55))
                    .lineLimit(1)
            }
            Spacer()
            Text(HistoryView.format(session.duration))
                .font(.system(size: 13, weight: .medium, design: .monospaced))
                .foregroundColor(Color(hex: "#DDDDDD").opacity(0.75))
        }
        .padding(.vertical, 2)
    }
}
