# Core Layer

## Tujuan
Menyimpan model, protocol, dan service yang dipakai lintas feature.

## Isi utama
- `Location/ParkLocation.swift` untuk koordinat dan timezone taman.
- `SharedModels/ParkSpot.swift` untuk representasi spot taman yang dipakai Deterministic, ML, dan Score.
- `Sun/Models/SunPosition.swift` untuk altitude dan azimuth matahari.
- `Sun/Services/OfficialSunKitSunPositionService.swift` sebagai adapter ke SunKit.
- `Sun/SunVectorConverter.swift` untuk konversi posisi matahari ke vektor 3D.
- `Protocols` berisi kontrak lintas fitur supaya dependency tidak bolak-balik.

## Aturan dependency
Core tidak boleh bergantung ke feature. Feature boleh memakai Core.
