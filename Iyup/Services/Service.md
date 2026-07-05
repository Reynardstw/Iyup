# Services

Dokumentasi ini bukan arsip komentar mentah. Komentar lama sudah diubah menjadi catatan desain dan ringkasan fungsi yang lebih mudah dibaca.

## ML

### 1. `Services/MLShadeCoreMLForecastService.swift`

- **Peran MVVM:** Service / domain logic
- **Ringkasan:** Service forecast aktif yang meload model Core ML dan JSON feature untuk lux, temperature, dan occupancy.
- **Import utama:** `Foundation, CoreML`
- **Deklarasi utama:**
  - `class MLShadeCoreMLForecastService`
  - `enum ModelKey`
  - `struct ModelManifest`
  - `struct LoadedModel`
- **Property/dependency penting:**
  - `bundle` — `private let bundle: Bundle`
  - `calendar` — `private let calendar: Calendar`
  - `sensorFeatureProvider` — `private let sensorFeatureProvider: SensorFeatureProvider`
  - `spotMapping` — `private let spotMapping: [String: Int]`
  - `loadedModels` — `private let loadedModels: [ModelKey: LoadedModel]`
- **Function utama:**
  - `func forecast(` — menghasilkan prediksi environment untuk spot dan timeline tertentu.
  - `private func spotNumber(for spot: ParkSpot) -> Int? {` — fungsi pendukung sesuai kebutuhan file ini.
  - `private func predict(` — menjalankan inferensi model untuk target tertentu.
  - `private func mergeAutomaticFeatures(` — melengkapi atau menyatukan feature input agar aman untuk model.
  - `private func mergeSafeSensorDefaults(` — melengkapi atau menyatukan feature input agar aman untuk model.
  - `private func fillLagDefaults(` — melengkapi atau menyatukan feature input agar aman untuk model.
  - `private static func defaultSensorFeatureProvider(` — fungsi pendukung sesuai kebutuhan file ini.
  - `private static func loadManifest(` — meload metadata/urutan feature dari JSON.
  - `private static func loadModel(` — meload file model Core ML dari bundle.
  - `private static func resourceURL(` — mencari URL resource dari bundle aplikasi.
  - `private func normalizeSpotID(_ value: String) -> String {` — menormalkan format identifier agar cocok dengan mapping.
- **Informasi dari komentar lama yang sudah dijadikan dokumentasi:**
  - Service ini adalah implementasi Core ML aktif untuk add-on rekomendasi spot teduh berbasis ML.
  - Implementasi ini disesuaikan dengan export XGBoost: memakai enam file JSON feature terpisah, input spot_num, dan enam file Model*.mlmodel.
  - Service ini menyediakan default aman untuk sensor dan histori agar integrasi awal tidak crash ketika data sensor nyata belum tersedia.
  - Konversi weekday mengikuti format Python/pandas: Monday = 0 sampai Sunday = 6.
  - Input model menggunakan spot_num, bukan spot_id.

### 2. `Services/MLShadeEnvironmentForecastProviding.swift`

- **Peran MVVM:** Service / domain logic
- **Ringkasan:** Protocol abstraction untuk provider forecast environment.
- **Import utama:** `Foundation`
- **Deklarasi utama:**
  - `protocol MLShadeEnvironmentForecastProviding`
- **Function utama:**
  - `func forecast(` — menghasilkan prediksi environment untuk spot dan timeline tertentu.
  - `func forecast(` — menghasilkan prediksi environment untuk spot dan timeline tertentu.
- **Informasi dari komentar lama yang sudah dijadikan dokumentasi:**
  - Protocol ini menjadi abstraksi provider forecast untuk MLShadeEnvironmentScoringEngine.
  - Pipeline deterministik menghasilkan ShadowIntervalResult terlebih dahulu; provider ini menambahkan prediksi environment di atas timeline tersebut.

### 3. `Services/MLShadeEnvironmentScoringEngine.swift`

- **Peran MVVM:** Service / domain logic
- **Ringkasan:** Engine scoring yang menggabungkan shadow interval dengan forecast environment.
- **Import utama:** `Foundation`
- **Deklarasi utama:**
  - `struct MLShadeEnvironmentScoringEngine`
