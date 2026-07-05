# Views

Dokumentasi ini bukan arsip komentar mentah. Komentar lama sudah diubah menjadi catatan desain dan ringkasan fungsi yang lebih mudah dibaca.

## ML

### 1. `Views/MLShadeRankingView.swift`

- **Peran MVVM:** View
- **Ringkasan:** View untuk menampilkan ranking rekomendasi spot berdasarkan forecast ML dan environment scoring.
- **Import utama:** `SwiftUI`
- **Deklarasi utama:**
  - `struct MLShadeRankingView`
  - `struct ScoredResultRow`
- **Property/dependency penting:**
  - `viewModel` — `@Bindable var viewModel: MLShadeRecommendationViewModel`
  - `body` — `var body: some View {`
  - `errorMessage` — `if let errorMessage = viewModel.errorMessage {`
  - `rank` — `let rank: Int`
  - `scored` — `let scored: MLShadeScoredSpotResult`
- **Function utama:**
  - `private func tintColor(for score: Double) -> Color {` — menentukan warna visual berdasarkan score.
- **Informasi dari komentar lama yang sudah dijadikan dokumentasi:**
  - View ini khusus untuk cabang ML.
  - UI menampilkan ranking final dari MLShadeEnvironmentScoringEngine.
  - Final score berasal dari gabungan shadow, lux, suhu, stabilitas, dan penalti occupancy, disertai prediksi environment per spot.

## Shade Map / Shadow / Sun

### 1. `Views/DeterministicShadowView.swift`

- **Peran MVVM:** View
- **Ringkasan:** View untuk menghitung dan menampilkan hasil bayangan deterministik tanpa forecast ML.
- **Import utama:** `SwiftUI`
- **Deklarasi utama:**
  - `struct DeterministicShadowView`
  - `struct ShadowResultRow`
- **Property/dependency penting:**
  - `viewModel` — `@Bindable var viewModel: MLShadeRecommendationViewModel`
  - `body` — `var body: some View {`
  - `errorMessage` — `if let errorMessage = viewModel.errorMessage {`
  - `result` — `let result: ShadowIntervalResult`
  - `symbols` — `let symbols = timeline.map { $0.isShaded ? "1" : "0" }`
- **Function utama:**
  - `private func timelineText(_ timeline: [ShadowTimelineEntry]) -> Text {` — mengubah timeline shadow menjadi teks ringkas.
- **Informasi dari komentar lama yang sudah dijadikan dokumentasi:**
  - View ini khusus untuk cabang deterministik.
  - UI menampilkan hasil mentah pipeline shadow: timeline teduh/panas, shadow score, durasi, dan safety status.
  - View ini tidak menyentuh hasil ML sama sekali.

### 2. `Views/ShadeMap.swift`

- **Peran MVVM:** View
- **Ringkasan:** View map 3D taman dan proyeksi bayangan berbasis posisi matahari.
- **Import utama:** `SwiftUI, RealityKit`
- **Deklarasi utama:**
  - `struct ShadeMapView`
  - `class ParkScene`
- **Property/dependency penting:**
  - `hour` — `@State private var hour: Double = 10`
  - `scene` — `@State private var scene = ParkScene()`
  - `parkLocation` — `private let parkLocation = ParkLocation(`
  - `sun` — `private var sun: SunPosition {`
  - `dayFactor` — `private var dayFactor: Double {`
  - `skyGradient` — `private var skyGradient: LinearGradient {`
  - `controls` — `private var controls: some View {`
  - `container` — `private let container = Entity()`
  - `worldRoot` — `private let worldRoot = Entity()`
  - `sunLight` — `private let sunLight = DirectionalLight()`
  - `fillLight` — `private let fillLight = DirectionalLight()`
  - `targetWorld` — `private var targetWorld: SIMD3<Float> = .zero`
  - `sunPositionService` — `private let sunPositionService = OfficialSunKitSunPositionService()`
  - `sunVectorConverter` — `private let sunVectorConverter = SunVectorConverter(`
- **Function utama:**
  - `func build() async -> Entity {` — membangun scene/entity yang akan ditampilkan.
  - `func setSun(` — mengatur atau menghitung posisi matahari untuk visualisasi bayangan.
  - `func sunPosition(` — mengatur atau menghitung posisi matahari untuk visualisasi bayangan.
  - `private func addTrees(` — menambahkan objek pohon/occluder pada scene.
  - `static func jakartaDate(hour: Int) -> Date {` — membuat Date dengan timezone/konteks Jakarta.
- **Informasi dari komentar lama yang sudah dijadikan dokumentasi:**
  - Scene memakai orientasi northNegative agar arah visual matahari konsisten dengan logic lama.
  - Jika arah bayangan terlihat terbalik setelah integrasi map, konfigurasi north dapat diganti ke northPositive.

## File yang dihapus dari output

### 1. `Views/MLShadeRecommendationView.swift`

- **Status:** dihapus dari source output.
- **Alasan:** Legacy ML view lama; sudah digantikan oleh pemisahan DeterministicShadowView dan MLShadeRankingView.
- **Informasi isi file sebelum dihapus:**
  - File ini adalah view ML lama yang pernah menggabungkan kontrol interval, tombol Hitung Ranking ML, ranking final, dan rincian shadowmap dalam satu layar.
  - UI lama ini memakai NavigationStack, List, Section Interval, DatePicker mulai/selesai, tombol kalkulasi, ProgressView, scoredRow, shadowRow, dan timelineText.
  - Fungsi file ini sudah dipecah agar UI deterministik dan UI ML tidak tercampur: DeterministicShadowView menangani shadow mentah, sedangkan MLShadeRankingView menangani ranking ML.

### 2. `Views/ShadeRecommendationView.swift`

- **Status:** dihapus dari source output.
- **Alasan:** UI rekomendasi deterministik lama; tidak reachable dari ContentView aktif.
- **Informasi isi file sebelum dihapus:**
  - File ini adalah view deterministik lama untuk rekomendasi spot teduh tanpa layer ML.
  - Isinya menampilkan date picker, tombol hitung spot aman, ranking berdasarkan ShadowIntervalResult, durasi teduh, durasi kena matahari, alasan, dan timeline bayangan.
  - Karena ContentView aktif sudah memakai DeterministicShadowView, file ini tidak lagi diperlukan dalam flow utama.
