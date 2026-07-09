import Foundation

enum OutfitRecommender {
    static func recommend(temperatureCelsius: Double, condition: String, hour: Int) -> (headline: String, emojis: [String]) {
        let lowerCondition = condition.lowercased()
        let isRainy = lowerCondition.contains("hujan") || lowerCondition.contains("rain")

        if isRainy {
            return (
                "Rainy weather, bring something waterproof and quick-dry.",
                ["☂️", "🎒", "🩳", "🩴"]
            )
        }

        if hour <= 8 && temperatureCelsius <= 26 {
            return (
                "Cool morning air, great for light activewear.",
                ["🧢", "👟", "🩳", "🎽"]
            )
        }

        if temperatureCelsius >= 32 {
            return (
                "Perfect weather for a loose t-shirt and airy sundress.",
                ["🕶️", "👒", "👟", "🩴"]
            )
        }

        if temperatureCelsius >= 29 {
            return (
                "Warm and breezy, keep it light and airy.",
                ["🕶️", "👒", "👟", "🩳"]
            )
        }

        return (
            "Mild weather, comfortable for a casual outfit.",
            ["👕", "👟", "🧢", "🩳"]
        )
    }
}