- **Property/dependency penting:**
  - `forecastService` — `private let forecastService: any MLShadeEnvironmentForecastProviding`
  - `scoringService` — `private let scoringService: MLShadeScoringService`
  - `scoredResults` — `var scoredResults: [MLShadeScoredSpotResult] = []`
  - `forecastPoints` — `let forecastPoints = try await forecastService.forecast(`
  - `scored` — `let scored = makeScoredResult(`
  - `sortedResults` — `let sortedResults = scoredResults.sorted { lhs, rhs in`
  - `count` — `let count = Double(forecastPoints.count)`
  - `meanLux` — `let meanLux = forecastPoints.map(\.lux).reduce(0.0, +) / count`
  - `meanTemperature` — `let meanTemperature = forecastPoints.map(\.temperatureCelsius).reduce(0.0, +) / count`
  - `maxOccupancy` — `let maxOccupancy = forecastPoints.map(\.occupancy).max() ?? 0.0`
  - `stability` — `let stability = scoringService.shadeStability(timeline: shadowResult.timeline)`
  - `lightScore` — `let lightScore = scoringService.lightScore(lux: meanLux)`
  - `temperatureScore` — `let temperatureScore = scoringService.temperatureScore(celsius: meanTemperature)`
  - `occupancyPenalty` — `let occupancyPenalty = scoringService.occupancyPenalty(occupancy: maxOccupancy)`
  - `finalScore` — `let finalScore = scoringService.finalForecastScore(`
  - `reasons` — `var reasons: [String] = []`
- **Function utama:**
  - `func score(` — menghitung skor atau ranking hasil rekomendasi.
  - `func score(` — menghitung skor atau ranking hasil rekomendasi.
  - `private func makeScoredResult(` — fungsi pendukung sesuai kebutuhan file ini.
  - `private func makeEnvironmentReasons(` — fungsi pendukung sesuai kebutuhan file ini.
- **Informasi dari komentar lama yang sudah dijadikan dokumentasi:**
  - Engine ini menggabungkan output shadow deterministik dengan forecast environment ML.
  - Pipeline shadow lama tetap utuh: ShadeRecommendationEngine menghasilkan ShadowIntervalResult, lalu service ini menambahkan scoring final di atasnya.
  - Penalti keramaian dibuat konservatif dengan mengikuti prediksi occupancy paling tinggi di interval.

### 4. `Services/MLShadeForecastError.swift`

- **Peran MVVM:** Service / domain logic
- **Ringkasan:** Error type untuk proses forecast ML shade.
- **Import utama:** `Foundation`
- **Deklarasi utama:**
  - `enum MLShadeForecastError`
- **Property/dependency penting:**
  - `errorDescription` — `var errorDescription: String? {`
  - `name` — `case .modelUnavailable(let name):`
  - `feature` — `case .missingFeature(let feature, let model):`
  - `expected` — `case .invalidOutput(let expected, let model, let available):`
  - `spotID` — `case .spotMappingNotFound(let spotID):`
  - `spotName` — `case .emptyTimeline(let spotName):`
- **Informasi dari komentar lama yang sudah dijadikan dokumentasi:**
  - Error type ini khusus untuk add-on forecast ML/environment.
  - Error ini dipisah dari ShadowCalculationError karena pipeline shadow bersifat deterministik.

### 5. `Services/MLShadeMockEnvironmentForecastService.swift`

- **Peran MVVM:** Service / domain logic
- **Ringkasan:** Mock/fallback forecast provider ketika model Core ML tidak bisa dimuat.
- **Import utama:** `Foundation`
- **Deklarasi utama:**
  - `struct MLShadeMockEnvironmentForecastService`
- **Property/dependency penting:**
  - `shaded` — `let shaded = entry.isShaded`
  - `altitude` — `let altitude = max(0.0, entry.sunPosition.altitudeDegrees)`
  - `lux` — `let lux = shaded ? 900.0 : min(70_000.0, 8_000.0 + altitude * 850.0)`
  - `temperature` — `let temperature = shaded ? 30.0 : min(36.0, 30.0 + altitude / 25.0)`
  - `occupancy` — `let occupancy = shaded ? 0.45 : 0.25`
- **Function utama:**
  - `func forecast(` — menghasilkan prediksi environment untuk spot dan timeline tertentu.
- **Informasi dari komentar lama yang sudah dijadikan dokumentasi:**
  - Service ini adalah fallback ringan untuk preview dan skenario ketika resource Core ML belum masuk bundle.

### 6. `Services/MLShadeScoringService.swift`

- **Peran MVVM:** Service / domain logic
- **Ringkasan:** Rule-based scoring untuk mengubah prediksi environment menjadi komponen skor.
- **Import utama:** `Foundation`
- **Deklarasi utama:**
  - `struct MLShadeScoringService`
  - `struct Weights`
