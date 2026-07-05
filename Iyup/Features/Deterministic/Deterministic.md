# Deterministic Feature

## Tujuan
Menghitung status teduh atau terkena matahari untuk setiap spot berdasarkan interval waktu, posisi matahari, dan raycast/occluder geometry.

## File utama
- `Views/DeterministicShadowView.swift` menampilkan hasil shadow deterministic.
- `Services/ShadowIntervalCalculator.swift` menghitung timeline bayangan per sample waktu.
- `Services/ShadeRecommendationEngine.swift` menjalankan kalkulasi untuk semua spot.
- `Services/GeometryShadowRaycastService.swift` menyediakan raycast geometry demo berbasis sphere occluder.
- `Models/ShadowIntervalResult.swift` menjadi output utama deterministic.

## Alur data
Input waktu dan lokasi masuk ke `ShadowIntervalRequest`, lalu diproses oleh `ShadeRecommendationEngine` dan `ShadowIntervalCalculator`. Calculator memakai `SunPositionProviding`, `SunVectorConverter`, dan `ShadowRaycastProviding` untuk menghasilkan timeline dan ringkasan shadow result.
