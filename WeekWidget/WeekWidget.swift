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

struct WeekWidgetEntryView : View {
    var entry: Provider.Entry

    private var cal: Calendar {
        var c = Calendar(identifier: .iso8601)
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
        guard let weekInterval = cal.dateInterval(of: .weekOfYear, for: date) else { return 1 }
        let days = cal.dateComponents([.day], from: weekInterval.start, to: date).day ?? 0
        return min(max(days + 1, 1), 7)
    }
    
    private func shortWeekday(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = cal
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        return formatter.string(from: date).capitalized
    }
    
    private func shortDayMonth(for date: Date) -> String {
        let day = cal.component(.day, from: date)
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = cal
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

        HStack(alignment: .bottom, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 6)
                        .padding(.bottom, -6)
                    Text("\(week)")
                        .font(.system(size: 42))
                }
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
            VStack(alignment: .trailing, spacing: 8) {
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
                    Text(shortDayMonth(for: entry.date))
                        .font(.callout)
                }
                .gaugeStyle(.accessoryCircular)
                .tint(Gradient(colors: [.primary.opacity(0.25), .primary]))
            }
        }
    }
}

struct WeekWidget: Widget {
    let kind: String = "WeekWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            WeekWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .supportedFamilies([.systemSmall])
    }
}
