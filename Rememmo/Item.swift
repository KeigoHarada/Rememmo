//
//  Item.swift
//  Rememmo
//
//  Created by 原田啓吾 on 2025/06/30.
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
