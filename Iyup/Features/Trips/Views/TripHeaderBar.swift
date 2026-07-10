import SwiftUI

/// Header reusable untuk PlanTripView & EditTripView.
/// Patokan layout/gaya dari "Trip Details" (EditTripView):
/// back (kiri) • judul (tengah) • tombol aksi (kanan).
struct TripHeaderBar: View {
    let title: String
    let trailingTitle: String

    /// true → tombol kanan gaya prominent (ungu, teks putih) mis. "Save".
    /// false → gaya glass polos mis. "Edit".
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
