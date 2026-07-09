# Park Detail Feature (Action Sheet)

## Tujuan
Action sheet detail taman yang muncul di atas peta, dengan tiga tahap tinggi (detent). Dibuat sebagai view berdiri sendiri lebih dulu agar tidak bentrok dengan ShadeMapView yang sedang dikerjakan paralel. Data masih dummy; penyambungan ke fitur lain dilakukan belakangan.

## File
- `Models/ParkDetailInfo.swift` — struct data + satu contoh `sample` (dummy). Semua isi sheet mengalir dari sini, jadi mudah diganti atau ditambah taman lain.
- `Views/ParkDetailSheetView.swift` — layar utama: latar peta placeholder + sheet tiga detent. Bukan RealityView asli; placeholder ini nanti diganti peta 3D saat digabung.
- `Views/ParkDetailSheetContent.swift` — isi sheet: header, tombol Plan Trip, dan kartu-kartu (info, cuaca, outfit, popular times, alamat).
- `Views/PlanTripView.swift` — placeholder tujuan tombol Plan Trip.

## Perilaku tiga detent
Sheet punya tiga tinggi: peek (`.height(180)`), medium (`.fraction(0.5)`), dan large (`.large`).
- Peek: hanya header taman + tombol Plan Trip terlihat. Peta di belakang bisa digerakkan.
- Medium: menampilkan info, cuaca, dan awal konten (seperti gambar 1). Peta masih bisa digerakkan. Konten belum bisa di-scroll.
- Large: seluruh konten (seperti gambar 2) dan baru di sini konten bisa di-scroll.

Kunci teknisnya:
- `presentationDetents([...], selection: $detent)` melacak detent aktif.
- `presentationBackgroundInteraction(.enabled(upThrough: midDetent))` membuat peta di belakang tetap bisa disentuh saat peek dan medium; nonaktif saat large.
- `scrollDisabled(detent != largeDetent)` mematikan scroll kecuali di large, sehingga di peek dan medium konten tidak ikut ter-scroll.
- `interactiveDismissDisabled()` membuat sheet tidak bisa ditutup dengan swipe ke bawah; tombol X hanya menciutkan kembali ke peek.

## Sumber data (nanti, saat disambungkan)
Rancangan sumber yang sudah disepakati, untuk menggantikan dummy:
- Nama, kota, entrance, hours, alamat, "Open 24 Hours": statis di `ParkDetailInfo`.
- Distance: dari fitur Location (jarak user ke taman).
- Temperature dan Humidity: dari WeatherKit hourly 06:00–18:00, nilainya mengikuti posisi slider jam.
- Outfit: dipetakan dari tabel empat musim berdasarkan suhu dan kondisi cuaca; ditampilkan sebagai emoji.
- Popular Times: dari model ML occupancy. Semua nama hari ditampilkan, tapi hanya hari ini yang punya bar. Rentang 06:00–18:00.
- Recommended shade window: skor gabungan teduh (SunKit) + sepi (occupancy ML) + suhu tidak panas (WeatherKit), diambil satu blok dua jam terbaik.
- Crowd label: dari occupancy jam sekarang, dipetakan ke Not busy / Moderate / Busy / Full.
- Plan Trip: sementara membuka `PlanTripView` placeholder.

## Catatan integrasi
Karena view ini berdiri sendiri, saat digabung ke ShadeMapView cukup: ganti `mapPlaceholder` dengan RealityView taman, dan ganti `ParkDetailInfo.sample` dengan data nyata dari service terkait. Struktur sheet dan perilaku detent tidak perlu diubah.

## Persyaratan
Membutuhkan iOS 16.4+ untuk `presentationBackgroundInteraction`. Proyek sudah menargetkan iOS 17+, jadi aman.
