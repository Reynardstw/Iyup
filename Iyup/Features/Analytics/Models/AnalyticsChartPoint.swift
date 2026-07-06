import Foundation

struct AnalyticsChartPoint: Identifiable, Equatable, Sendable {
    let id = UUID()
    let date: Date
    let label: String
    let value: Double
}
