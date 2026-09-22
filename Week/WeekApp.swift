//
//  WeekApp.swift
//  Week
//
//  Created by Diego Rivera on 20/10/25.
//

import SwiftUI
import AppKit
import CoreText

@main
struct WeekApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Week Number") {
                    appDelegate.showAboutWindow()
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

private final class WeekDockTileView: NSView {
    var drawIcon: ((NSRect) -> Void)?

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawIcon?(bounds)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, NSPopoverDelegate, NSWindowDelegate {
    var statusItem: NSStatusItem?
    var updateTimer: Timer?
    private var iconStyleTimer: Timer?
    private var lastDockStyle: DockStyle?
    private var lastDockTintSetting: String?
    var popover: NSPopover?
    private var mainWindow: NSWindow?
    private var aboutWindow: NSWindow?
    private let calendarApplicationPaths = [
        "/System/Applications/Calendar.app",
        "/Applications/Calendar.app"
    ]
    private var hasFinishedLaunching = false
    private var shouldOpenCalendarAfterLaunch = false
    private var pendingMainWindowOpen: DispatchWorkItem?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
        hasFinishedLaunching = true
        setupStatusItem()
        scheduleMidnightUpdate()
        updateDockIcon()
        watchIconStyle()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidBecomeActive(_:)),
                                               name: NSApplication.didBecomeActiveNotification,
                                               object: nil)
        
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            if self.shouldOpenCalendarAfterLaunch {
                self.shouldOpenCalendarAfterLaunch = false
                self.forwardWidgetLaunchToCalendar()
            } else {
                self.showMainWindow()
            }
        }
        pendingMainWindowOpen = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2, execute: workItem)
    }
    
    @objc func handleURLEvent(_ event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else { return }

        handleOpenURL(url)
    }

    private func handleOpenURL(_ url: URL) {
        if url.scheme == "weekapp" && url.host == "opencalendar" {
            if hasFinishedLaunching {
                pendingMainWindowOpen?.cancel()
                pendingMainWindowOpen = nil
                mainWindow?.close()
                forwardWidgetLaunchToCalendar()
            } else {
                shouldOpenCalendarAfterLaunch = true
            }
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !flag else { return false }
        showMainWindow()
        return true
    }

    @objc private func appDidBecomeActive(_ notification: Notification) {
        updateDockIcon()
    }

    private func forwardWidgetLaunchToCalendar() {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        let workspace = NSWorkspace.shared
        let fileManager = FileManager.default

        if let calendarPath = calendarApplicationPaths.first(where: { fileManager.fileExists(atPath: $0) }) {
            let calendarURL = URL(fileURLWithPath: calendarPath)
            workspace.openApplication(at: calendarURL, configuration: configuration) { _, _ in
                DispatchQueue.main.async {
                    self.mainWindow?.close()
                    NSApp.hide(nil)
                }
            }
        }
    }

    private func showMainWindow() {
        if let existingWindow = mainWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let rootView = ContentView()
        let controller = NSHostingController(rootView: rootView)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 820, height: 660),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "Week Number"
        window.contentViewController = controller
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.setContentSize(CGSize(width: 820, height: 660))
        window.minSize = CGSize(width: 820, height: 660)
        window.maxSize = CGSize(width: 820, height: 660)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        mainWindow = window
    }

    func showAboutWindow() {
        if let existingWindow = aboutWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let controller = NSHostingController(rootView: About())
        let window = NSWindow(
            contentRect: NSRect(
                x: 0,
                y: 0,
                width: Frame.aboutWindowWidth,
                height: Frame.aboutWindowHeight
            ),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.title = "About Week Number"
        window.contentViewController = controller
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.minSize = CGSize(width: Frame.aboutWindowWidth, height: Frame.aboutWindowHeight)
        window.maxSize = CGSize(width: Frame.aboutWindowWidth, height: Frame.aboutWindowHeight)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        aboutWindow = window
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

    @objc func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else {
            return
        }

        if window === mainWindow {
            mainWindow = nil
        } else if window === aboutWindow {
            aboutWindow = nil
        }
    }
    
    func weekNumberTitle(for date: Date) -> String {
        let week = isoWeekNumber(for: date)
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
        updateDockIcon()
        scheduleMidnightUpdate()
    }

    private func updateDockIcon() {
        let date = Date()
        let week = isoWeekNumber(for: date)
        let style = currentDockStyle()
        lastDockStyle = style
        lastDockTintSetting = dockTintSetting()
        let tintColor = currentDockTintColor()
        let tile = NSApp.dockTile
        let view = (tile.contentView as? WeekDockTileView)
            ?? WeekDockTileView(frame: NSRect(origin: .zero, size: tile.size))
        view.autoresizingMask = [.width, .height]
        view.drawIcon = { [weak self] bounds in
            self?.drawDockIcon(in: bounds, week: week, date: date,
                               style: style, tintColor: tintColor)
        }
        if tile.contentView !== view { tile.contentView = view }
        tile.display()
    }

    private enum DockStyle: Equatable {
        case regularLight, regularDark
        case clearLight, clearDark
        case tintedLight, tintedDark
    }

    private func currentDockStyle() -> DockStyle {
        // macOS records Icon & widget style separately from light/dark app appearance.
        let setting = UserDefaults.standard.string(forKey: "AppleIconAppearanceTheme") ?? ""
        let isDark = NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
        switch setting {
        case "ClearLight": return .clearLight
        case "ClearDark": return .clearDark
        case "ClearAutomatic": return isDark ? .clearDark : .clearLight
        case "TintedLight": return .tintedLight
        case "TintedDark": return .tintedDark
        case "TintedAutomatic": return isDark ? .tintedDark : .tintedLight
        case "RegularDark": return .regularDark
        case "RegularAutomatic": return isDark ? .regularDark : .regularLight
        default: return .regularLight
        }
    }

    private func watchIconStyle() {
        iconStyleTimer?.invalidate()
        let timer = Timer(timeInterval: 5, repeats: true) { [weak self] _ in
            guard let self else { return }
            guard self.currentDockStyle() != self.lastDockStyle
                    || self.dockTintSetting() != self.lastDockTintSetting else { return }
            self.updateDockIcon()
        }
        RunLoop.main.add(timer, forMode: .common)
        iconStyleTimer = timer
    }

    private func dockTintSetting() -> String {
        let defaults = UserDefaults.standard
        return "\(defaults.string(forKey: "AppleIconAppearanceTintColor") ?? "")|"
            + (defaults.string(forKey: "AppleIconAppearanceCustomTintColor") ?? "")
    }

    private func currentDockTintColor() -> NSColor {
        let defaults = UserDefaults.standard
        let selection = defaults.string(forKey: "AppleIconAppearanceTintColor") ?? "Blue"
        if selection == "Other",
           let components = defaults.string(forKey: "AppleIconAppearanceCustomTintColor")?
                .split(whereSeparator: { $0.isWhitespace }).compactMap({ Double($0) }),
           components.count >= 3 {
            return NSColor(deviceRed: components[0], green: components[1],
                           blue: components[2], alpha: 1)
        }
        switch selection.lowercased() {
        case "purple": return .systemPurple
        case "pink": return .systemPink
        case "red": return .systemRed
        case "orange": return .systemOrange
        case "yellow": return .systemYellow
        case "green": return .systemGreen
        case "gray", "grey": return .systemGray
        default: return .systemBlue
        }
    }

    private func drawDockIcon(in rect: NSRect, week: Int, date: Date,
                              style: DockStyle, tintColor: NSColor) {
        // The reference artwork is 1024 points square. Scale the complete design
        // together so the text, rounded face, and progress marks stay aligned.
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        let padding = min(rect.width, rect.height) * 0.09
        let iconRect = rect.insetBy(dx: padding, dy: padding)
        context.saveGState()
        context.translateBy(x: iconRect.minX, y: iconRect.minY)
        context.scaleBy(x: iconRect.width / 1024, y: iconRect.height / 1024)

        let face = NSBezierPath(roundedRect: NSRect(x: 0, y: 0, width: 1024, height: 1024),
                                xRadius: 256, yRadius: 256)
        let wColor: NSColor
        let numberColor: NSColor
        let barColor: NSColor
        let dotColor: NSColor
        switch style {
        case .regularLight:
            NSGradient(starting: .white,
                       ending: NSColor(deviceRed: 245 / 255, green: 245 / 255,
                                       blue: 245 / 255, alpha: 1))?
                .draw(in: face, angle: -90)
            wColor = NSColor(deviceRed: 235 / 255, green: 52 / 255, blue: 37 / 255, alpha: 1)
            numberColor = .black
            barColor = NSColor(deviceRed: 171 / 255, green: 171 / 255,
                               blue: 171 / 255, alpha: 1)
            dotColor = wColor
        case .regularDark:
            NSGradient(starting: NSColor(deviceRed: 30 / 255, green: 30 / 255,
                                        blue: 30 / 255, alpha: 1),
                       ending: NSColor(deviceRed: 15 / 255, green: 15 / 255,
                                       blue: 15 / 255, alpha: 1))?
                .draw(in: face, angle: -90)
            wColor = NSColor(deviceRed: 235 / 255, green: 52 / 255, blue: 37 / 255, alpha: 1)
            numberColor = .white
            barColor = NSColor(deviceRed: 171 / 255, green: 171 / 255,
                               blue: 171 / 255, alpha: 1)
            dotColor = wColor
        case .clearLight, .clearDark:
            // The Dock composites the face over its own backdrop. Clear Dark
            // uses dark glass, like the other clear icons in the Dock.
            let isDarkClear = style == .clearDark
            context.saveGState()
            let shadow = NSShadow()
            shadow.shadowColor = NSColor(white: 0, alpha: 0.28)
            shadow.shadowBlurRadius = 18
            shadow.shadowOffset = NSSize(width: 0, height: -8)
            shadow.set()
            (isDarkClear
                ? NSColor(deviceRed: 0.02, green: 0.05, blue: 0.08, alpha: 0.55)
                : NSColor(white: 1, alpha: 0.18)).setFill()
            face.fill()
            context.restoreGState()
            NSColor(white: 1, alpha: isDarkClear ? 0.12 : 0.22).setStroke()
            face.lineWidth = 6
            face.stroke()
            wColor = NSColor(white: 1, alpha: isDarkClear ? 0.34 : 0.23)
            numberColor = .white
            barColor = NSColor(white: 1, alpha: isDarkClear ? 0.58 : 0.45)
            dotColor = isDarkClear ? .white : NSColor(white: 0, alpha: 0.28)
        case .tintedLight:
            let tint = tintColor.usingColorSpace(.deviceRGB) ?? .systemBlue
            NSGradient(starting: NSColor(deviceRed: 0.58 + tint.redComponent * 0.42,
                                         green: 0.58 + tint.greenComponent * 0.42,
                                         blue: 0.58 + tint.blueComponent * 0.42, alpha: 1),
                       ending: NSColor(deviceRed: 0.47 + tint.redComponent * 0.43,
                                       green: 0.47 + tint.greenComponent * 0.43,
                                       blue: 0.47 + tint.blueComponent * 0.43, alpha: 1))?
                .draw(in: face, angle: -90)
            wColor = NSColor(white: 0, alpha: 0.50)
            numberColor = NSColor(white: 0, alpha: 0.78)
            barColor = NSColor(white: 0, alpha: 0.30)
            dotColor = NSColor(white: 0, alpha: 0.72)
        case .tintedDark:
            let tint = tintColor.usingColorSpace(.deviceRGB) ?? .systemBlue
            NSGradient(starting: NSColor(deviceRed: 0.06 + tint.redComponent * 0.08,
                                         green: 0.08 + tint.greenComponent * 0.19,
                                         blue: 0.10 + tint.blueComponent * 0.15, alpha: 1),
                       ending: NSColor(deviceRed: 0.04 + tint.redComponent * 0.08,
                                       green: 0.06 + tint.greenComponent * 0.17,
                                       blue: 0.08 + tint.blueComponent * 0.14, alpha: 1))?
                .draw(in: face, angle: -90)
            wColor = tintColor.withAlphaComponent(0.85)
            numberColor = tintColor
            barColor = tintColor.withAlphaComponent(0.55)
            dotColor = tintColor
        }
        face.addClip()

        let quarter = quarterIndex(for: week, on: date)
        for index in 0..<4 {
            let bar = NSBezierPath(roundedRect: NSRect(x: 162 + 187 * index,
                                                       y: 229,
                                                       width: 163,
                                                       height: 52),
                                   xRadius: 26, yRadius: 26)
            barColor.setFill()
            bar.fill()
        }
        dotColor.setFill()
        NSBezierPath(ovalIn: NSRect(x: 204 + 187 * quarter,
                                    y: 214, width: 81, height: 81)).fill()

        drawWeekMark(week: week, in: context, wColor: wColor, numberColor: numberColor)
        context.restoreGState()
    }

    private func drawWeekMark(week: Int, in context: CGContext,
                              wColor: NSColor, numberColor: NSColor) {
        let font = NSFont(name: "SF Pro Rounded Light", size: 460)
            ?? NSFont.systemFont(ofSize: 460, weight: .light)
        let text = NSAttributedString(string: String(week), attributes: [
            .font: font,
            .foregroundColor: numberColor
        ])
        let line = CTLineCreateWithAttributedString(text)
        let ink = CTLineGetImageBounds(line, context)
        guard ink.width > 0, ink.height > 0 else { return }
        let numberScale = 345 / ink.height
        let numberWidth = ink.width * numberScale
        let markLeft: CGFloat = 158
        let markRight: CGFloat = 875
        let gap: CGFloat = 35
        let fullWWidth: CGFloat = 395
        let wScale = min(1, max(0.35, (markRight - markLeft - gap - numberWidth) / fullWWidth))

        // The W's upper-left ink corner stays at the same point as it shrinks.
        let w = NSBezierPath()
        let points: [(CGFloat, CGFloat)] = [
            (182, 270), (265, 565), (356, 270), (448, 565), (530, 270)
        ]
        for (index, point) in points.enumerated() {
            let x = markLeft + (point.0 - markLeft) * wScale
            let y = 1024 - (245 + (point.1 - 245) * wScale)
            if index == 0 { w.move(to: NSPoint(x: x, y: y)) }
            else { w.line(to: NSPoint(x: x, y: y)) }
        }
        w.lineWidth = 48 * wScale
        w.lineCapStyle = .round
        w.lineJoinStyle = .round
        wColor.setStroke()
        w.stroke()

        let numberLeft = markLeft + fullWWidth * wScale + gap
        let numberTop: CGFloat = 245
        numberColor.setFill()
        context.saveGState()
        context.translateBy(x: numberLeft - ink.minX * numberScale,
                            y: 1024 - numberTop - ink.maxY * numberScale)
        context.scaleBy(x: numberScale, y: numberScale)
        CTLineDraw(line, context)
        context.restoreGState()
    }

    private func quarterIndex(for week: Int, on date: Date) -> Int {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        let total = calendar.range(of: .weekOfYear,
                                   in: .yearForWeekOfYear,
                                   for: date)?.count ?? 52
        return min(3, max(0, (week - 1) * 4 / total))
    }

    private func isoWeekNumber(for date: Date) -> Int {
        var calendar = Calendar(identifier: .iso8601)
        calendar.timeZone = .current
        return calendar.component(.weekOfYear, from: date)
    }
}
