//
//  WeekApp.swift
//  Week
//
//  Created by Diego Rivera on 20/10/25.
//

import SwiftUI

@main
struct WeekApp: App {
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

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
}
