# Park Detail Feature

## Tujuan
Park Detail menampilkan detail taman dalam sheet bertingkat dan menyediakan pintu masuk ke Plan Trip.

## Struktur
```text
Features/ParkDetail/
├─ Models/
├─ Services/
├─ ViewModels/
└─ Views/
```

## Perilaku sheet
Sheet memiliki tiga detent:
- peek untuk ringkasan taman dan tombol Plan Trip;
- medium untuk konten utama awal;
- large untuk konten penuh dan scroll.

`presentationBackgroundInteraction` digunakan supaya area peta di belakang masih bisa disentuh pada detent rendah. Scroll konten diaktifkan hanya saat detent large.

## Plan Trip
Plan Trip dibuka dari alur ShadeMap dan Trips. Dependency Plan Trip dibuat melalui `AppComposition.makePlanTripViewModel()`, sedangkan 3D preview standalone hanya dibuat saat view edit/plan benar-benar tampil.

## Data
Data taman berasal dari `ParkDetailViewModel`. Sumber seperti WeatherKit, Location, deterministic shade, dan ML forecast disambungkan melalui dependency dari `AppComposition`.