- **Property/dependency penting:**
  - `shadowForecast` — `let shadowForecast: Double`
  - `expectedLight` — `let expectedLight: Double`
  - `shadeStability` — `let shadeStability: Double`
  - `expectedTemperature` — `let expectedTemperature: Double`
  - `interval` — `static let interval = Weights(`
  - `weights` — `private let weights: Weights`
  - `flags` — `let flags = timeline.map(\.isShaded)`
  - `transitions` — `let transitions = zip(flags, flags.dropFirst())`
  - `base` — `let base = weights.shadowForecast * shadowForecastScore`
  - `t` — `let t = (x - xs[index - 1]) / (xs[index] - xs[index - 1])`
- **Function utama:**
  - `func lightScore(lux: Double) -> Double {` — fungsi pendukung sesuai kebutuhan file ini.
  - `func temperatureScore(celsius: Double) -> Double {` — fungsi pendukung sesuai kebutuhan file ini.
  - `func occupancyPenalty(occupancy: Double) -> Double {` — fungsi pendukung sesuai kebutuhan file ini.
  - `func shadeStability(timeline: [ShadowTimelineEntry]) -> Double {` — fungsi pendukung sesuai kebutuhan file ini.
  - `func finalForecastScore(` — fungsi pendukung sesuai kebutuhan file ini.
  - `private func interpolate(` — fungsi pendukung sesuai kebutuhan file ini.
- **Informasi dari komentar lama yang sudah dijadikan dokumentasi:**
  - Service ini mengubah output ML menjadi skor sebelum digabung dengan skor shadow deterministik.
  - Output ML tidak langsung menjadi keputusan final; nilai lux, suhu, stabilitas, dan occupancy diproses sebagai komponen scoring.

## Shade Map / Shadow / Sun

### 1. `Services/GeometryShadowRaycastService.swift`

- **Peran MVVM:** Service / domain logic
- **Ringkasan:** Service raycast/geometri untuk menentukan apakah suatu titik terkena bayangan occluder.
- **Import utama:** `Foundation, simd`
- **Deklarasi utama:**
  - `struct ShadowOccluderSphere`
  - `struct GeometryShadowRaycastService`
- **Property/dependency penting:**
  - `id` — `let id: String`
  - `center` — `let center: SIMD3<Float>`
  - `radius` — `let radius: Float`
  - `occluders` — `let occluders: [ShadowOccluderSphere]`
  - `normalizedDirection` — `let normalizedDirection = simd_normalize(sunDirection)`
  - `originToCenter` — `let originToCenter = origin - sphereCenter`
  - `a` — `let a = simd_dot(direction, direction)`
  - `b` — `let b = 2.0 * simd_dot(originToCenter, direction)`
  - `c` — `let c = simd_dot(originToCenter, originToCenter) - sphereRadius * sphereRadius`
  - `discriminant` — `let discriminant = b * b - 4.0 * a * c`
  - `sqrtDiscriminant` — `let sqrtDiscriminant = sqrt(discriminant)`
  - `t1` — `let t1 = (-b - sqrtDiscriminant) / (2.0 * a)`
  - `t2` — `let t2 = (-b + sqrtDiscriminant) / (2.0 * a)`
  - `minimumHitDistance` — `let minimumHitDistance: Float = 0.05`
- **Function utama:**
  - `func isPointShaded(` — fungsi pendukung sesuai kebutuhan file ini.
  - `private func rayIntersectsSphere(` — fungsi pendukung sesuai kebutuhan file ini.
- **Informasi dari komentar lama yang sudah dijadikan dokumentasi:**
  - Service ini dipakai untuk validasi algoritma raycast secara geometri sebelum terhubung ke RealityKit.
  - Setiap occluder direpresentasikan sebagai sphere.

### 2. `Services/OfficialSunKitSunPositionService.swift`

- **Peran MVVM:** Service / domain logic
- **Ringkasan:** Provider posisi matahari berbasis SunKit.
- **Import utama:** `Foundation, CoreLocation, SunKit`
- **Deklarasi utama:**
  - `struct OfficialSunKitSunPositionService`
- **Property/dependency penting:**
  - `coordinate` — `let coordinate = CLLocation(`
  - `timeZone` — `let timeZone = TimeZone(identifier: location.timeZoneIdentifier)`
  - `sun` — `var sun = Sun(`
- **Function utama:**
  - `func position(` — fungsi pendukung sesuai kebutuhan file ini.
