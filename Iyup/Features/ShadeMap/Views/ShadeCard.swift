//
//  ShadeCard.swift
//  Iyup
//
//  Created by Albert Tandy Harison on 08/07/26.
//

import SwiftUI

struct ShadeCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "thermometer.medium")
                    .font(.system(size: 12))
                Text("32°")
            }

            HStack(spacing: 4) {
                Image(systemName: "sun.max")
                    .font(.system(size: 12))
                Text("Bright")
            }

            HStack(spacing: 4) {
                Image(systemName: "person.2.fill")
                    .font(.system(size: 12))
                Text("Slightly crowded")
            }
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(.black)
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 5)
                .fill(.white)
                .shadow(color: .black.opacity(0.12), radius: 10, y: 4)
        )
    }
}
