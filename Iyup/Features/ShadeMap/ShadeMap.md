# ShadeMap Feature

## Tujuan
ShadeMap menampilkan taman 3D, mengatur cahaya matahari berdasarkan waktu, menampilkan shade spot, dan membuka flow detail atau Plan Trip.

## Struktur
```text
Features/ShadeMap/
├─ Models/
│  └─ ParkModel.swift
├─ Services/
│  └─ RealityKit/
│     └─ ParkScene.swift
├─ ViewModels/
│  └─ ShadeMapViewModel.swift
└─ Views/
   ├─ ShadeMapView.swift
   └─ Components/
      ├─ ShadeCard.swift
      ├─ TimeSliderPanel.swift
      └─ TwoFingerPan.swift
```

## Asset RealityKit
Scene utama memuat:
- `Resources/RealityKit/park.usdz`
- `Resources/RealityKit/map_pin_location_pin.usdz`

Nama asset di dokumentasi lama yang masih menyebut `checkpoint_final_4.usda` sudah tidak dipakai sebagai sumber utama.

## Alur data
`ShadeMapView` membaca state dari `ShadeMapViewModel`. Saat jam atau tanggal berubah, ViewModel menyinkronkan tanggal, kalkulasi shade, scoring, dan kamera.

`ParkScene` menangani detail RealityKit:
- build scene 3D;
- set posisi matahari;
- mengatur kamera;
- menampilkan dan menyembunyikan shade spots;
- update glow spot yang aman/teduh;
- menjalankan glow loop saat scene aktif.

## Gesture
Gesture cepat seperti rotasi/pan tetap berada dekat dengan View karena update visual perlu responsif. `TwoFingerPan` menjadi bridge UIKit untuk two-finger pan agar gesture tidak memblokir tap di RealityView.

## Mode tampilan
ShadeMap memiliki beberapa mode:
- mode default carousel taman;
- mode detail saat user membuka View Details;
- mode Plan Trip ketika halaman Plan Trip muncul di atas peta.

Saat masuk View Details, parent diberi sinyal agar tab bar bisa disembunyikan. Saat Plan Trip dibuka dari ShadeMap, map 3D tetap berasal dari ShadeMapView dan PlanTripView hanya menyediakan slot transparan.
