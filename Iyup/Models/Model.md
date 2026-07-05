# Models

Dokumentasi ini bukan arsip komentar mentah. Komentar lama sudah diubah menjadi catatan desain dan ringkasan fungsi yang lebih mudah dibaca.

## ML

### 1. `Models/MLShadeEnvironmentForecastPoint.swift`

- **Peran MVVM:** Model
- **Ringkasan:** Model titik forecast environment untuk pipeline ML shade.
- **Import utama:** `Foundation`
- **Deklarasi utama:**
  - `struct MLShadeEnvironmentForecastPoint`
- **Property/dependency penting:**
  - `sampleDate` — `let sampleDate: Date`
  - `lux` — `let lux: Double`
  - `temperatureCelsius` — `let temperatureCelsius: Double`
  - `occupancy` — `let occupancy: Double`
- **Informasi dari komentar lama yang sudah dijadikan dokumentasi:**
  - Model ini merepresentasikan satu titik prediksi environment untuk satu spot pada satu waktu sampling.
  - Data di file ini hanya berisi forecast environment; status shadow tetap berasal dari pipeline deterministik.
  - Occupancy menggunakan skala 0.0 sampai 1.0, dari kosong sampai penuh.

### 2. `Models/MLShadeScoredSpotResult.swift`

- **Peran MVVM:** Model
- **Ringkasan:** Model hasil ranking/scoring rekomendasi spot dari pipeline ML.
- **Import utama:** `Foundation`
- **Deklarasi utama:**
  - `struct MLShadeScoredSpotResult`
- **Property/dependency penting:**
  - `id` — `let id = UUID()`
  - `shadowResult` — `let shadowResult: ShadowIntervalResult`
  - `finalScore` — `let finalScore: Double`
  - `shadeStability` — `let shadeStability: Double`
  - `expectedLightScore` — `let expectedLightScore: Double`
  - `expectedTemperatureScore` — `let expectedTemperatureScore: Double`
  - `occupancyPenalty` — `let occupancyPenalty: Double`
  - `meanPredictedLux` — `let meanPredictedLux: Double`
  - `meanPredictedTemperature` — `let meanPredictedTemperature: Double`
  - `maxPredictedOccupancy` — `let maxPredictedOccupancy: Double`
  - `environmentReasons` — `let environmentReasons: [String]`
  - `spot` — `var spot: ParkSpot { shadowResult.spot }`
  - `occupancyLabel` — `var occupancyLabel: String {`
- **Informasi dari komentar lama yang sudah dijadikan dokumentasi:**
  - Model ini adalah hasil akhir rekomendasi setelah ShadowIntervalResult digabung dengan forecast environment dan rule-based scoring.
  - Model ini membungkus ShadowIntervalResult, bukan menggantikan hasil shadow-only yang sudah ada.

## Shade Map / Shadow / Sun

### 1. `Models/ParkLocation.swift`

- **Peran MVVM:** Model
- **Ringkasan:** Model lokasi taman.
- **Import utama:** `Foundation`
- **Deklarasi utama:**
  - `struct ParkLocation`
- **Property/dependency penting:**
  - `latitude` — `let latitude: Double`
  - `longitude` — `let longitude: Double`
  - `timeZoneIdentifier` — `let timeZoneIdentifier: String`
  - `timeZone` — `var timeZone: TimeZone {`
- **Informasi dari komentar lama:** tidak ada catatan desain khusus dari komentar source.

### 2. `Models/ParkSpot.swift`

- **Peran MVVM:** Model
- **Ringkasan:** Model spot/kandidat titik rekomendasi.
- **Import utama:** `Foundation, simd`
- **Deklarasi utama:**
  - `struct ParkSpot`
- **Property/dependency penting:**
  - `id` — `let id: String`
  - `name` — `let name: String`
  - `position` — `let position: SIMD3<Float>`
- **Informasi dari komentar lama:** tidak ada catatan desain khusus dari komentar source.

