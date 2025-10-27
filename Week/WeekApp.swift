//
//  WeekApp.swift
//  Week
//
//  Created by Diego Rivera on 20/10/25.
//

import SwiftUI
import AppKit

@main
struct WeekApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.openWindow) var openWindow
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .fixedWindow(size: CGSize(width: 820, height: 660))
        }
        Window("About Week Number", id: "about") {
            About()
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Week Number") {
                    openWindow(id: "about")
                }
            }
            CommandGroup(replacing: .newItem) { }
            CommandGroup(replacing: .saveItem) { }
            CommandGroup(replacing: .importExport) { }
            CommandGroup(replacing: .printItem) { }
            CommandGroup(replacing: .toolbar) { }
            CommandGroup(replacing: .sidebar) { }
            CommandGroup(replacing: .windowArrangement) { }
            CommandGroup(replacing: .undoRedo) { }
            CommandGroup(replacing: .pasteboard) { }
        }
        .commands {
            CommandGroup(replacing: .textEditing) { }
            CommandGroup(replacing: .help) { }
        }
    }
}

struct WeekStatusPanelView: View {
    let entry = SimpleEntry(date: Date())
    
    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            GaugesWeekWidgetEntryView(entry: entry)
                .padding(.horizontal, 16)
            CalendarWeekWidgetEntryView(entry: entry, showHeader: false)
                .padding(.horizontal, 16)
        }
        .padding(.leading, 8)
        .padding(.bottom, 18)
        .padding(.top, 22)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate {
    var statusItem: NSStatusItem?
    var updateTimer: Timer?
    var popover: NSPopover?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        scheduleMidnightUpdate()
    }

    func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.title = weekNumberTitle(for: Date())
        item.button?.target = self
        item.button?.action = #selector(statusItemClicked(_:))
        self.statusItem = item
    }
    
    @objc func statusItemClicked(_ sender: Any?) {
        if let popover = popover, popover.isShown {
            popover.performClose(sender)
            return
        }
        showPopover()
    }
    
    func showPopover() {
        guard let button = statusItem?.button else {
            return
        }
        let popover = NSPopover()
        popover.contentSize = NSSize(width: 340, height: 510)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self
        popover.contentViewController = NSHostingController(rootView: WeekStatusPanelView())
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        self.popover = popover
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func popoverDidClose(_ notification: Notification) {
        self.popover = nil
    }
    
    func weekNumberTitle(for date: Date) -> String {
        let week = Calendar.current.component(.weekOfYear, from: date)
        return "Week \(week)"
    }
    
    func scheduleMidnightUpdate() {
        updateTimer?.invalidate()
        let now = Date()
        if let nextMidnight = Calendar.current.nextDate(after: now, matching: DateComponents(hour:0, minute:0, second:5), matchingPolicy: .nextTime) {
            updateTimer = Timer(fireAt: nextMidnight, interval: 0, target: self, selector: #selector(updateWeekNumber), userInfo: nil, repeats: false)
            RunLoop.main.add(updateTimer!, forMode: .common)
        }
    }
    
    @objc func updateWeekNumber() {
        statusItem?.button?.title = weekNumberTitle(for: Date())
        scheduleMidnightUpdate()
    }
}
