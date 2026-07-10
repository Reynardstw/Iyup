# Trips Feature

## Tujuan
Fitur Trips menyimpan rencana kunjungan user dari Plan Trip, menampilkan daftar trip, membuka detail trip, dan mengizinkan user mengedit trip yang sudah tersimpan.

## Struktur
```text
Features/Trips/
├─ Models/
│  └─ Trip.swift
├─ Services/
│  ├─ TripNotificationScheduler.swift
│  └─ TripStore.swift
├─ ViewModels/
│  └─ PlanTripViewModel.swift
└─ Views/
   ├─ TripsView.swift
   ├─ EditTripView.swift
   ├─ PlanTripView.swift
   └─ Components/
      ├─ TripHeaderBar.swift
      └─ StandalonePark3DPreview.swift
```

## Model penyimpanan
`Trip` memakai `UUID` sebagai ID utama. ID ini dipakai oleh `TripStore.update(_:)` agar edit trip tidak membuat data baru.

Field penting:
- `parkName`, `city`, `address`, `latitude`, `longitude` untuk identitas taman.
- `date` menyimpan tanggal dan jam rencana kunjungan.
- `recommendedShadeWindow` menyimpan rekomendasi jam teduh.
- `alertOption` menyimpan pilihan notifikasi.
- `shadeConditionText` menyimpan ringkasan kondisi teduh pada waktu yang dipilih.
- `savedAt` menyimpan waktu pertama kali trip dibuat.

## TripStore
`TripStore` menyimpan data memakai `UserDefaults` dalam bentuk JSON. Karena class ini memakai Observation, `TripsView` akan ikut refresh saat array `trips` berubah.

Operasi utama:
- `add(_:)` menambah trip baru di posisi paling atas.
- `update(_:)` mengganti trip berdasarkan `trip.id`, lalu menjadwalkan ulang notifikasi.
- `delete(at:)` menghapus trip dan membatalkan notifikasi terkait.

## PlanTripView
`PlanTripView` mendukung dua mode:
- Create mode: `editingTrip == nil`, tombol Save akan membuat `UUID` baru dan memanggil `TripStore.add(_:)`.
- Edit mode: `editingTrip != nil`, tombol Save memakai `id` lama dan memanggil `TripStore.update(_:)`.

`mapTopSpacing` menentukan sumber preview map:
- Jika `mapTopSpacing > 0`, halaman sedang dibuka dari `ShadeMapView`; slot map dibuat transparan supaya live RealityKit map dari belakang tetap terlihat.
- Jika `mapTopSpacing == 0`, halaman sedang dibuka dari flow standalone seperti `Trip Details → Edit`; halaman membuat preview 3D sendiri melalui `StandalonePark3DPreview`.

Initializer kompatibilitas lama tetap disediakan agar call site lama yang mengirim `scene` dan `scoreViewModel` masih bisa compile. Dependency tersebut tidak dipakai langsung oleh halaman ini agar tidak membuat RealityView kedua pada flow utama ShadeMap.

## EditTripView
`EditTripView` bertindak sebagai detail page. Tombol `Edit` membuka `PlanTripView` dalam edit mode. Setelah Save, state lokal seperti `selectedDate`, `alertOption`, dan `shadeConditionText` diperbarui supaya detail page langsung menampilkan data terbaru.

## StandalonePark3DPreview
Komponen ini dipakai hanya saat `PlanTripView` dibuka tanpa `ShadeMapView` di belakangnya. Preview ini:
- memakai RealityKit secara native;
- memuat scene taman ringan;
- memakai arah kamera yang disesuaikan dengan mode Plan Trip;
- menampilkan shade spot pin dan glow berdasarkan `PlanTripViewModel.shadedSpotIDs`;
- mematikan interaksi user karena fungsinya hanya preview;
- menghentikan glow loop dan menyembunyikan pin saat view keluar dari layar.

## TripHeaderBar
Header custom native SwiftUI untuk flow Plan Trip dan Trip Details. Layout menggunakan `ZStack` agar judul tetap berada di tengah header, sementara tombol back tetap kiri dan tombol aksi tetap kanan. Ini mencegah judul seperti `Plan Your Trip` berubah menjadi ellipsis karena pembagian tiga kolom `HStack`.
