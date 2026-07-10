import SwiftUI
import UIKit

struct TwoFingerPan: UIViewRepresentable {
    var onPan: (CGSize) -> Void
    var onEnded: () -> Void

    func makeUIView(context: Context) -> UIView {
        let view = TransparentGestureView()
        view.backgroundColor = .clear

        view.isUserInteractionEnabled = false

        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handle(_:))
        )
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        pan.delegate = context.coordinator

        view.panGesture = pan

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onPan: onPan, onEnded: onEnded)
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
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

        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}

class TransparentGestureView: UIView {
    var panGesture: UIPanGestureRecognizer?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if let window = self.window, let pan = panGesture {
            window.addGestureRecognizer(pan)
        }
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil, let window = self.window, let pan = panGesture {
            window.removeGestureRecognizer(pan)
        }
    }
}
