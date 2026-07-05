# App Composition

Dokumentasi ini bukan arsip komentar mentah. Komentar lama sudah diubah menjadi catatan desain dan ringkasan fungsi yang lebih mudah dibaca.

## App Composition

### 1. `ContentView.swift`

- **Peran MVVM:** Composition / root file
- **Ringkasan:** Root UI/tab awal aplikasi; menjadi titik start untuk deterministic shadow dan ranking ML.
- **Import utama:** `SwiftUI`
- **Deklarasi utama:**
  - `struct ContentView`
  - `struct ShadeIntervalSection`
- **Property/dependency penting:**
  - `viewModel` — `@State private var viewModel: MLShadeRecommendationViewModel`
  - `body` — `var body: some View {`
  - `debugRunID` — `let debugRunID = "AUTO-" + String(UUID().uuidString.prefix(8))`
- **Informasi dari komentar lama yang sudah dijadikan dokumentasi:**
  - ContentView berfungsi sebagai composition root untuk UI utama.
  - Satu ViewModel dipakai bersama oleh tab deterministik dan tab ML supaya hasil shadow deterministik dapat langsung menjadi input scoring ML.
  - Auto-calculate dijalankan sekali saat root muncul, bukan saat user berpindah tab, agar kalkulasi tidak dipicu berulang.
  - Kontrol interval dan tombol hitung dipakai bersama oleh dua view sehingga perubahan jam di satu tab otomatis sinkron dengan tab lain.

### 2. `IyupApp.swift`

- **Peran MVVM:** App entry point
- **Ringkasan:** Entry point aplikasi SwiftUI yang membuka ContentView.
- **Import utama:** `SwiftUI`
- **Deklarasi utama:**
  - `struct IyupApp`
- **Property/dependency penting:**
  - `body` — `var body: some Scene {`
- **Informasi dari komentar lama yang sudah dijadikan dokumentasi:**
  - File ini adalah entry point aplikasi SwiftUI dan mengarahkan aplikasi ke ContentView.

## ML

### 1. `MLShadeRecommendationDemoFactory.swift`

- **Peran MVVM:** Composition / root file
- **Ringkasan:** Factory/composition untuk membuat ViewModel aktif dan memilih service Core ML atau mock fallback.
- **Import utama:** `Foundation, simd`
- **Deklarasi utama:**
  - `enum MLShadeRecommendationDemoFactory`
- **Property/dependency penting:**
  - `viewModel` — `let viewModel = try makeCoreMLViewModel()`
  - `now` — `let now = Date()`
  - `startDate` — `let startDate = jakartaCalendar.date(bySettingHour: 15, minute: 0, second: 0, of: now) ?? now`
  - `endDate` — `let endDate = jakartaCalendar.date(bySettingHour: 17, minute: 0, second: 0, of: now)`
  - `location` — `let location = ParkLocation(`
  - `spots` — `let spots = [`
  - `raycastService` — `let raycastService = GeometryShadowRaycastService(`
  - `calculator` — `let calculator = ShadowIntervalCalculator(`
  - `recommendationEngine` — `let recommendationEngine = ShadeRecommendationEngine(calculator: calculator)`
  - `scoringEngine` — `let scoringEngine = MLShadeEnvironmentScoringEngine(`
  - `jakartaCalendar` — `private static var jakartaCalendar: Calendar {`
  - `calendar` — `var calendar = Calendar(identifier: .gregorian)`
- **Function utama:**
  - `static func makeViewModel() -> MLShadeRecommendationViewModel {` — fungsi pendukung sesuai kebutuhan file ini.
  - `static func makeCoreMLViewModel() throws -> MLShadeRecommendationViewModel {` — fungsi pendukung sesuai kebutuhan file ini.
  - `static func makeMockViewModel() -> MLShadeRecommendationViewModel {` — fungsi pendukung sesuai kebutuhan file ini.
  - `private static func makeViewModel(` — fungsi pendukung sesuai kebutuhan file ini.
- **Informasi dari komentar lama yang sudah dijadikan dokumentasi:**
  - Factory ini dipakai untuk komposisi awal dan preview/integrasi awal.
  - makeViewModel() mencoba memakai service Core ML XGBoost asli terlebih dahulu.
  - Jika resource model atau JSON belum ter-bundle dengan benar, factory akan fallback ke mock forecast provider agar UI tetap bisa berjalan.
  - ID spot disamakan dengan mapping XGBoost, misalnya Spot_A, Spot_B, dan Spot_C.

## File yang dihapus dari output

### 1. `SunPosition_artifact.swift`

- **Status:** dihapus dari source output.
- **Alasan:** Legacy artifact algoritma matahari lama; seluruh isi aslinya berupa komentar dan sudah tidak dipakai flow aktif.
- **Informasi isi file sebelum dihapus:**
  - File ini berisi backup algoritma posisi matahari lama berbasis NOAA Solar Calculator.
  - Di dalamnya pernah ada model SunPosition untuk altitude, azimuth, shadowAzimuth, dan perhitungan panjang bayangan dari tinggi objek.
  - File ini juga pernah berisi SolarCalculator untuk Julian Day, geometri orbit matahari, equation of time, hour angle, elevasi, azimuth, dan koreksi refraksi atmosfer.
  - Fungsi historisnya hanya sebagai referensi algoritma; implementasi aktif sekarang memakai SunPosition.swift, OfficialSunKitSunPositionService.swift, dan SunVectorConverter.swift.

### 2. `Screenshot 2026-07-03 at 12.42.41.png`

- **Status:** dihapus dari source output.
- **Alasan:** Screenshot/debug image; tidak direferensikan kode app.
- **Informasi isi file sebelum dihapus:**
  - File ini adalah screenshot/debug lokal, bukan resource yang dipanggil oleh kode Swift.

### 3. `MLModels/Json/model_features.json`

- **Status:** dihapus dari source output.
- **Alasan:** Manifest JSON model lama; service aktif memakai JSON terpisah model_features_*_xgb.json.
- **Informasi isi file sebelum dihapus:**
  - File ini adalah manifest feature gabungan versi lama.
  - Service aktif tidak memakai manifest gabungan ini karena sudah memakai JSON terpisah per target model, misalnya model_features_short_lux_xgb.json dan model_features_long_temp_xgb.json.
