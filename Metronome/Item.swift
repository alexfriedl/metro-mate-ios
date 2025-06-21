//
//  Item.swift
//  Metronome
//
//  Created by Alexander Friedl on 21.06.25.
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
