import Foundation

@MainActor
enum SunExposureProjectionStartupRunner {
    private static var hasRun = false

    static func runOnce() async {
        guard !hasRun else {
            return
        }

        hasRun = true

        do {
            let exporter = SunExposureProjectionExporter()

            let entries = try exporter.generate(
                date: SunExposureProjectionExporter.demoDate,
                startHour: 6,
                endHour: 18,
                stepMinutes: 15,
                includeEndTime: true
            )

            let url = try exporter.writeCSV(
                entries: entries,
                fileName: "sun_exposure_projection_06_18.csv"
            )

            print("✅ [SunExposureProjection] CSV generated")
            print("✅ [SunExposureProjection] Rows: \(entries.count)")
            print("✅ [SunExposureProjection] Path: \(url.path)")
        } catch {
            print("❌ [SunExposureProjection] Failed to generate CSV")
            print("❌ [SunExposureProjection] Error: \(error.localizedDescription)")
        }
    }
}
