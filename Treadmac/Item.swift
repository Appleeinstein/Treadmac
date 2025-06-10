//
//  Item.swift
//  Treadmac
//
//  Created by Harsh vithlani on 11/06/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
