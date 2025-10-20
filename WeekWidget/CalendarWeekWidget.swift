
//
//  WeekWidget.swift
//  WeekWidget
//
//  Created by Diego Rivera on 20/10/25.
//

import WidgetKit
import SwiftUI

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
    
    private func fullWeekday(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.calendar = displayCal
        formatter.setLocalizedDateFormatFromTemplate("EEEE")
        return formatter.string(from: date).capitalized
    }

    private func fullMonthName(for date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale.current
        df.calendar = displayCal
        df.dateFormat = "MMMM"
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
        let (week, _) = isoWeekInfo(for: entry.date)
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
                            .padding(.leading, 6)
                    }
                    .padding(.bottom, -6)
                    Text("\(week)")
                        .font(.system(size: 42))
                }
                .padding(.leading, -6)
                VStack(spacing: -3) {
                    Text(fullWeekday(for: entry.date))
                        .font(.caption.weight(.thin))
                        .foregroundStyle(.secondary)
                        .padding(.bottom, -3)
                    Text("\(dayNumber(entry.date))")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(fullMonthName(for: entry.date))
                        .font(.caption.weight(.thin))
                        .foregroundStyle(.secondary)
                }
                .opacity(0.6)
                .padding(.leading, 9)
                .padding(.bottom, 3)
            }
            .padding(.top, 1)
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
