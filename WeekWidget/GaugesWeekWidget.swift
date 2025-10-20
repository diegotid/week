//
//  WeekWidget.swift
//  WeekWidget
//
//  Created by Diego Rivera on 20/10/25.
//

import WidgetKit
import SwiftUI

struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        SimpleEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        let now = Date()
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .current
        entries.append(SimpleEntry(date: now, configuration: configuration))
        let startOfTomorrow = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: now)!)
        for dayOffset in 0..<14 {
            if let entryDate = cal.date(byAdding: .day, value: dayOffset, to: startOfTomorrow) {
                entries.append(SimpleEntry(date: entryDate, configuration: configuration))
            }
        }
        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct GaugesWeekWidgetEntryView : View {
    var entry: Provider.Entry

    private var cal: Calendar {
        var c = Calendar(identifier: .iso8601)
        c.timeZone = .current
        return c
    }
    
    private var displayCal: Calendar {
        var c = Calendar.current
        c.timeZone = .current
        return c
    }

    private func isoWeekInfo(for date: Date) -> (week: Int, totalWeeks: Int) {
        let week = cal.component(.weekOfYear, from: date)
        let totalWeeks = cal.range(of: .weekOfYear, in: .yearForWeekOfYear, for: date)?.count ?? 52
        return (week, totalWeeks)
    }

    private func quarterProgress(for date: Date) -> (q: Int, progress: Double) {
        let q = cal.component(.quarter, from: date)
        guard let interval = cal.dateInterval(of: .quarter, for: date) else { return (q, 0) }
        let progress = min(max(date.timeIntervalSince(interval.start) / interval.duration, 0), 1)
        return (q, progress)
    }

    private func dayIndexInWeek(for date: Date) -> Int {
        guard let weekInterval = displayCal.dateInterval(of: .weekOfYear, for: date) else { return 1 }
        let days = displayCal.dateComponents([.day], from: weekInterval.start, to: date).day ?? 0
        return min(max(days + 1, 1), 7)
    }
    
    private func shortWeekday(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = displayCal
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter.string(from: date).capitalized
    }
    
    private func shortDayMonth(for date: Date) -> String {
        let day = displayCal.component(.day, from: date)
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = displayCal
        formatter.dateFormat = "MMMM"
        let monthName = formatter.string(from: date)
        if let firstLetter = monthName.first {
            return "\(day)\(String(firstLetter))"
        } else {
            return "\(day)"
        }
    }

    var body: some View {
        let (week, totalWeeks) = isoWeekInfo(for: entry.date)
        let yearProgress = Double(week) / Double(totalWeeks)
        let (q, qProgress) = quarterProgress(for: entry.date)
        let dayIndex = dayIndexInWeek(for: entry.date)
        let weekProgress = Double(dayIndex) / 7.0

        HStack(alignment: .bottom, spacing: 18) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Text("Week")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 6)
                    .padding(.bottom, -6)
                    Text("\(week)")
                        .font(.system(size: 42))
                }
                .padding(.leading, 3)
                Gauge(value: weekProgress) {
                    Text("\(week)")
                        .foregroundStyle(.secondary)
                } currentValueLabel: {
                    Text(shortWeekday(for: entry.date))
                        .font(.caption2)
                }
                .gaugeStyle(.accessoryCircular)
                .tint(Gradient(colors: [.primary.opacity(0.25), .primary]))
            }
            VStack(alignment: .trailing, spacing: 14) {
                Gauge(value: yearProgress) {
                    Text("Year")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } currentValueLabel: {
                    Text("...\(totalWeeks)")
                        .font(.callout)
                }
                .gaugeStyle(.accessoryCircular)
                .tint(Gradient(colors: [.primary.opacity(0.25), .primary]))
                Gauge(value: qProgress) {
                    Text("Q\(q)")
                        .foregroundStyle(.secondary)
                } currentValueLabel: {
                    Text("\(Int(round(qProgress * 100)))%")
                        .font(.caption2)
                }
                .gaugeStyle(.accessoryCircular)
                .tint(Gradient(colors: [.primary.opacity(0.25), .primary]))
            }
        }
    }
}

struct CalendarWeekWidgetEntryView: View {
    var entry: Provider.Entry

    private var cal: Calendar {
        var c = Calendar(identifier: .iso8601)
        c.timeZone = .current
        return c
    }
    
    private var displayCal: Calendar {
        var c = Calendar.current
        c.timeZone = .current
        return c
    }
    
