//
//  WeekWidgetProvider.swift
//  WeekWidgetExtension
//
//  Created by Diego Rivera on 21/10/25.
//

import WidgetKit

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
