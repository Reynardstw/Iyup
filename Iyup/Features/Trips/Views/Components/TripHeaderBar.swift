import SwiftUI

struct TripHeaderBar: View {
    let title: String
    let trailingTitle: String

    var trailingProminent: Bool = false

    let onBack: () -> Void
    let onTrailing: () -> Void

    private let brandPurple = Color(red: 153/255, green: 69/255, blue: 236/255)

    var body: some View {
        ZStack {
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.black)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
                .allowsHitTesting(false)

            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.black)
                        .frame(width: 45, height: 48)
                        .glassEffect(in: .circle)
                }

                Spacer(minLength: 0)

                Button(action: onTrailing) {
                    Text(trailingTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(trailingProminent ? .white : .black)
                        .padding(.horizontal, 18)
                        .frame(height: 48)
                        .background {
                            if trailingProminent {
                                Capsule().fill(brandPurple)
                            }
                        }
                        .glassEffect(in: .capsule)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
