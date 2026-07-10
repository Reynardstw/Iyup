import SwiftUI

struct TimeSliderPanel: View {
    @Binding var hour: Double
    @State private var isEditing = false

    private let range: ClosedRange<Double> = 6...18
    private let sliderHeight: CGFloat = 570

    private let primaryPurple = Color(
        red: 153 / 255,
        green: 69 / 255,
        blue: 236 / 255
    )

    private var currentQuarterTime: Double {
        let calendar = Calendar.current
        let now = Date()

        let h = calendar.component(.hour, from: now)
        let m = calendar.component(.minute, from: now)

        let roundedMinute = ((m + 7) / 15) * 15

        var hourValue = h
        var minuteValue = roundedMinute

        if minuteValue == 60 {
            hourValue += 1
            minuteValue = 0
        }

        let value = Double(hourValue) + Double(minuteValue) / 60.0

        return min(max(value, range.lowerBound), range.upperBound)
    }

    private var isAtNow: Bool {
        abs(hour - currentQuarterTime) < 0.001
    }

    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "sun.max.fill")
                .font(.title3)
                .padding(.bottom, 35)

            ZStack {
                Slider(
                    value: $hour,
                    in: range,
                    step: 0.25
                )
                .rotationEffect(.degrees(90))
                .frame(width: sliderHeight)
                .tint(primaryPurple)

                if !isAtNow {
                    Text(timeString(from: hour))
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule().fill(primaryPurple)
                        )
                        .offset(
                            x: -65,
                            y: thumbYOffset()
                        )
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: isAtNow)
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        setToNow()
                    }
                } label: {
                    Text("Now")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 10)
                        .background(
                            Capsule().fill(
                                isAtNow
                                ? primaryPurple
                                : primaryPurple.opacity(0.6)
                            )
                        )
                }
                .offset(
                    x: -65,
                    y: nowYOffset()
                )
            }
            .frame(width: 60, height: sliderHeight)

            Image(systemName: "moon.fill")
                .font(.title3)
        }
    }

    private func timeString(from value: Double) -> String {
        let hour = Int(value)
        let minute = Int(round((value - Double(hour)) * 60))

        return String(format: "%02d:%02d", hour, minute)
    }

    private func thumbYOffset() -> CGFloat {
        let ratio = (hour - range.lowerBound) /
        (range.upperBound - range.lowerBound)

        return (CGFloat(ratio) - 0.5) * (sliderHeight - 28)
    }

    private func nowYOffset() -> CGFloat {
        let ratio = (currentQuarterTime - range.lowerBound) /
        (range.upperBound - range.lowerBound)

        return (CGFloat(ratio) - 0.5) * (sliderHeight - 28)
    }

    private func setToNow() {
        hour = currentQuarterTime
    }
}
