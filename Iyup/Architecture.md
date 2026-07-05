# Iyup Feature-First MVVM Structure

## Major feature
Project dipisah menjadi empat feature utama:

1. `ShadeMap` untuk visualisasi map 3D dan arah cahaya matahari.
2. `Deterministic` untuk kalkulasi timeline teduh/kena matahari.
3. `ML` untuk forecast lux, suhu, dan occupancy.
4. `Score` untuk orkestrasi dan ranking final.


## App Composition

`App/Composition/AppComposition.swift` menjadi tempat dependency wiring. File ini membuat service Core ML atau fallback mock, menyiapkan lokasi, spot demo, raycast service, deterministic engine, scoring engine, lalu mengembalikan ViewModel untuk `ContentView`.

## Arah data utama

```text
App
→ Score ViewModel
→ Deterministic engine
→ ShadowIntervalResult
→ ML forecast service
→ MLShadeEnvironmentForecastPoint
→ Score engine
→ MLShadeScoredSpotResult
→ View
```

## Arah dependency

```text
App
↓
Features
↓
Core
```

Feature tidak perlu saling import secara langsung. Kontrak lintas feature diletakkan di `Core/Protocols`.

## Resource
- `Features/ML/Resources` menyimpan model ML dan JSON karena resource tersebut spesifik fitur ML.
- `Resources/Reality` menyimpan file map 3D karena dipakai oleh ShadeMap.
- `Resources/Assets.xcassets` menyimpan asset app.

## Perubahan dari struktur lama
- `Views/`, `ViewModels/`, `Models/`, dan `Services/` root sudah diganti menjadi feature-first.
- `ShadeMap.swift` dipecah menjadi `ShadeMapView.swift` dan `ParkScene.swift`.
- Synthetic tree generator di `ParkScene` dihapus.
- `ContentView` sekarang punya 3 tab: Deterministik, Ranking ML, dan Shade Map.
