//
//  ShareSheet.swift
//  Swipop
//

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
    let project: Project

    func makeUIViewController(context _: Context) -> UIActivityViewController {
        let text = "\(project.title) on Swipop"
        let url = URL(string: "https://swipop.app/project/\(project.id)")!

        return UIActivityViewController(
            activityItems: [text, url],
            applicationActivities: nil
        )
    }

    func updateUIViewController(_: UIActivityViewController, context _: Context) {}
}
