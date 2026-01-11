//
//  BusinessCardAIAssisstantApp.swift
//  BusinessCardAIAssisstant
//
//  Created by Zhexiang Li on 1/11/26.
//

import SwiftUI

@main
struct BusinessCardAIAssisstantApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
    }
}
