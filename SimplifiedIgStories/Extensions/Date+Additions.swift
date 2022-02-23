//
//  Date+Additions.swift
//  SimplifiedIgStories
//
//  Created by Tsz-Lung on 21/2/2022.
//

import Foundation

extension Date {
    // Reference: https://stackoverflow.com/a/51682991
    func timeAgoDisplay() -> String {
        let toDate = Date()
        let calendar = Calendar.current
        
        if let interval = calendar.dateComponents([.year], from: self, to: toDate).year, interval > 0 {
          return "\(interval)y"
        }
        
        if let interval = calendar.dateComponents([.month], from: self, to: toDate).month, interval > 0 {
          return "\(interval)m"
        }
        
        if let interval = calendar.dateComponents([.weekOfYear], from: self, to: toDate).weekOfYear, interval > 0 {
          return "\(interval)w"
        }
        
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
