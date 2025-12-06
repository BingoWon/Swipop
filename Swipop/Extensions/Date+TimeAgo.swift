//
//  Date+TimeAgo.swift
//  Swipop
//

import Foundation

extension Date {
    var timeAgo: String {
        let seconds = Int(-timeIntervalSinceNow)

        if seconds < 60 { return "now" }
        if seconds < 3600 { return "\(seconds / 60)m" }
        if seconds < 86400 { return "\(seconds / 3600)h" }
        if seconds < 604_800 { return "\(seconds / 86400)d" }

        return "\(seconds / 604_800)w"
    }
}
