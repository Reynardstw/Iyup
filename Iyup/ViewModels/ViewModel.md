# ViewModels

Dokumentasi ini bukan arsip komentar mentah. Komentar lama sudah diubah menjadi catatan desain dan ringkasan fungsi yang lebih mudah dibaca.

## ML

### 1. `ViewModels/MLShadeRecommendationViewModel.swift`

- **Peran MVVM:** ViewModel
- **Ringkasan:** State dan orchestration kalkulasi rekomendasi ML di UI.
- **Import utama:** `Foundation, Observation`
- **Deklarasi utama:**
  - `class MLShadeRecommendationViewModel`
- **Property/dependency penting:**
  - `shadowResults` — `var shadowResults: [ShadowIntervalResult] = []`
  - `scoredResults` — `var scoredResults: [MLShadeScoredSpotResult] = []`
  - `errorMessage` — `var errorMessage: String?`
  - `isCalculating` — `var isCalculating = false`
  - `startDate` — `var startDate: Date`
  - `endDate` — `var endDate: Date`
  - `stepMinutes` — `var stepMinutes: Int`
  - `recommendationEngine` — `private let recommendationEngine: ShadeRecommendationEngine`
  - `scoringEngine` — `private let scoringEngine: MLShadeEnvironmentScoringEngine`
  - `location` — `private let location: ParkLocation`
  - `spots` — `private let spots: [ParkSpot]`
  - `request` — `let request = ShadowIntervalRequest(`
  - `deterministicResults` — `let deterministicResults = try recommendationEngine.recommend(request: request)`
- **Function utama:**
  - `func calculate() async {` — menjalankan pipeline kalkulasi dari UI/ViewModel.
  - `func calculate(debugRunID: String) async {` — menjalankan pipeline kalkulasi dari UI/ViewModel.
- **Informasi dari komentar lama yang sudah dijadikan dokumentasi:**
  - ViewModel ini dibuat khusus untuk rekomendasi ML, bukan pengganti ViewModel shadow-only lama.
  - Pemisahan tipe ini menjaga fitur shadow-only tidak bentrok nama dengan fitur ML.

## File yang dihapus dari output

### 1. `ViewModels/ShadeRecommendationViewModel.swift`

- **Status:** dihapus dari source output.
- **Alasan:** ViewModel pasangan ShadeRecommendationView lama; tidak reachable karena view lamanya dihapus.
- **Informasi isi file sebelum dihapus:**
  - File ini adalah ViewModel lama untuk ShadeRecommendationView.
  - Isinya mengatur state results, errorMessage, isCalculating, startDate, endDate, serta fungsi calculateRecommendation().
  - Di preview/demo, file ini pernah membuat data dummy lokasi Jakarta, spot A/B/C, occluder pohon, GeometryShadowRaycastService, OfficialSunKitSunPositionService, ShadowIntervalCalculator, dan ShadeRecommendationEngine.
  - Karena view pasangannya dihapus, ViewModel ini ikut tidak diperlukan.
