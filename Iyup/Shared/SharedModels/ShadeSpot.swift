//
//  ShadeSpot.swift
//  Iyup
//
//  Created by Albert Tandy Harison on 07/07/26.
//

import Foundation
import RealityKit

struct ShadeSpot: Identifiable {
    let id = UUID()
    let position: SIMD3<Float>
    let hour: Int
    let level: ShadeLevel
}

enum ShadeLevel {
    case low, medium, high
}


