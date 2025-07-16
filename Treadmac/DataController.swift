//
//  DataController.swift
//  Treadmac
//
//  Created by Harsh vithlani on 11/06/2025.
//


import Foundation
import SwiftData

@MainActor
class DataController {
    static let shared = DataController()
    let container: ModelContainer
    var context: ModelContext { container.mainContext }

    private init() {
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: ScrollData.self, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
}
