//
//  WeekWidget.swift
//  WeekWidget
//
//  Created by Diego Rivera on 20/10/25.
//

import WidgetKit
import SwiftUI

struct HybridWeekWidgetEntryView: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    
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
    
    private static var noGroupYearFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale.current
        f.numberStyle = .none
        f.usesGroupingSeparator = false
        return f
    }()
    
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

    private func dayNumber(_ date: Date) -> Int { displayCal.component(.day, from: date) }
    private func month(_ date: Date) -> Int { displayCal.component(.month, from: date) }
    private func year(_ date: Date) -> Int { displayCal.component(.year, from: date)}

    var body: some View {
        let (week, totalWeeks) = isoWeekInfo(for: entry.date)
        let yearProgress = Double(week) / Double(totalWeeks)
        let weekStart = startOfISOWeek(containing: entry.date)
        let nextWeekStart = displayCal.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
        let currentWeek = daysForWeek(starting: weekStart)
        let followingWeek = daysForWeek(starting: nextWeekStart)
        let currentMonth = month(entry.date)
        let yr = year(entry.date)
        let yearString = HybridWeekWidgetEntryView.noGroupYearFormatter.string(from: NSNumber(value: yr)) ?? "\(yr)"

        Link(destination: URL(string: "weekapp://opencalendar")!) {
            VStack(alignment: .center, spacing: 14) {
                HStack(alignment: .bottom, spacing: 16) {
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 6) {
                            Text("Week")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Color("AccentColor"))
                        }
                        .padding(.leading, 3)
                        .padding(.bottom, -6)
                        Text("\(week)")
                            .font(.system(size: 42))
                    }
                    .padding(.leading, 6)
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
                .padding(.top, 1)
                .padding(.trailing, 3)
                .frame(maxWidth: .infinity)
                VStack(spacing: 2) {
                    HStack(spacing: 9.4) {
                        ForEach(weekdaySymbolsOrdered(), id: \.self) { sym in
                            Text(sym)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.leading, 18)
                    weekRow(currentWeek, weekNumber: week, highlightDate: entry.date, currentMonth: currentMonth)
                    weekRow(followingWeek, weekNumber: week + 1, highlightDate: entry.date, currentMonth: currentMonth)
                }
                .padding(.trailing, 4)
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func weekRow(
        _ days: [Date],
        weekNumber: Int,
        highlightDate: Date,
        currentMonth: Int
    ) -> some View {
        HStack(spacing: -1) {
            Text("\(weekNumber)")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(-90))
                .frame(width: 18)
            ForEach(days, id: \.self) { (day: Date) in
                let isToday = displayCal.isDate(day, inSameDayAs: highlightDate)
                let isOtherMonth = month(day) != currentMonth
                ZStack(alignment: .center) {
                    if isToday {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(highlightFillColor())
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
    
    private func highlightFillColor() -> Color {
        switch renderingMode {
        case .accented:
            return Color("AccentColor").opacity(0.25)
        default:
            return Color("AccentColor")
        }
    }
}

struct HybridWeekWidget: Widget {
    let kind: String = "HybridWeekWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            HybridWeekWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Week Number with Calendar View and Year Progress Gauge")
        .description("Week number with a two-week calendar and year progress.")
        .supportedFamilies([.systemSmall])
    }
}
