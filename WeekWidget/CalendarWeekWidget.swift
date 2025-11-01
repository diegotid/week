//
//  WeekWidget.swift
//  WeekWidget
//
//  Created by Diego Rivera on 20/10/25.
//

import WidgetKit
import SwiftUI

struct CalendarWeekWidgetEntryView: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    
    var entry: SimpleEntry
    var showHeader: Bool = true

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

    private func dayNumber(_ date: Date) -> Int { displayCal.component(.day, from: date) }
    private func month(_ date: Date) -> Int { displayCal.component(.month, from: date) }
    private func year(_ date: Date) -> Int { displayCal.component(.year, from: date)}

    private func weekStartDatesForMonth(containing date: Date) -> [Date] {
        guard let firstOfMonth = displayCal.date(from: displayCal.dateComponents([.year, .month], from: date)),
              let range = displayCal.range(of: .day, in: .month, for: date) else {
            return []
        }
        let firstWeekStart = startOfISOWeek(containing: firstOfMonth)
        let lastOfMonth = displayCal.date(byAdding: .day, value: range.count - 1, to: firstOfMonth)!
        let lastWeekStart = startOfISOWeek(containing: lastOfMonth)
        var weekStarts: [Date] = []
        var current = firstWeekStart
        while current <= lastWeekStart {
            weekStarts.append(current)
            guard let next = displayCal.date(byAdding: .day, value: 7, to: current) else { break }
            current = next
        }
        return weekStarts
    }

    var body: some View {
        let (week, _) = isoWeekInfo(for: entry.date)
        let currentMonth = month(entry.date)
        let weekStarts = weekStartDatesForMonth(containing: entry.date)

        VStack(alignment: .center, spacing: 6) {
            if showHeader {
                HStack(alignment: .bottom, spacing: 3) {
                    Text("Week")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color("AccentColor"))
                    Text("\(week)")
                        .font(.system(size: 12, weight: .bold))
                        .bold()
                    Spacer()
                    Text(monthYearString(for: entry.date))
                        .font(.system(size: 11))
                }
                .padding(.horizontal, 8)
            }
            VStack(spacing: 2) {
                HStack(spacing: 0) {
                    Spacer(minLength: 18)
                    ForEach(weekdaySymbolsOrdered(), id: \.self) { sym in
                        Text(sym)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(width: 18)
                    }
                }
                ForEach(weekStarts, id: \.self) { weekStart in
                    let weekNumber = cal.component(.weekOfYear, from: weekStart)
                    let weekDays = daysForWeek(starting: weekStart)
                    weekRow(weekDays,
                            weekNumber: weekNumber,
                            highlightDate: entry.date,
                            currentMonth: currentMonth,
                            isCurrent: weekNumber == week)
                }
            }
            .padding(.trailing, 4)
        }
    }

    @ViewBuilder
    private func weekRow(
        _ days: [Date],
        weekNumber: Int,
        highlightDate: Date,
        currentMonth: Int,
        isCurrent: Bool = false
    ) -> some View {
        HStack(spacing: -1) {
            if isCurrent {
                Text("\(weekNumber)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color("AccentColor"))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 18)
            } else {
                Text("\(weekNumber)")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(-90))
                    .frame(width: 18)
            }
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
                        .fontWeight(isToday ? .bold : .regular)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundStyle(isToday ? .white : (isOtherMonth ? .secondary : .primary))
                        .frame(width: 14, height: 14)
                }
                .frame(width: 18, height: 18)
            }
        }
        .overlay(
            Group {
                if isCurrent {
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary, lineWidth: 1)
                }
            }
        )
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

struct CalendarWeekWidget: Widget {
    let kind: String = "CalendarWeekWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            CalendarWeekWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Calendar View with Week Number")
        .description("Calendar month view with current week highlighted.")
        .supportedFamilies([.systemSmall])
    }
}
