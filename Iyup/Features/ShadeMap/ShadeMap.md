# ShadeMap Feature

## Tujuan
Menampilkan taman 3D dari file `checkpoint_final_4.usda`, mengatur cahaya matahari berdasarkan SunKit, dan menyediakan fondasi untuk visualisasi bayangan di RealityKit.

## File utama
- `Views/ShadeMapView.swift` menampilkan tab visualisasi 3D, slider jam, dan overlay informasi altitude/azimuth.
- `Scene/ParkScene.swift` membangun scene RealityKit, load USDA map, normalisasi skala map, dan mengarahkan `DirectionalLight` berdasarkan posisi matahari.

## Alur data
`ShadeMapView` membaca nilai jam dari slider, memanggil `ParkScene.setSun(hour:location:)`, lalu `ParkScene` menghitung `SunPosition` melalui `OfficialSunKitSunPositionService` dan mengubahnya menjadi vektor cahaya melalui `SunVectorConverter`.

## Catatan implementasi
Pohon buatan dari versi demo sudah dihapus. Objek pohon atau obstacle sekarang diharapkan berasal dari file map final.
