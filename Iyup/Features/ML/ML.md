# ML Feature

## Tujuan
Melakukan forecast environment untuk tiap spot, terutama lux, suhu, dan occupancy, menggunakan Core ML model dan manifest JSON feature order.

## File utama
- `Services/MLShadeCoreMLForecastService.swift` load manifest JSON dan `.mlmodel`, membangun feature input, lalu menjalankan prediksi Core ML.
- `Services/MLShadeMockEnvironmentForecastService.swift` menyediakan fallback dummy forecast saat Core ML gagal diload.
- `Models/MLShadeEnvironmentForecastPoint.swift` menjadi output per sample waktu.
- `Resources/Models` menyimpan model Core ML.
- `Resources/Json` menyimpan manifest feature order.

## Alur data
ML menerima `ShadowIntervalResult`, mengambil timeline shadow, membuat feature dictionary sesuai JSON, menjalankan model short/long horizon, lalu mengembalikan list `MLShadeEnvironmentForecastPoint`.

## Debug logging
Service Core ML dan mock forecast punya flag debug internal yang default-nya mati. Flag ini hanya dinyalakan saat perlu investigasi output model, karena logging prediksi bisa sangat banyak dan dapat membuat layar yang memuat Park Detail terasa lag.