    private func weekdaySymbolsOrdered() -> [String] {
        let df = DateFormatter()
        df.locale = Locale.current
        df.calendar = displayCal
        let raw = df.veryShortStandaloneWeekdaySymbols ?? df.shortStandaloneWeekdaySymbols
        let symbols = raw ?? ["S","M","T","W","T","F","S"]
        let start = max(min(displayCal.firstWeekday - 1, 6), 0)
        return Array(symbols[start...] + symbols[..<start])
    }

    private func monthYearString(for date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale.current
        df.calendar = displayCal
        df.setLocalizedDateFormatFromTemplate("LLL yyyy")
        return df.string(from: date)
    }

    private func isoWeekInfo(for date: Date) -> (week: Int, totalWeeks: Int) {
        let week = cal.component(.weekOfYear, from: date)
        let totalWeeks = cal.range(of: .weekOfYear, in: .yearForWeekOfYear, for: date)?.count ?? 52
        return (week, totalWeeks)
    }

    private func startOfISOWeek(containing date: Date) -> Date {
        let start = displayCal.dateInterval(of: .weekOfYear, for: date)?.start ?? displayCal.startOfDay(for: date)
        return start
    }

    private func daysForWeek(starting start: Date) -> [Date] {
        (0..<7).compactMap { displayCal.date(byAdding: .day, value: $0, to: start) }
    }

    private func dayNumber(_ date: Date) -> Int { displayCal.component(.day, from: date) }
    private func month(_ date: Date) -> Int { displayCal.component(.month, from: date) }

    var body: some View {
        let (week, totalWeeks) = isoWeekInfo(for: entry.date)
        let yearProgress = Double(week) / Double(totalWeeks)
        let weekStart = startOfISOWeek(containing: entry.date)
        let nextWeekStart = displayCal.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
        let currentWeek = daysForWeek(starting: weekStart)
        let followingWeek = daysForWeek(starting: nextWeekStart)
        let currentMonth = month(entry.date)

        VStack(alignment: .center, spacing: 16) {
            HStack(alignment: .bottom, spacing: 22) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Text("Week")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.leading, 6)
                    .padding(.bottom, -6)
                    Text("\(week)")
                        .font(.system(size: 42))
                }
                Gauge(value: yearProgress) {
                    Text("Year")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } currentValueLabel: {
                    Text("...\(totalWeeks)")
                        .font(.callout)
                }
                .gaugeStyle(.accessoryCircular)
                .tint(Gradient(colors: [.primary.opacity(0.25), .primary]))
            }
            .padding(.top, 1)
            .padding(.leading, 3)
            .frame(maxWidth: .infinity)
            VStack(spacing: 4) {
                HStack(spacing: 0) {
                    Spacer(minLength: 18)
                    ForEach(weekdaySymbolsOrdered(), id: \.self) { sym in
                        Text(sym)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 18)
                    }
                }
                weekRow(currentWeek, weekNumber: week, highlightDate: entry.date, currentMonth: currentMonth)
                weekRow(followingWeek, weekNumber: week + 1, highlightDate: entry.date, currentMonth: currentMonth)
            }
            .padding(.trailing, 4)
        }
    }

    @ViewBuilder
    private func weekRow(
        _ days: [Date],
        weekNumber: Int,
        highlightDate: Date,
        currentMonth: Int
    ) -> some View {
        HStack(spacing: 0) {
            Text("\(weekNumber)")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(-90))
                .frame(width: 18)
            ForEach(days, id: \.self) { (day: Date) in
                let isToday = displayCal.isDate(day, inSameDayAs: highlightDate)
                let isOtherMonth = month(day) != currentMonth
                ZStack(alignment: .center) {
                    if isToday {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.primary.opacity(0.25))
                            .frame(width: 18, height: 18)
                    }
                    Text("\(dayNumber(day))")
                        .font(.caption2)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundStyle(isToday ? .white : (isOtherMonth ? .secondary : .primary))
                        .frame(width: 14, height: 14)
                }
                .frame(width: 18, height: 18)
            }
        }
    }
}

struct GaugesWeekWidget: Widget {
    let kind: String = "WeekWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            GaugesWeekWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Week Number with Progress Gauges")
        .description("Week number with progress for week, quarter, and year.")
        .supportedFamilies([.systemSmall])
    }
}

struct CalendarWeekWidget: Widget {
    let kind: String = "CalendarWeekWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            CalendarWeekWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Week Number with Calendar View")
        .description("Week number with a compact calendar view showing 2 weeks.")
        .supportedFamilies([.systemSmall])
    }
}
