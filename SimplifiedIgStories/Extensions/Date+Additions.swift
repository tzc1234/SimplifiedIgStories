//
//  Date+Additions.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 21/2/2022.
//

import Foundation

extension Date {
    func timeAgoDisplay() -> String {
        let toDate = Date()
        let calendar = Calendar.current
        
        if let interval = calendar.dateComponents([.day], from: self, to: toDate).day, interval > 0 {
          return "\(interval)d"
        }
        
        if let interval = calendar.dateComponents([.hour], from: self, to: toDate).hour, interval > 0 {
          return "\(interval)h"
        }
        
        if let interval = calendar.dateComponents([.minute], from: self, to: toDate).minute, interval > 0 {
          return "\(interval)m"
        }
        
        if let interval = calendar.dateComponents([.second], from: self, to: toDate).second, interval > 0 {
          return "\(interval)s"
        }
        
        return ""
    }
}
