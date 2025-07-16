//
//  TreadmacApp.swift
//  Treadmac
//
//  Created by Harsh Vithlani on 11/06/2025.
//

import SwiftUI

@main
struct TreadMacApp: App {
    let dataController = DataController.shared

    var body: some Scene {
        MenuBarExtra {
            StartupWrapperView()
                .modelContext(dataController.context)
                .preferredColorScheme(.dark)
                .frame(width: 300)
        } label: {
            Image("MenuBarIcon")
        }
        .menuBarExtraStyle(.window)
    }
}

