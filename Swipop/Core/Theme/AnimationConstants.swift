//
//  AnimationConstants.swift
//  Swipop
//
//  Unified animation timing constants
//

import SwiftUI

extension Animation {
    /// Standard tab/page switch animation
    static let tabSwitch = Animation.easeOut(duration: 0.25)

    /// Quick feedback animation
    static let feedback = Animation.easeOut(duration: 0.15)

    /// Spring animation for interactive elements
    static let interactive = Animation.spring(response: 0.3, dampingFraction: 0.8)
}
