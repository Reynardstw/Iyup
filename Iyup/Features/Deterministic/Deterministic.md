# Deterministic Feature

## Tujuan
Menghitung status teduh atau terkena matahari untuk setiap spot berdasarkan interval waktu, posisi matahari, dan raycast/occluder geometry.

## Status UI
Standalone/debug view deterministic dari tab lama sudah dihapus. Core deterministic tetap dipakai oleh ShadeMap, ParkDetail, PlanTrip, dan scoring.

## File utama
- `Services/ShadowIntervalCalculator2.swift` menghitung timeline bayangan per sample waktu. Type utamanya tetap `ShadowIntervalCalculator`.
- `Services/ShadeRecommendationEngine.swift` menjalankan kalkulasi untuk semua spot.
- `Services/GeometryShadowRaycastService.swift` menyediakan raycast geometry berbasis occluder.
- `Services/DateIntervalSampler.swift` membuat segment waktu untuk interval kalkulasi.
- `Data/ParkGeometryCatalog.swift` menyimpan data geometry runtime seperti lokasi taman, bench spots, dan tree occluders. Export CSV sudah dihapus karena tidak dipakai lagi di app.
- `Models/ShadowIntervalResult.swift` menjadi output utama deterministic.

## Alur data
Input waktu dan lokasi masuk ke `ShadowIntervalRequest`, lalu diproses oleh `ShadeRecommendationEngine` dan `ShadowIntervalCalculator`. Calculator memakai `SunPositionProviding`, `SunVectorConverter`, dan `ShadowRaycastProviding` untuk menghasilkan timeline dan ringkasan shadow result.

## Parameter penting
Konfigurasi utama yang dipakai oleh kalkulasi shade saat ini:
- `shadeCoverageThreshold = 0.70`, artinya spot dianggap teduh saat coverage occlusion minimal 70%.
- `benchSampleRadius = 0.50`, artinya sampling dilakukan di sekitar radius bench 0.5 meter.
- Koordinat scene memakai konvensi X = East, Y = Up, Z = North.
