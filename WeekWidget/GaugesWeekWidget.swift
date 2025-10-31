//
//  WeekWidget.swift
//  WeekWidget
//
//  Created by Diego Rivera on 20/10/25.
//

import WidgetKit
import SwiftUI

struct GaugesWeekWidgetEntryView: View {
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

    // Add a formatter that disables grouping separator
    private static var noGroupYearFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale.current
        f.numberStyle = .none
        f.usesGroupingSeparator = false
        return f
    }()

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
    
    private func shortDayMonth(for date: Date) -> some View {
        let day = displayCal.component(.day, from: date)
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = displayCal
        formatter.dateFormat = "MMM"
        let monthName = formatter.string(from: date)
        
        return VStack(spacing: -2) {
            Text("\(day)")
                .font(.callout)
                .bold()
            Text(monthName)
                .font(.system(size: 9, weight: .bold))
        }
        .padding(.bottom, 3)
    }

    var body: some View {
        let (week, totalWeeks) = isoWeekInfo(for: entry.date)
        let yearProgress = Double(week) / Double(totalWeeks)
        let (q, qProgress) = quarterProgress(for: entry.date)
        let dayIndex = dayIndexInWeek(for: entry.date)
        let weekProgress = Double(dayIndex) / 7.0
        let year = displayCal.component(.year, from: entry.date)
        let yearString = GaugesWeekWidgetEntryView.noGroupYearFormatter.string(from: NSNumber(value: year)) ?? "\(year)"

        HStack(alignment: .bottom, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 6) {
                        Text("Week")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(Color("AccentColor"))
                    }
                    .padding(.leading, 6)
                    .padding(.bottom, -6)
                    Text("\(week)")
                        .font(.system(size: 42))
                }
                .padding(.leading, 3)
                Gauge(value: qProgress) {
                    Text("Q\(q)")
                } currentValueLabel: {
                    Text("\(Int(round(qProgress * 100)))%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color("AccentColor"))
                }
                .gaugeStyle(.accessoryCircular)
                .tint(Gradient(colors: [.primary.opacity(0.25), .primary]))
            }
            VStack(alignment: .trailing, spacing: 8) {
                Gauge(value: weekProgress) {
                    Text("\(week)")
                } currentValueLabel: {
                    Text(shortWeekday(for: entry.date))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color("AccentColor"))
                }
                .gaugeStyle(.accessoryCircular)
                .tint(Gradient(colors: [.primary.opacity(0.25), .primary]))
                Gauge(value: yearProgress) {
                    Text(yearString)
                        .font(.caption)
                } currentValueLabel: {
                    shortDayMonth(for: entry.date)
                        .foregroundStyle(Color("AccentColor"))
                }
                .gaugeStyle(.accessoryCircular)
                .tint(Gradient(colors: [.primary.opacity(0.25), .primary]))
            }
        }
    }
}

struct GaugesWeekWidget: Widget {
    let kind: String = "WeekWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            GaugesWeekWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Week Number with Progress Gauges")
        .description("Week number with progress for week, quarter, and year.")
        .supportedFamilies([.systemSmall])
    }
}
