//
//  TimeSliderPanel.swift
//  Iyup
//
//  Created by Albert Tandy Harison on 08/07/26.
//

//import SwiftUI
//
//struct TimeSliderPanel: View {
//    @Binding var hour: Double
//    @State private var isEditing = false
//
//    private let range: ClosedRange<Double> = 6...18
//    private let sliderHeight: CGFloat = 450
//
//    var body: some View {
//        VStack(spacing: 16) {
//            // ikon matahari (atas)
//            Image(systemName: "sun.max.fill")
//
//            ZStack {
//                // slider native, diputar vertikal
//                Slider(
//                    value: $hour,
//                    in: range,
//                    step: 1,
//                    onEditingChanged: { editing in
//                        isEditing = editing
//                    }
//                )
//                .rotationEffect(.degrees(90))
//                .frame(width: sliderHeight)
//                .tint(Color(red: 153/255, green: 69/255, blue: 236/255))
//
//                // bubble jam ikut posisi thumb
//                Text(String(format: "%02d:00", Int(hour)))
//                    .font(.subheadline.bold())
//                    .foregroundStyle(.white)
//                    .padding(.horizontal, 14)
//                    .padding(.vertical, 8)
//                    .background(Capsule().fill(Color(red: 153/255, green: 69/255, blue: 236/255)))
//                    .offset(x: -60, y: bubbleY())
//                    .animation(.easeOut(duration: 0.15), value: hour)
//            }
//            .frame(width: 60, height: sliderHeight)
//
//            // ikon bulan (bawah)
//            Image(systemName: "moon.fill")
//
//            // tombol Now
//            Button {
//                setToNow()
//            } label: {
//                Text("Now")
//                    .font(.subheadline.weight(.semibold))
//                    .foregroundStyle(.white)
//                    .padding(.horizontal, 22)
//                    .padding(.vertical, 10)
//                    .background(Capsule().fill(Color(red: 153/255, green: 69/255, blue: 236/255).opacity(0.6)))
//            }
//        }
//    }
//
//    // hitung posisi Y bubble sesuai jam (atas = jam besar, bawah = jam kecil)
//    private func bubbleY() -> CGFloat {
//        let ratio = (hour - range.lowerBound) / (range.upperBound - range.lowerBound)
//        // ratio 0 (jam 6) = paling bawah, ratio 1 (jam 18) = paling atas
//        return (0.5 - CGFloat(ratio)) * sliderHeight
//    }
//
//    private func setToNow() {
//        let h = Calendar.current.component(.hour, from: Date())
//        hour = Double(min(max(h, 6), 18))
//    }
//}



//
//  TimeSliderPanel.swift
//  Iyup
//
//  Created by Albert Tandy Harison on 08/07/26.
//

import SwiftUI

struct TimeSliderPanel: View {
    @Binding var hour: Double
    @State private var isEditing = false

    private let range: ClosedRange<Double> = 6...18
    private let sliderHeight: CGFloat = 450
    
    // Satu warna ungu murni sesuai request
    private let primaryPurple = Color(red: 153/255, green: 69/255, blue: 236/255)

    // Mengecek apakah posisi slider ada di jam sekarang
    private var isAtNow: Bool {
        let currentH = Calendar.current.component(.hour, from: Date())
        return Int(hour) == currentH
    }

    var body: some View {
        VStack(spacing: 0) {
            
            // ikon matahari (atas)
            Image(systemName: "sun.max.fill")
                .font(.title3)
                // Offset dihapus, padding bawah dibesarkan agar menjauh dari ujung slider
                .padding(.bottom, 35)

            ZStack {
                // Slider Native
                Slider(
                    value: $hour,
                    in: range,
                    step: 1,
                    onEditingChanged: { editing in
                        isEditing = editing
                    }
                )
                .rotationEffect(.degrees(90))
                .frame(width: sliderHeight)
                // Warna slider tidak pernah berubah, selalu ungu solid
                .tint(primaryPurple)

                // Bubble jam hilang saat menekan "Now"
                if !isAtNow {
                    Text(String(format: "%02d:00", Int(hour)))
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(primaryPurple))
                        .offset(x: -65, y: thumbYOffset())
                        .transition(.opacity)
                        .animation(.easeInOut(duration: 0.2), value: isAtNow)
                }

                // Tombol "Now"
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
                        // Warna solid jika di jam sekarang, pudar (0.6) jika tidak
                        .background(
                            Capsule().fill(isAtNow ? primaryPurple : primaryPurple.opacity(0.6))
                        )
                }
                .offset(x: -65, y: nowYOffset())
            }
            .frame(width: 60, height: sliderHeight)

            // ikon bulan (bawah)
            Image(systemName: "moon.fill")
                .font(.title3)
                // Padding disesuaikan agar proporsional dengan matahari
//                .padding(.top, 25)
        }
    }

    // Posisi Y untuk bubble yang mengikuti drag
    private func thumbYOffset() -> CGFloat {
        let ratio = (hour - range.lowerBound) / (range.upperBound - range.lowerBound)
        return (CGFloat(ratio) - 0.5) * (sliderHeight - 28)
    }

    // Posisi Y untuk tombol "Now"
    private func nowYOffset() -> CGFloat {
        let calendar = Calendar.current
        let now = Date()
        let currentHour = calendar.component(.hour, from: now)
        let currentMinute = calendar.component(.minute, from: now)
        
        let realTime = Double(currentHour) + (Double(currentMinute) / 60.0)
        let clampedTime = min(max(realTime, range.lowerBound), range.upperBound)
        let ratio = (clampedTime - range.lowerBound) / (range.upperBound - range.lowerBound)
        
        return (CGFloat(ratio) - 0.5) * (sliderHeight - 28)
    }

    private func setToNow() {
        let h = Calendar.current.component(.hour, from: Date())
        hour = Double(min(max(h, 6), 18))
    }
}
