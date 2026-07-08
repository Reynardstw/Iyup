////
////  TwoFingerPan.swift
////  Iyup
////
////  Created by Albert Tandy Harison on 07/07/26.
////
//
import SwiftUI
import UIKit

struct TwoFingerPan: UIViewRepresentable {
    var onPan: (CGSize) -> Void
    var onEnded: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.backgroundColor = .clear
        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handle(_:))
        )
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        view.addGestureRecognizer(pan)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPan: onPan, onEnded: onEnded)
    }

    class Coordinator: NSObject {
        let onPan: (CGSize) -> Void
        let onEnded: () -> Void

        init(onPan: @escaping (CGSize) -> Void, onEnded: @escaping () -> Void) {
            self.onPan = onPan
            self.onEnded = onEnded
        }

        @objc func handle(_ g: UIPanGestureRecognizer) {
            let t = g.translation(in: g.view)
            onPan(CGSize(width: t.x, height: t.y))
            if g.state == .ended || g.state == .cancelled {
                onEnded()
            }
        }
    }
}
