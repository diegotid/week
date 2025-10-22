//
//  ContentView.swift
//  Week
//
//  Created by Diego Rivera on 20/10/25.
//

import SwiftUI
import WeekWidgetExtension

struct ContentView: View {
    let sampleEntry = SimpleEntry(date: Date())

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Image(systemName: "rectangle.stack.fill.badge.plus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .padding(.top, 32)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Add Week Widgets to Your Home Screen")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("1. Touch and hold an empty area on your Home Screen until the apps jiggle.")
                        Text("2. Tap the '+' button in the top corner to open the Widget Gallery.")
                        Text("3. Search for “Week” or scroll to find our widgets.")
                        Text("4. See previews of each widget below.")
                        Text("5. Tap 'Add Widget', then drag it where you like and tap 'Done'.")
                    }
                    .font(.body)
                    Text("Widget Previews")
                        .font(.headline)
                        .padding(.top, 18)
                    HStack(alignment: .top, spacing: 20) {
                        Label("Calendar View with Week Number and Current Week Highlight", systemImage: "calendar")
                            .font(.subheadline)
                        Spacer()
                        ZStack(alignment: .center) {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(.ultraThickMaterial)
                                .frame(maxWidth: 160, maxHeight: 160)
                                .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
                            CalendarWeekWidgetEntryView(entry: sampleEntry)
                                .padding(10)
                        }
                        .frame(maxWidth: 160, maxHeight: 160)
                    }
                    .frame(maxWidth: 460)
                    HStack(alignment: .top, spacing: 20) {
                        Label("Week Number with Week, Quarter and Year Progress Gauges", systemImage: "gauge.with.dots.needle.33percent")
                            .font(.subheadline)
                        Spacer()
                        ZStack(alignment: .center) {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(.ultraThickMaterial)
                                .frame(maxWidth: 160, maxHeight: 160)
                                .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
                            GaugesWeekWidgetEntryView(entry: sampleEntry)
                                .padding(10)
                        }
                        .frame(maxWidth: 160, maxHeight: 160)
                    }
                    .frame(maxWidth: 460)
                    HStack(alignment: .top, spacing: 20) {
                        Label("Week Number with 2-Week Calendar View and Year Progress Gauge", systemImage: "calendar.badge.clock")
                            .font(.subheadline)
                        Spacer()
                        ZStack(alignment: .center) {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(.ultraThickMaterial)
                                .frame(maxWidth: 160, maxHeight: 160)
                                .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
                            HybridWeekWidgetEntryView(entry: sampleEntry)
                                .padding(10)
                        }
                        .frame(maxWidth: 160, maxHeight: 160)
                    }
                    .frame(maxWidth: 460)
                }
                .padding(.vertical)
                Spacer()
            }
            .frame(width: 600)
        }
    }
}

#Preview {
    ContentView()
}