- **Informasi dari komentar lama yang sudah dijadikan dokumentasi:**
  - Adapter ini memakai package SunKit-Swift/SunKit sebagai sumber posisi matahari resmi.
  - SunKit hanya menghitung altitude dan azimuth; logic bayangan tetap dihitung oleh ShadowIntervalCalculator melalui SunVectorConverter dan ShadowRaycastProviding.

### 3. `Services/ShadeRecommendationEngine.swift`

- **Peran MVVM:** Service / domain logic
- **Ringkasan:** Engine rekomendasi spot teduh berbasis interval bayangan deterministik.
- **Import utama:** `Foundation`
- **Deklarasi utama:**
  - `struct ShadeRecommendationEngine`
- **Property/dependency penting:**
  - `calculator` — `private let calculator: ShadowIntervalCalculator`
  - `recommendedThreshold` — `private let recommendedThreshold: Double`
  - `alternativeThreshold` — `private let alternativeThreshold: Double`
  - `maximumRecommendedDirectSunStreakMinutes` — `private let maximumRecommendedDirectSunStreakMinutes: Double`
- **Function utama:**
  - `func recommend(` — fungsi pendukung sesuai kebutuhan file ini.
  - `private func makeResult(` — fungsi pendukung sesuai kebutuhan file ini.
  - `private func evaluateStatus(` — fungsi pendukung sesuai kebutuhan file ini.
  - `private func calculateLongestDirectSunStreakMinutes(` — menjalankan pipeline kalkulasi dari UI/ViewModel.
  - `private func makeReason(` — fungsi pendukung sesuai kebutuhan file ini.
  - `private func formatTime(_ date: Date) -> String {` — fungsi pendukung sesuai kebutuhan file ini.
- **Informasi dari komentar lama:** tidak ada catatan desain khusus dari komentar source.

### 4. `Services/ShadowCalculationError.swift`

- **Peran MVVM:** Service / domain logic
- **Ringkasan:** Error type untuk perhitungan shadow.
- **Import utama:** `Foundation`
- **Deklarasi utama:**
  - `enum ShadowCalculationError`
- **Property/dependency penting:**
  - `errorDescription` — `var errorDescription: String? {`
- **Informasi dari komentar lama:** tidak ada catatan desain khusus dari komentar source.

### 5. `Services/ShadowIntervalCalculator.swift`

- **Peran MVVM:** Service / domain logic
- **Ringkasan:** Kalkulator interval bayangan dari request, sun provider, dan raycast provider.
- **Import utama:** `Foundation, simd`
- **Deklarasi utama:**
  - `struct ShadowIntervalCalculator`
- **Property/dependency penting:**
  - `sunPositionService` — `private let sunPositionService: SunPositionProviding`
  - `shadowRaycastService` — `private let shadowRaycastService: ShadowRaycastProviding`
  - `sampler` — `private let sampler: DateIntervalSampler`
  - `sunVectorConverter` — `private let sunVectorConverter: SunVectorConverter`
  - `segments` — `let segments = try sampler.makeSegments(`
  - `timelines` — `var timelines: [ParkSpot: [ShadowTimelineEntry]] = Dictionary(`
  - `sampleDate` — `let sampleDate = segment.midpoint`
  - `sunPosition` — `let sunPosition = try sunPositionService.position(`
  - `sunDirection` — `let sunDirection = sunVectorConverter.directionVector(`
  - `isShaded` — `let isShaded: Bool`
  - `entry` — `let entry = ShadowTimelineEntry(`
- **Function utama:**
  - `func calculate(` — menjalankan pipeline kalkulasi dari UI/ViewModel.
- **Informasi dari komentar lama yang sudah dijadikan dokumentasi:**
  - Saat malam atau matahari berada di bawah horizon, kalkulator menganggap tidak ada direct sunlight.

### 6. `Services/ShadowRaycastProviding.swift`

- **Peran MVVM:** Service / domain logic
- **Ringkasan:** Protocol abstraction untuk raycast bayangan.
- **Import utama:** `Foundation, simd`
- **Deklarasi utama:**
  - `protocol ShadowRaycastProviding`
- **Function utama:**
  - `func isPointShaded(` — fungsi pendukung sesuai kebutuhan file ini.
- **Informasi dari komentar lama yang sudah dijadikan dokumentasi:**
  - Protocol ini mengembalikan true ketika garis dari titik menuju matahari terhalang occluder.

### 7. `Services/SunPositionProviding.swift`

- **Peran MVVM:** Service / domain logic
- **Ringkasan:** Protocol abstraction untuk provider posisi matahari.
- **Import utama:** `Foundation`
- **Deklarasi utama:**
  - `protocol SunPositionProviding`
