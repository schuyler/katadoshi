//
//  katadoshiApp.swift
//  katadoshi
//
//  Created by Schuyler Erle on 11/2/25.
//

import SwiftUI

@main
struct katadoshiApp: App {
    @State private var formStore = FormStore()

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            // In test mode, use an isolated FormStore
            if ProcessInfo.processInfo.arguments.contains("UI_TESTING") {
                FormsListView()
                    .environment(FormStore(userDefaults: UserDefaults(suiteName: "UI_TESTING")!))
            } else {
                FormsListView()
                    .environment(formStore)
            }
            #else
            FormsListView()
                .environment(formStore)
            #endif
        }
    }
}
