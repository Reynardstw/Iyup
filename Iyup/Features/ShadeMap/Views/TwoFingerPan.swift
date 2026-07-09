import SwiftUI
import UIKit

struct TwoFingerPan: UIViewRepresentable {
    var onPan: (CGSize) -> Void
    var onEnded: () -> Void

    func makeUIView(context: Context) -> UIView {
        // Kita menggunakan custom view di bawah
        let view = TransparentGestureView()
        view.backgroundColor = .clear
        
        // 1. PENTING: Matikan interaksi pada view ini agar
        // ia tidak menjadi "tameng" yang memblokir tap ke RealityView
        view.isUserInteractionEnabled = false
        
        let pan = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handle(_:))
        )
        pan.minimumNumberOfTouches = 2
        pan.maximumNumberOfTouches = 2
        pan.delegate = context.coordinator
        
        // Simpan referensi gesture ke custom view agar bisa dipasang ke Window
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

        // 2. PENTING: Izinkan gesture 2 jari UIKit ini berjalan
        // berbarengan dengan gesture bawaan SwiftUI (Tap, Zoom, Pan 1 jari)
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}

// 3. CUSTOM VIEW: Trik menempelkan Gesture langsung ke Window Induk
class TransparentGestureView: UIView {
    var panGesture: UIPanGestureRecognizer?

    // Saat View masuk ke layar (overlay aktif)
    override func didMoveToWindow() {
        super.didMoveToWindow()
        if let window = self.window, let pan = panGesture {
            window.addGestureRecognizer(pan) // Pasang gesture secara global
        }
    }

    // Saat View dihapus dari layar (overlay hilang)
    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil, let window = self.window, let pan = panGesture {
            window.removeGestureRecognizer(pan) // Bersihkan gesture agar tidak bocor
        }
    }
}