- **Function utama:**
  - `func position(` — fungsi pendukung sesuai kebutuhan file ini.
- **Informasi dari komentar lama:** tidak ada catatan desain khusus dari komentar source.

### 8. `Services/SunVectorConverter.swift`

- **Peran MVVM:** Service / domain logic
- **Ringkasan:** Konversi posisi matahari menjadi vektor arah untuk kalkulasi bayangan.
- **Import utama:** `Foundation, simd`
- **Deklarasi utama:**
  - `enum SceneZAxisDirection`
  - `struct SunVectorConverter`
- **Property/dependency penting:**
  - `zAxisDirection` — `let zAxisDirection: SceneZAxisDirection`
  - `altitude` — `let altitude = degreesToRadians(sunPosition.altitudeDegrees)`
  - `azimuth` — `let azimuth = degreesToRadians(sunPosition.azimuthDegrees)`
  - `horizontalLength` — `let horizontalLength = cos(altitude)`
  - `east` — `let east = horizontalLength * sin(azimuth)`
  - `up` — `let up = sin(altitude)`
  - `north` — `let north = horizontalLength * cos(azimuth)`
  - `sceneNorth` — `let sceneNorth: Double = {`
  - `vector` — `let vector = SIMD3<Float>(`
- **Function utama:**
  - `func directionVector(from sunPosition: SunPosition) -> SIMD3<Float> {` — fungsi pendukung sesuai kebutuhan file ini.
  - `private func degreesToRadians(_ degrees: Double) -> Double {` — fungsi pendukung sesuai kebutuhan file ini.
- **Informasi dari komentar lama yang sudah dijadikan dokumentasi:**
  - Converter ini mengubah altitude dan azimuth menjadi vektor 3D.
  - Asumsi koordinat default: X = East, Y = Up, dan Z = North, kecuali konfigurasi mengubah orientasi north.

## General

### 1. `Services/DateIntervalSampler.swift`

- **Peran MVVM:** Service / domain logic
- **Ringkasan:** Utility sampling tanggal/waktu dalam interval.
- **Import utama:** `Foundation`
- **Deklarasi utama:**
  - `struct DateIntervalSegment`
  - `struct DateIntervalSampler`
- **Property/dependency penting:**
  - `id` — `let id = UUID()`
  - `start` — `let start: Date`
  - `end` — `let end: Date`
  - `midpoint` — `var midpoint: Date {`
  - `durationMinutes` — `var durationMinutes: Double {`
  - `stepSeconds` — `let stepSeconds = TimeInterval(stepMinutes * 60)`
  - `segments` — `var segments: [DateIntervalSegment] = []`
  - `currentStart` — `var currentStart = startDate`
  - `proposedEnd` — `let proposedEnd = currentStart.addingTimeInterval(stepSeconds)`
  - `currentEnd` — `let currentEnd = min(proposedEnd, endDate)`
- **Function utama:**
  - `func makeSegments(` — fungsi pendukung sesuai kebutuhan file ini.
- **Informasi dari komentar lama:** tidak ada catatan desain khusus dari komentar source.

## File yang dihapus dari output

### 1. `Services/CoreMLEnvironmentForecastService.swift`

- **Status:** dihapus dari source output.
- **Alasan:** Core ML forecast service versi lama; flow aktif memakai MLShadeCoreMLForecastService.
- **Informasi isi file sebelum dihapus:**
  - File ini adalah service forecast Core ML versi lama.
  - Service lama ini memuat enam model: ModelShortLux, ModelShortTemp, ModelShortOccupancy, ModelLongLux, ModelLongTemp, dan ModelLongOccupancy.
  - Fungsinya pernah dipakai untuk prediksi short-term dan long-term lux, temperature, serta occupancy.
  - Versi aktif sekarang adalah MLShadeCoreMLForecastService.swift yang sudah disesuaikan dengan export XGBoost dan JSON feature terpisah.

### 2. `Services/ForecastFeatureBuilder.swift`

- **Status:** dihapus dari source output.
- **Alasan:** Feature builder milik CoreMLEnvironmentForecastService lama; tidak diperlukan setelah service lama dihapus.
- **Informasi isi file sebelum dihapus:**
  - File ini adalah builder feature untuk service ML lama.
  - Isinya pernah mengubah sensor/current-state, histori, lag feature, rolling mean, trend, waktu, weekend flag, cloud cover, shadow status, dan spot mapping menjadi dictionary input model.
  - Karena CoreMLEnvironmentForecastService.swift lama dihapus, builder ini juga tidak lagi dipakai.
