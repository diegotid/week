//
//  WeekWidgetProvider.swift
//  WeekWidgetExtension
//
//  Created by Diego Rivera on 21/10/25.
//

import WidgetKit

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> Void) {
        completion(SimpleEntry(date: Date()))
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
        var entries: [SimpleEntry] = []
        let now = Date()
        var cal = Calendar(identifier: .iso8601)
        cal.timeZone = .current
        entries.append(SimpleEntry(date: now))
        let startOfTomorrow = cal.startOfDay(for: cal.date(byAdding: .day, value: 1, to: now)!)
        for dayOffset in 0..<14 {
            if let entryDate = cal.date(byAdding: .day, value: dayOffset, to: startOfTomorrow) {
                entries.append(SimpleEntry(date: entryDate))
            }
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}
