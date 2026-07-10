# Score Feature

## Tujuan
Menjadi titik orkestrasi dan ranking akhir. Feature ini menggabungkan hasil deterministic shadow dengan hasil ML forecast untuk menghasilkan score rekomendasi spot.

## Status UI
Standalone/debug ranking view dari tab lama sudah dihapus. Core scoring tetap dipakai oleh ShadeMap untuk glow/rekomendasi dan oleh flow lain yang membutuhkan ranking spot.

## File utama
- `ViewModels/MLShadeRecommendationViewModel.swift` mengelola state, loading, error, shadow results, dan scored results.
- `Services/MLShadeEnvironmentScoringEngine.swift` menggabungkan shadow result dan ML forecast.
- `Services/MLShadeScoringService.swift` menghitung komponen score.
- `Models/MLShadeScoredSpotResult.swift` menjadi output ranking akhir.

## Alur data
ViewModel memanggil deterministic engine, menerima `ShadowIntervalResult`, meneruskannya ke scoring engine, scoring engine memanggil ML forecast provider, lalu score result diurutkan untuk dipakai oleh UI utama.

## Debug logging
Scoring engine memiliki flag debug internal yang default-nya mati. Flag ini hanya untuk investigasi skor dan sebaiknya tidak dinyalakan saat UI utama dipakai, karena recalculation bisa menghasilkan banyak log.
