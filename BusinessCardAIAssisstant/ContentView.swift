//
//  ContentView.swift
//  BusinessCardAIAssisstant
//
//  Created by Zhexiang Li on 1/11/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        RootView()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(AppSettings())
}
