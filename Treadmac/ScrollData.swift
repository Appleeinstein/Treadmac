//
//  ScrollData.swift
//  TreadMac
//
//  Created by Harsh Viththani on 11/06/2025.
//

import Foundation
import SwiftData

@Model
class ScrollData: Identifiable {
    @Attribute(.unique) var date: Date
    var totalScrollPixels: Int
    var perAppScroll: [String: Int]
    var hourlyScroll: [Int: Int]? // Made optional
    
    init(date: Date, totalScrollPixels: Int = 0, perAppScroll: [String: Int] = [:], hourlyScroll: [Int: Int]? = nil) {
        self.date = date
        self.totalScrollPixels = totalScrollPixels
        self.perAppScroll = perAppScroll
        self.hourlyScroll = hourlyScroll
    }
}
