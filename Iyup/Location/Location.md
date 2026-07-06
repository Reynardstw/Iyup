# Location Feature

## Tujuan
Menghitung dan menampilkan jarak dari lokasi user saat ini ke sebuah tempat tujuan (default: Taman Bendera Pusaka), lengkap dengan peta sederhana yang menandai posisi user dan tujuan. Feature ini berdiri sendiri sebagai satu tab di `ContentView`.

## File utama
- `Models/NearbyPlace.swift` merepresentasikan tempat tujuan (nama + koordinat). Menyediakan `NearbyPlace.tamanBenderaPusaka` sebagai tujuan default.
- `Models/LocationDistanceError.swift` mendefinisikan error yang mungkin muncul saat mengambil lokasi (izin ditolak, lokasi tidak tersedia, permintaan diganti).
- `Services/UserLocationProviding.swift` adalah protokol abstraksi sumber lokasi user, supaya bisa di-inject dan di-mock.
- `Services/CoreLocationUserLocationService.swift` implementasi nyata memakai `CLLocationManager`. Meminta izin "When In Use", lalu mengambil satu kali lokasi lewat `requestLocation()` yang dibungkus `CheckedContinuation` agar jadi async/await.
- `Services/PreviewUserLocationService.swift` implementasi tiruan berkoordinat tetap, dipakai untuk `#Preview` dan testing tanpa GPS.
- `ViewModels/LocationDistanceViewModel.swift` memegang state (koordinat user, jarak, loading, error), memanggil service, lalu menghitung jarak dan memformatnya jadi teks.
- `Views/LocationDistanceView.swift` menampilkan peta dengan dua marker dan panel ringkasan berisi nama tujuan, angka jarak, pesan error, serta tombol perbarui.

## Alur data
View memanggil `viewModel.locate()` saat muncul (`.task`) dan saat tombol ditekan. ViewModel memanggil `locationService.requestCurrentLocation()`, menerima `CLLocationCoordinate2D`, menghitung jarak garis lurus ke koordinat tujuan, lalu memperbarui state. View mengamati state lewat `@Observable` dan otomatis menggambar ulang marker user dan teks jarak.

## Cara jarak dihitung
Jarak yang dipakai adalah jarak garis lurus (great-circle) melalui `CLLocation.distance(from:)`, dihitung offline di device tanpa koneksi. Ini bukan jarak rute jalan dan tidak menggambar garis apa pun di peta, sesuai kebutuhan. Bila suatu saat butuh jarak rute sebenarnya (mengikuti jalan) beserta estimasi waktu tempuh, gantilah perhitungan di ViewModel dengan `MKDirections` dari MapKit; API itu native, tanpa key, namun memanggil server Apple sehingga butuh internet dan sebaiknya tidak dipanggil beruntun untuk banyak titik sekaligus.

## Setup yang dibutuhkan
1. Info.plist wajib memuat kunci `NSLocationWhenInUseUsageDescription` berisi alasan yang jujur, misalnya: "Iyup memakai lokasimu untuk menampilkan spot teduh terdekat dan menghitung jaraknya." Tanpa kunci ini app akan crash saat pertama kali meminta lokasi.
2. MapKit dan Core Location tidak butuh capability apa pun di Apple Developer Portal; cukup `import MapKit` dan `import CoreLocation`.

## Catatan
- Koordinat `NearbyPlace.tamanBenderaPusaka` saat ini adalah placeholder di area Jakarta. Ganti `latitude` dan `longitude` di `Models/NearbyPlace.swift` dengan koordinat asli tempat tujuan.
- Untuk menambah tujuan lain, buat instance `NearbyPlace` baru dan lewatkan ke `LocationDistanceViewModel`, atau ubah tujuan default yang dipakai pada convenience init di `LocationDistanceView`.
- Semua file di target sudah dipastikan masuk Target Membership Iyup agar bisa dikompilasi.

## Integrasi ke ContentView
`ContentView` menambahkan satu `Tab` baru berjudul "Lokasi" yang memanggil `LocationDistanceView()`. Convenience init tanpa argumen pada view merakit sendiri service nyata dan tujuan default, sehingga `ContentView` tidak perlu mengurus dependensinya.
