import RealityKit

struct ShadeSpotService {
        func spots() -> [ShadeSpot] {
        return [

            ShadeSpot(position: [-7, -3, -45], hour: 0, level: .high, spotID: "Bench3"),

            ShadeSpot(position: [1, -3, 18], hour: 0, level: .low, spotID: "Bench5"),
            ShadeSpot(position: [-16, -3, -26], hour: 0, level: .high, spotID: "Bench1"),
            ShadeSpot(position: [-14, -3, -70], hour: 0, level: .medium, spotID: "Bench2"),
            ShadeSpot(position: [20, -3, 20], hour: 0, level: .low, spotID: "Bench4"),
        ]
    }
}
