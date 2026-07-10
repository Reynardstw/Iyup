# Iyup Architecture

## Prinsip struktur
Project memakai pola feature-first MVVM. Setiap fitur menyimpan model, service, view model, dan view-nya sendiri supaya perubahan di satu fitur tidak menyebar ke folder global.

```text
Iyup/
├─ App/
│  ├─ Composition/
│  └─ Views/
├─ Features/
│  └─ <FeatureName>/
│     ├─ Models/
│     ├─ Services/
│     ├─ ViewModels/
│     ├─ Views/
│     │  └─ Components/
│     └─ <FeatureName>.md
├─ Shared/
│  ├─ Location/
│  ├─ Protocols/
│  ├─ SharedModels/
│  └─ Sun/
│     ├─ Models/
│     └─ Services/
└─ Resources/
   ├─ Assets.xcassets/
   └─ RealityKit/
```

## Arah dependency
```text
App → Features → Shared
```

Aturan utamanya:
- `App/Composition` bertugas melakukan dependency wiring.
- `Features` boleh memakai model/protocol/service dari `Shared`.
- `Shared` tidak boleh bergantung ke feature tertentu.
- View hanya mengatur UI dan interaksi ringan.
- ViewModel menyimpan state dan mengorkestrasi service.
- Service berisi akses framework, kalkulasi, persistence, notifikasi, atau adapter eksternal.

## App utama
Entry app adalah `IyupApp.swift` yang membuka `RootTabView`. `RootTabView` berisi alur utama: Parks/ShadeMap, Trips, dan Search placeholder.

`ContentView` debug tab lama sudah dihapus supaya tidak ada UI demo yang ikut menjadi bagian project aktif.

## App Composition
`App/Composition/AppComposition.swift` menjadi pusat pembuatan dependency. File ini membuat service Core ML atau fallback mock, menyiapkan lokasi taman, spot bench, raycast service, deterministic engine, scoring engine, WeatherKit service, Location service, dan ViewModel yang dibutuhkan halaman.

`AppComposition.makePlanTripViewModel()` menyediakan dependency untuk Plan Trip. Geometry taman sekarang disimpan di `Features/Deterministic/Data/ParkGeometryCatalog.swift` supaya data runtime tidak tercampur dengan utilitas export CSV.

## Resource
- `Resources/RealityKit/park.usdz` adalah asset 3D taman utama.
- `Resources/RealityKit/map_pin_location_pin.usdz` adalah asset pin shade spot.
- `Resources/Assets.xcassets` menyimpan logo, app icon, accent color, dan image pendukung.
- `Features/ML/Resources` menyimpan model `.mlmodel` dan JSON feature list karena resource tersebut spesifik untuk fitur ML.

## Cleanup fase ini
Fase cleanup ini menghapus UI debug lama, modul Analytics, ParkDetail sheet wrapper lama, dan utilitas export CSV. Core function yang masih mungkin dipakai fitur utama atau future feature tetap dipertahankan.

Dihapus:
- `App/Views/ContentView.swift`
- `Features/Analytics/`
- standalone/demo views untuk Deterministic, Score Ranking, Location, Weather, dan ML manual debug
- helper UI/debug-only yang hanya dipakai view demo tersebut
- `Features/ParkDetail/Views/ParkDetailSheetView.swift` karena sudah digantikan oleh `ParkDetailSheetContent.swift`
- `Features/Deterministic/Services/SunExposureProjectionExporter.swift` dan model export CSV-nya

Dipertahankan:
- Core deterministic services/models, termasuk `ParkGeometryCatalog`
- Core score and ML services/models/view model
- Weather models/services/view model
- Location models/services/view model
- Seluruh IoT module
- ShadeMap, ParkDetail, Trips, dan Shared modules