### 3. `Models/ShadowIntervalRequest.swift`

- **Peran MVVM:** Model
- **Ringkasan:** Model request perhitungan interval bayangan.
- **Import utama:** `Foundation`
- **Deklarasi utama:**
  - `struct ShadowIntervalRequest`
- **Property/dependency penting:**
  - `location` — `let location: ParkLocation`
  - `startDate` — `let startDate: Date`
  - `endDate` — `let endDate: Date`
  - `stepMinutes` — `let stepMinutes: Int`
  - `spots` — `let spots: [ParkSpot]`
- **Informasi dari komentar lama:** tidak ada catatan desain khusus dari komentar source.

### 4. `Models/ShadowIntervalResult.swift`

- **Peran MVVM:** Model
- **Ringkasan:** Model hasil perhitungan interval bayangan.
- **Import utama:** `Foundation`
- **Deklarasi utama:**
  - `struct ShadowIntervalResult`
- **Property/dependency penting:**
  - `id` — `let id = UUID()`
  - `spot` — `let spot: ParkSpot`
  - `timeline` — `let timeline: [ShadowTimelineEntry]`
  - `shadowForecastScore` — `let shadowForecastScore: Double`
  - `shadeDurationMinutes` — `let shadeDurationMinutes: Double`
  - `sunExposureMinutes` — `let sunExposureMinutes: Double`
  - `longestDirectSunStreakMinutes` — `let longestDirectSunStreakMinutes: Double`
  - `firstSunExposureTime` — `let firstSunExposureTime: Date?`
  - `safetyStatus` — `let safetyStatus: ShadowSafetyStatus`
  - `reason` — `let reason: String`
- **Informasi dari komentar lama:** tidak ada catatan desain khusus dari komentar source.

### 5. `Models/ShadowSafetyStatus.swift`

- **Peran MVVM:** Model
- **Ringkasan:** Enum/status keamanan atau kenyamanan bayangan.
- **Import utama:** `Foundation`
- **Deklarasi utama:**
  - `enum ShadowSafetyStatus`
- **Property/dependency penting:**
  - `rankPriority` — `var rankPriority: Int {`
- **Informasi dari komentar lama:** tidak ada catatan desain khusus dari komentar source.

### 6. `Models/ShadowTimelineEntry.swift`

- **Peran MVVM:** Model
- **Ringkasan:** Model entry timeline bayangan per timestamp.
- **Import utama:** `Foundation`
- **Deklarasi utama:**
  - `struct ShadowTimelineEntry`
- **Property/dependency penting:**
  - `id` — `let id = UUID()`
  - `segmentStart` — `let segmentStart: Date`
  - `segmentEnd` — `let segmentEnd: Date`
  - `sampleDate` — `let sampleDate: Date`
  - `sunPosition` — `let sunPosition: SunPosition`
  - `isShaded` — `let isShaded: Bool`
  - `durationMinutes` — `var durationMinutes: Double {`
- **Informasi dari komentar lama:** tidak ada catatan desain khusus dari komentar source.

### 7. `Models/SunPosition.swift`

- **Peran MVVM:** Model
- **Ringkasan:** Model posisi matahari seperti altitude dan azimuth.
- **Import utama:** `Foundation`
- **Deklarasi utama:**
  - `struct SunPosition`
- **Property/dependency penting:**
  - `altitudeDegrees` — `let altitudeDegrees: Double`
  - `azimuthDegrees` — `let azimuthDegrees: Double`
  - `isAboveHorizon` — `var isAboveHorizon: Bool {`
- **Informasi dari komentar lama yang sudah dijadikan dokumentasi:**
  - altitudeDegrees menyatakan sudut matahari dari horizon: 0 derajat berarti horizon, 90 derajat berarti tepat di atas kepala.
  - azimuthDegrees menyatakan arah dari true north searah jarum jam: 0 utara, 90 timur, 180 selatan, dan 270 barat.
