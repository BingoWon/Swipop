//
//  View+TabViewAccessory.swift
//  Swipop
//

import SwiftUI

extension View {
    /// Conditionally applies tabViewBottomAccessory
    @ViewBuilder
    func conditionalBottomAccessory<Content: View>(
        _ condition: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        if condition {
            self.tabViewBottomAccessory { content() }
        } else {
            self
        }
    }
}

