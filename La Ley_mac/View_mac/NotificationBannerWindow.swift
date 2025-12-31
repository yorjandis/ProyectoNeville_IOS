//
//  NotificationBannerWindow.swift
//  Neville_iOS
//
//  Created by Yorjandis PG on 30/12/25.
//

import SwiftUI
import AppKit

final class NotificationBannerWindow {

    static let shared = NotificationBannerWindow()

    private var window: NSWindow?

    private init() {}

    func show<Content: View>(@ViewBuilder content: () -> Content) {

        if window == nil {
            let hosting = NSHostingController(rootView: content())

            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 360, height: 120),
                styleMask: [.nonactivatingPanel, .borderless],
                backing: .buffered,
                defer: false
            )

            panel.level = .statusBar       // 👈 por encima de TODAS
            panel.isFloatingPanel = true
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.collectionBehavior = [
                .canJoinAllSpaces,
                .fullScreenAuxiliary
            ]

            panel.contentView = hosting.view
            window = panel
        }

        positionWindow()
        window?.makeKeyAndOrderFront(nil)
    }

    func hide() {
        window?.orderOut(nil)
    }

    private func positionWindow() {
        guard let screen = NSScreen.main,
              let window = window else { return }

        let screenFrame = screen.visibleFrame
        let windowSize = window.frame.size

        let x = screenFrame.midX - windowSize.width / 2
        let y = screenFrame.maxY - windowSize.height - 20

        window.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
