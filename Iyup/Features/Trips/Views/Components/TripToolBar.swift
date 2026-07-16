import SwiftUI

struct TripToolbar: ViewModifier {
    let title: String
    let trailingTitle: String
    var trailingProminent: Bool = false
    var onBack: (() -> Void)? = nil
    let onTrailing: () -> Void

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let onBack {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            onBack()
                        } label: {
                            Image(systemName: "chevron.left")
                        }
                        .accessibilityLabel("Back")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if trailingProminent {
                        Button(trailingTitle, action: onTrailing)
                            .buttonStyle(.glassProminent)
                            .tint(.accentColor)
                    } else {
                        Button(trailingTitle, action: onTrailing)
                    }
                }
            }
            .navigationBarBackButtonHidden(onBack != nil)
    }
}

extension View {
    func tripToolbar(
        title: String,
        trailingTitle: String,
        trailingProminent: Bool = false,
        onBack: (() -> Void)? = nil,
        onTrailing: @escaping () -> Void
    ) -> some View {
        modifier(TripToolbar(
            title: title,
            trailingTitle: trailingTitle,
            trailingProminent: trailingProminent,
            onBack: onBack,
            onTrailing: onTrailing
        ))
    }
}
