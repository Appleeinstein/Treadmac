//
//  ScrollMonitor.swift
//  Treadmac
//
//  Created by Harsh vithlani on 11/06/2025.
//

import SwiftData
import AppKit
import Foundation

class ScrollMonitor {
    static let shared = ScrollMonitor()
    private var monitor: Any?

    private init() {}

    func startMonitoring(with context: ModelContext) {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
            self?.handleScrollEvent(event, context: context)
        }
    }

    private func handleScrollEvent(_ event: NSEvent, context: ModelContext) {
        let deltaY = Int(abs(event.scrollingDeltaY))
        guard deltaY > 0 else { return }

        let appName = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Unknown"
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let currentHour = Calendar.current.component(.hour, from: Date())

        let fetchDescriptor = FetchDescriptor<ScrollData>(predicate: #Predicate { $0.date == startOfDay })

        do {
            if let existingData = try context.fetch(fetchDescriptor).first {
                existingData.totalScrollPixels += deltaY
                existingData.perAppScroll[appName, default: 0] += deltaY
                if existingData.hourlyScroll == nil {
                    existingData.hourlyScroll = [:]
                }
                existingData.hourlyScroll?[currentHour, default: 0] += deltaY
            } else {
                var hourlyScroll: [Int: Int] = [:]
                hourlyScroll[currentHour] = deltaY
                let newData = ScrollData(
                    date: startOfDay,
                    totalScrollPixels: deltaY,
                    perAppScroll: [appName: deltaY],
                    hourlyScroll: hourlyScroll
                )
                context.insert(newData)
            }
            try context.save()
            print("Scrolled \(deltaY) px in \(appName) at hour \(currentHour)")
        } catch {
            print("Scroll event error: \(error)")
        }
    }
}
