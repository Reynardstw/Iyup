//import Foundation
//
//// MARK: - Hasil perhitungan posisi matahari
//
///// Posisi matahari untuk satu titik koordinat dan satu waktu.
//struct SunPosition {
//    /// Sudut elevasi (altitude) di atas horizon, dalam derajat.
//    /// 0° = horizon, 90° = tepat di atas kepala. Negatif berarti matahari
//    /// di bawah horizon (malam) sehingga tidak ada bayangan matahari.
//    let altitude: Double
//
//    /// Azimuth: arah kompas datangnya cahaya, diukur searah jarum jam dari Utara.
//    /// 0° = Utara, 90° = Timur, 180° = Selatan, 270° = Barat.
//    let azimuth: Double
//
//    /// Arah jatuhnya bayangan (kebalikan dari arah matahari), derajat dari Utara.
//    var shadowAzimuth: Double {
//        (azimuth + 180).truncatingRemainder(dividingBy: 360)
//    }
//
//    /// Panjang bayangan untuk objek setinggi `height` (meter).
//    /// Mengembalikan nil bila matahari di bawah horizon.
//    func shadowLength(forHeight height: Double) -> Double? {
//        guard altitude > 0 else { return nil }
//        return height / tan(altitude * .pi / 180)
//    }
//}
//
//// MARK: - Kalkulator (algoritma NOAA Solar Calculator)
//
//enum SolarCalculator {
//
//    /// Hitung posisi matahari berdasarkan algoritma NOAA Solar Calculator
//    /// (berbasis Astronomical Algorithms, Jean Meeus). Akurasi ~0.1°,
//    /// lebih dari cukup untuk pemetaan bayangan kota dan terain.
//    ///
//    /// - Parameters:
//    ///   - date: waktu kejadian (dibaca dalam UTC; konversi zona waktu ditangani di sini).
//    ///   - latitude: lintang dalam derajat, Utara positif.
//    ///   - longitude: bujur dalam derajat, Timur positif.
//    static func position(date: Date, latitude: Double, longitude: Double) -> SunPosition {
//        let rad = Double.pi / 180, deg = 180 / Double.pi
//
//        // --- Julian Day (berbasis komponen waktu UTC) ---
//        var cal = Calendar(identifier: .gregorian)
//        cal.timeZone = TimeZone(identifier: "UTC")!
//        let c = cal.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
//        var year = Double(c.year!), month = Double(c.month!)
//        let dayFrac = Double(c.day!)
//            + (Double(c.hour!) + (Double(c.minute!) + Double(c.second!) / 60) / 60) / 24
//        if month <= 2 { year -= 1; month += 12 }
//        let a = floor(year / 100), b = 2 - a + floor(a / 4)
//        let jd = floor(365.25 * (year + 4716)) + floor(30.6001 * (month + 1)) + dayFrac + b - 1524.5
//
//        // --- Geometri orbit matahari ---
//        let t = (jd - 2451545.0) / 36525.0                                  // Julian century
//        let l0 = (280.46646 + t * (36000.76983 + t * 0.0003032))            // bujur rata-rata
//            .truncatingRemainder(dividingBy: 360)
//        let mAnom = 357.52911 + t * (35999.05029 - 0.0001537 * t)           // anomali rata-rata
//        let ecc = 0.016708634 - t * (0.000042037 + 0.0000001267 * t)        // eksentrisitas
//        let center = sin(mAnom * rad) * (1.914602 - t * (0.004817 + 0.000014 * t))
//            + sin(2 * mAnom * rad) * (0.019993 - 0.000101 * t)
//            + sin(3 * mAnom * rad) * 0.000289
//        let trueLong = l0 + center
//        let appLong = trueLong - 0.00569 - 0.00478 * sin((125.04 - 1934.136 * t) * rad)
//        let obliq0 = 23 + (26 + (21.448 - t * (46.815 + t * (0.00059 - t * 0.001813))) / 60) / 60
//        let obliq = obliq0 + 0.00256 * cos((125.04 - 1934.136 * t) * rad)
//        let decl = asin(sin(obliq * rad) * sin(appLong * rad)) * deg         // deklinasi
//
//        // --- Equation of time (menit) ---
//        let y = pow(tan(obliq / 2 * rad), 2)
//        let eot = 4 * deg * (y * sin(2 * l0 * rad)
//            - 2 * ecc * sin(mAnom * rad)
//            + 4 * ecc * y * sin(mAnom * rad) * cos(2 * l0 * rad)
//            - 0.5 * y * y * sin(4 * l0 * rad)
//            - 1.25 * ecc * ecc * sin(2 * mAnom * rad))
//
//        // --- Hour angle ---
//        let utcMinutes = Double(c.hour!) * 60 + Double(c.minute!) + Double(c.second!) / 60
//        var tst = (utcMinutes + eot + 4 * longitude).truncatingRemainder(dividingBy: 1440)
//        if tst < 0 { tst += 1440 }
//        let ha = tst / 4 < 0 ? tst / 4 + 180 : tst / 4 - 180
//
//        // --- Elevasi & azimuth ---
//        let latR = latitude * rad, declR = decl * rad, haR = ha * rad
//        let cosZen = min(1, max(-1, sin(latR) * sin(declR)
//            + cos(latR) * cos(declR) * cos(haR)))
//        let zenith = acos(cosZen)
//        let elevation = 90 - zenith * deg
//
//        let azDenom = cos(latR) * sin(zenith)
//        let azimuth: Double
//        if abs(azDenom) > 1e-9 {
//            let azArg = min(1, max(-1, (sin(latR) * cos(zenith) - sin(declR)) / azDenom))
//            let az = acos(azArg) * deg
//            azimuth = ha > 0
//                ? (az + 180).truncatingRemainder(dividingBy: 360)
//                : (540 - az).truncatingRemainder(dividingBy: 360)
//        } else {
//            azimuth = latitude > 0 ? 180 : 0
//        }
//
//        // --- Koreksi pembiasan atmosfer (matahari tampak sedikit lebih tinggi) ---
//        let refraction = atmosphericRefraction(elevation: elevation)
//        return SunPosition(altitude: elevation + refraction, azimuth: azimuth)
//    }
//
//    /// Pembiasan atmosfer dalam derajat (pendekatan NOAA).
//    private static func atmosphericRefraction(elevation e: Double) -> Double {
//        if e > 85 { return 0 }
//        let er = e * .pi / 180
//        let arcSeconds: Double
//        if e > 5 {
//            arcSeconds = 58.1 / tan(er) - 0.07 / pow(tan(er), 3) + 0.000086 / pow(tan(er), 5)
//        } else if e > -0.575 {
//            arcSeconds = 1735 + e * (-518.2 + e * (103.4 + e * (-12.79 + e * 0.711)))
//        } else {
//            arcSeconds = -20.772 / tan(er)
//        }
//        return arcSeconds / 3600
//    }
//}
//
//// MARK: - Contoh pemakaian
////
//// let pos = SolarCalculator.position(date: Date(),
////                                    latitude: -6.2088,   // Jakarta
////                                    longitude: 106.8456)
//// print(pos.altitude, pos.azimuth)              // mis. 60.2  354.2
//// let bayangan = pos.shadowLength(forHeight: 50) // panjang bayangan gedung 50 m
