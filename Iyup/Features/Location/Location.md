# Location Feature

## Tujuan
Mengambil lokasi user dan menghitung jarak dari lokasi user ke tempat tujuan, terutama untuk ParkDetail.

## Status UI
Standalone/demo `LocationDistanceView` dari tab lama sudah dihapus. ViewModel dan service location tetap dipakai oleh ParkDetail.

## File utama
- `Models/NearbyPlace.swift` merepresentasikan tempat tujuan.
- `Models/LocationDistanceError.swift` mendefinisikan error pengambilan lokasi.
- `Services/UserLocationProviding.swift` adalah protokol abstraksi sumber lokasi user.
- `Services/CoreLocationUserLocationService.swift` implementasi nyata memakai `CLLocationManager`.
- `Services/PreviewUserLocationService.swift` implementasi tiruan untuk preview/testing.
- `ViewModels/LocationDistanceViewModel.swift` memegang state lokasi user, jarak, loading, error, dan format teks jarak.

## Alur data
ParkDetail memakai `LocationDistanceViewModel.locate()` untuk meminta lokasi user, menghitung jarak garis lurus ke taman, lalu menampilkan hasilnya di detail taman.

## Cara jarak dihitung
Jarak yang dipakai adalah jarak garis lurus melalui `CLLocation.distance(from:)`, dihitung offline di device. Ini bukan jarak rute jalan. Bila suatu saat butuh rute sebenarnya, gunakan `MKDirections` dari MapKit dengan pertimbangan koneksi internet dan frekuensi request.

## Setup yang dibutuhkan
`Info.plist` wajib memuat `NSLocationWhenInUseUsageDescription`. MapKit dan Core Location tidak butuh capability tambahan di Apple Developer Portal.
