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
            HStack(alignment: .top) {
                Image(systemName: "rectangle.stack.fill.badge.plus")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .padding(.trailing, 24)
                VStack(alignment: .leading, spacing: 16) {
                    Text("Add Week Number Widgets to Your Home Screen")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("1. Touch and hold an empty area on your Home Screen until the apps jiggle.")
                            Text("2. Tap the '+' button in the top corner to open the Widget Gallery.")
                            Text("3. Search for “Week Number” or scroll to find our widgets.")
                            Text("4. See previews of each widget below.")
                            Text("5. Tap 'Add Widget', then drag it where you like and tap 'Done'.")
                        }
                        .font(.body)
                    }
                    Text("Widget Previews")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 18)
                }
                .frame(width: 460)
                Spacer()
            }
            .padding(.top, 32)
            HStack(alignment: .top, spacing: 32) {
                VStack(alignment: .leading, spacing: 20) {
                    ZStack(alignment: .center) {
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(.ultraThickMaterial)
                            .frame(maxWidth: 170, maxHeight: 170)
                            .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
                        CalendarWeekWidgetEntryView(entry: sampleEntry)
                            .padding(10)
                    }
                    .frame(width: 170, height: 170)
                    VStack(alignment: .leading) {
                        Text("Calendar View with Week Number")
                            .padding(.bottom, 1)
                        Text("Calendar month view with current week highlighted.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 170)
                VStack(alignment: .leading, spacing: 20) {
                    ZStack(alignment: .center) {
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(.ultraThickMaterial)
                            .frame(maxWidth: 170, maxHeight: 170)
                            .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
                        GaugesWeekWidgetEntryView(entry: sampleEntry)
                            .padding(10)
                    }
                    .frame(width: 170, height: 170)
                    VStack(alignment: .leading) {
                        Text("Week Number with Progress Gauges")
                            .padding(.bottom, 1)
                        Text("Week number with progress for week, quarter, and year.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 170)
                VStack(alignment: .leading, spacing: 20) {
                    ZStack(alignment: .center) {
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(.ultraThickMaterial)
                            .frame(maxWidth: 170, maxHeight: 170)
                            .shadow(color: .black.opacity(0.12), radius: 8, y: 2)
                        HybridWeekWidgetEntryView(entry: sampleEntry)
                            .padding(10)
                    }
                    .frame(width: 170, height: 170)
                    VStack(alignment: .leading) {
                        Text("Week Number with Calendar View and Year Progress Gauge")
                            .padding(.bottom, 1)
                        Text("Week number with a two-week calendar and year progress.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 170)
            }
            .padding(.top, 12)
            .padding(.leading, 98)
            .padding(.trailing, 64)
            .padding(.bottom, 32)
        }
        .padding()
        .padding(.leading, 32)
    }
}

#Preview {
    ContentView()
}
