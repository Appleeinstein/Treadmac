//
//  StartupWrapperView.swift
//  Treadmac
//
//  Created by Harsh vithlani on 11/06/2025.
//


import SwiftUI
import SwiftData

struct StartupWrapperView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        ContentView()
            .onAppear {
                checkAccessibilityPermissions()
                ScrollMonitor.shared.startMonitoring(with: context)
            }
    }

    private func checkAccessibilityPermissions() {
        let options = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true] as CFDictionary
        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        if !accessEnabled {
            print("⚠️ Accessibility permissions not granted. Please enable in System Settings → Privacy & Security → Accessibility.")
        }
    }
}

