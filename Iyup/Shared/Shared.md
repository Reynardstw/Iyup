# Shared Layer

## Tujuan
Shared menyimpan model, protocol, dan service lintas fitur.

## Struktur
```text
Shared/
├─ Location/
├─ Protocols/
├─ SharedModels/
└─ Sun/
   ├─ Models/
   └─ Services/
```

## Isi utama
- `Location/ParkLocation.swift` menyimpan koordinat dan timezone taman.
- `SharedModels/ParkSpot.swift` merepresentasikan spot taman yang dipakai Deterministic, ML, Score, Trips, dan ShadeMap.
- `SharedModels/ShadeSpot.swift` merepresentasikan marker shade spot di scene.
- `Sun/Models/SunPosition.swift` menyimpan altitude dan azimuth matahari.
- `Sun/Services/OfficialSunKitSunPositionService.swift` menjadi adapter ke SunKit.
- `Sun/Services/SunVectorConverter.swift` mengubah posisi matahari menjadi vektor 3D.
- `Protocols` berisi kontrak lintas fitur seperti raycast, sun position, dan ML forecast provider.

## Aturan dependency
Shared tidak boleh import feature. Feature boleh memakai Shared.
