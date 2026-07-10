//
//  ShadeSpotService.swift
//  Iyup
//
//  Created by Albert Tandy Harison on 07/07/26.
//

import RealityKit

struct ShadeSpotService {
//    func spots(forHour hour: Int) -> [ShadeSpot] {
        func spots() -> [ShadeSpot] {
        // dummy 3 titik
        return [
//            ShadeSpot(position: [-7, -3, -45], hour: hour, level: .high),
//            ShadeSpot(position: [-3, -3, -20], hour: hour, level: .medium), // sisa ini
//            ShadeSpot(position: [1, -3, 18], hour: hour, level: .low),
//            ShadeSpot(position: [-16, -3, -26], hour: hour, level: .high),
//            ShadeSpot(position: [-14, -3, -70], hour: hour, level: .medium),
//            ShadeSpot(position: [20, -3, 20], hour: hour, level: .low),
            ShadeSpot(position: [-7, -3, -45], hour: 0, level: .high, spotID: "Bench3"),
//            ShadeSpot(position: [-3, -3, -20], hour: 0, level: .medium, spotID: "Bench6"),
            ShadeSpot(position: [1, -3, 18], hour: 0, level: .low, spotID: "Bench5"),
            ShadeSpot(position: [-16, -3, -26], hour: 0, level: .high, spotID: "Bench1"),
            ShadeSpot(position: [-14, -3, -70], hour: 0, level: .medium, spotID: "Bench2"),
            ShadeSpot(position: [20, -3, 20], hour: 0, level: .low, spotID: "Bench4"),
        ]
    }
}
