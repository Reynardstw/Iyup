# Score Feature

## Tujuan
Menjadi titik orkestrasi dan ranking akhir. Feature ini menggabungkan hasil deterministic shadow dengan hasil ML forecast untuk menghasilkan score rekomendasi spot.

## File utama
- `ViewModels/MLShadeRecommendationViewModel.swift` mengelola state, loading, error, shadow results, dan scored results.
- `Views/MLShadeRankingView.swift` menampilkan ranking final.
- `Views/Components/ShadeIntervalSection.swift` dipakai sebagai kontrol interval hitung.
- `Services/MLShadeEnvironmentScoringEngine.swift` menggabungkan shadow result dan ML forecast.
- `Services/MLShadeScoringService.swift` menghitung komponen score.
- `Models/MLShadeScoredSpotResult.swift` menjadi output ranking akhir.

## Alur data
ViewModel memanggil deterministic engine, menerima `ShadowIntervalResult`, meneruskannya ke scoring engine, scoring engine memanggil ML forecast provider, lalu score result diurutkan untuk ditampilkan di ranking view.
