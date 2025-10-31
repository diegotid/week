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
    private var baseIcon: NSImage?

    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusItem()
        scheduleMidnightUpdate()
        cacheBaseIcon()
        updateDockIcon()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appDidBecomeActive(_:)),
                                               name: NSApplication.didBecomeActiveNotification,
                                               object: nil)
    }

    @objc private func appDidBecomeActive(_ notification: Notification) {
        updateDockIcon()
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
        updateDockIcon()
        scheduleMidnightUpdate()
    }

    private func cacheBaseIcon() {
        baseIcon = NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
        baseIcon?.isTemplate = false
    }

    private func updateDockIcon() {
        let digits = weekNumberDigits(for: Date())
        guard !digits.isEmpty else { return }
        let iconSource = baseIcon ?? NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
        let variant = currentDockIconVariant()
        let composed = NSImage(size: iconSource.size, flipped: false) { [self] rect -> Bool in
            drawDockIcon(in: rect, base: iconSource, variant: variant, weekNumber: digits)
            return true
        }
        composed.isTemplate = false
        NSApp.applicationIconImage = composed
        NSApp.dockTile.display()
    }

    private func drawDockIcon(in rect: NSRect, base: NSImage, variant: DockIconVariant, weekNumber: String) {
        base.draw(in: rect)
        let style = dockIconStyle(for: variant)
        let inset = rect.width * style.insetRatio
        let canvasRect = rect.insetBy(dx: inset, dy: inset)
        let cornerRadius = canvasRect.width * 0.26
        let roundedPath = NSBezierPath(roundedRect: canvasRect, xRadius: cornerRadius, yRadius: cornerRadius)
        if let faceImage = renderDockFace(size: canvasRect.size,
                                          cornerRadius: cornerRadius,
                                          style: style) {
            NSGraphicsContext.saveGraphicsState()
            roundedPath.addClip()
            faceImage.draw(in: canvasRect,
                           from: NSRect(origin: .zero, size: faceImage.size),
                           operation: .sourceOver,
                           fraction: style.fillOpacity)
            NSGraphicsContext.restoreGraphicsState()
        }
        drawDockIconText(in: canvasRect, style: style, weekNumber: weekNumber)
    }

    private func renderDockFace(size: CGSize,
                                cornerRadius: CGFloat,
                                style: DockIconStyle) -> NSImage? {
        let rect = NSRect(origin: .zero, size: size)
        let face = NSImage(size: size, flipped: false) { _ in
            let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
            NSGraphicsContext.saveGraphicsState()
            path.addClip()
            if let gradient = NSGradient(colors: [style.backgroundTop, style.backgroundBottom]) {
                gradient.draw(in: rect, angle: -90)
            }
            if style.highlightAlpha > 0 {
                let highlightHeight = rect.height * style.highlightCoverage
                let highlightRect = NSRect(x: rect.minX,
                                           y: rect.maxY - highlightHeight,
                                           width: rect.width,
                                           height: highlightHeight)
                if let highlight = NSGradient(
                    starting: NSColor.white.withAlphaComponent(style.highlightAlpha),
                    ending: NSColor.white.withAlphaComponent(0)
                ) {
                    highlight.draw(in: highlightRect, angle: -90)
                }
            }
            NSGraphicsContext.restoreGraphicsState()
            return true
        }
        return face
    }

    private func drawDockIconText(in rect: NSRect, style: DockIconStyle, weekNumber: String) {
        let scale: CGFloat = 2.0
        let hiResSize = CGSize(width: rect.size.width * scale, height: rect.size.height * scale)
        let hiResImage = renderHighResTextImage(size: hiResSize, scale: scale, style: style, weekNumber: weekNumber)
        hiResImage.draw(
            in: rect,
            from: NSRect(origin: .zero, size: hiResSize),
            operation: .sourceOver,
            fraction: 1.0
        )
    }

    private func renderHighResTextImage(size: CGSize, scale: CGFloat, style: DockIconStyle, weekNumber: String) -> NSImage {
        let hiResImage = NSImage(size: size)
        hiResImage.lockFocusFlipped(false)
        if let ctx = NSGraphicsContext.current {
            ctx.cgContext.saveGState()
            ctx.cgContext.scaleBy(x: scale, y: scale)
            let logicalRect = CGRect(origin: .zero, size: CGSize(width: size.width / scale, height: size.height / scale))
            let weekFontSize = logicalRect.width * 0.2
            let numberFontSize = logicalRect.width * 0.5
            let weekAttributes = dockTextAttributes(color: style.weekTextColor,
                                                    fontSize: weekFontSize,
                                                    weight: .semibold)
            let numberAttributes = dockTextAttributes(color: style.numberTextColor,
                                                      fontSize: numberFontSize,
                                                      weight: .bold)
            drawCentered("Week",
                         centerY: logicalRect.minY + logicalRect.height * 0.76,
                         in: logicalRect,
                         attributes: weekAttributes)
            drawCentered(weekNumber,
                         centerY: logicalRect.minY + logicalRect.height * 0.4,
                         in: logicalRect,
                         attributes: numberAttributes)

            ctx.cgContext.restoreGState()
        }
        hiResImage.unlockFocus()
        return hiResImage
    }

    private func drawCentered(_ text: String,
                              centerY: CGFloat,
                              in rect: NSRect,
                              attributes: [NSAttributedString.Key: Any]) {
        let attributed = text as NSString
        let textSize = attributed.size(withAttributes: attributes)
        let textRect = NSRect(
            x: rect.midX - textSize.width / 2,
            y: centerY - textSize.height / 2,
            width: textSize.width,
            height: textSize.height
        )
        attributed.draw(in: textRect, withAttributes: attributes)
    }

    private func dockTextAttributes(color: NSColor,
                                    fontSize: CGFloat,
                                    weight: NSFont.Weight) -> [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        let font = NSFont(name: "SF Pro Rounded Bold", size: fontSize)
            ?? NSFont(name: "SF Pro Rounded Semibold", size: fontSize)
            ?? NSFont.systemFont(ofSize: fontSize, weight: weight)
        return [
            .font: font,
            .foregroundColor: color,
            .paragraphStyle: paragraph
        ]
    }

    private func currentDockIconVariant() -> DockIconVariant {
        let appearance = NSApp.effectiveAppearance
        let options: [NSAppearance.Name] = [
            .accessibilityHighContrastDarkAqua,
            .darkAqua,
            .vibrantDark,
            .accessibilityHighContrastAqua,
            .vibrantLight,
            .aqua
        ]
        let bestMatch = appearance.bestMatch(from: options) ?? .aqua
        switch bestMatch {
        case .darkAqua, .vibrantDark, .accessibilityHighContrastDarkAqua:
            return .dark
        case .accessibilityHighContrastAqua, .vibrantLight:
            return .tinted
        default:
            return .light
        }
    }

    private func dockIconStyle(for variant: DockIconVariant) -> DockIconStyle {
        switch variant {
        case .light:
            return DockIconStyle(
                backgroundTop: rgbColor(0xF8F8FA),
                backgroundBottom: rgbColor(0xD6DADE),
                weekTextColor: rgbColor(0xEB534E),
                numberTextColor: rgbColor(0x212123),
                highlightAlpha: 0.42,
                highlightCoverage: 0.7,
                fillOpacity: 1,
                insetRatio: 0.08
            )
        case .dark:
            return DockIconStyle(
                backgroundTop: rgbColor(0x3F4145),
                backgroundBottom: rgbColor(0x15171A),
                weekTextColor: rgbColor(0xEB534E),
                numberTextColor: rgbColor(0xF4F5F9),
                highlightAlpha: 0.14,
                highlightCoverage: 0.65,
                fillOpacity: 1,
                insetRatio: 0.08
            )
        case .tinted:
            return DockIconStyle(
                backgroundTop: rgbColor(0x9DA0A4),
                backgroundBottom: rgbColor(0x686A6E),
                weekTextColor: rgbColor(0xE6E9EF),
                numberTextColor: rgbColor(0xFCFDFD),
                highlightAlpha: 0.35,
                highlightCoverage: 0.7,
                fillOpacity: 1,
                insetRatio: 0.08
            )
        }
    }

    private func rgbColor(_ hex: Int) -> NSColor {
        let red = CGFloat((hex >> 16) & 0xFF) / 255.0
        let green = CGFloat((hex >> 8) & 0xFF) / 255.0
        let blue = CGFloat(hex & 0xFF) / 255.0
        return NSColor(calibratedRed: red, green: green, blue: blue, alpha: 1.0)
    }

    private enum DockIconVariant {
        case light
        case dark
        case tinted
    }

    private struct DockIconStyle {
        let backgroundTop: NSColor
        let backgroundBottom: NSColor
        let weekTextColor: NSColor
        let numberTextColor: NSColor
        let highlightAlpha: CGFloat
        let highlightCoverage: CGFloat
        let fillOpacity: CGFloat
        let insetRatio: CGFloat
    }

    private func weekNumberDigits(for date: Date) -> String {
        let week = Calendar.current.component(.weekOfYear, from: date)
        return "\(week)"
    }
}
