//
//  MetronomeApp.swift
//  Metronome
//
//  Created by Alexander Friedl on 21.06.25.
//

import SwiftUI
import AppIntents

@main
struct MetronomeApp: App {
    init() {
        // Register shortcuts
        MetronomeShortcuts.updateAppShortcutParameters()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
