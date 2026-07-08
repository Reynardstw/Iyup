//
//  ShadeSpotService.swift
//  Iyup
//
//  Created by Albert Tandy Harison on 07/07/26.
//

import RealityKit

struct ShadeSpotService {
    func spots(forHour hour: Int) -> [ShadeSpot] {
        // dummy 3 titik
        return [
            ShadeSpot(position: [-7, -3, -45], hour: hour, level: .high),
            ShadeSpot(position: [-3, -3, -20], hour: hour, level: .medium),
            ShadeSpot(position: [5, -3, 30], hour: hour, level: .low),
        ]
    }
}
