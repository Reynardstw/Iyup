# Weather Feature

## Tujuan
Mengambil kondisi cuaca terkini dari WeatherKit dan menampilkan seluruh field yang tersedia dari dataset currentWeather, untuk melihat informasi apa saja yang bisa didapat. Feature ini sengaja hanya mengambil data saat tombol ditekan, bukan otomatis saat view muncul, agar hemat kuota WeatherKit. Hanya dataset currentWeather yang diminta; dataset lain seperti hourly dan daily tidak diambil.

## Field yang ditampilkan
Dari currentWeather: waktu pembaruan, kondisi, siang/malam, suhu, suhu terasa, titik embun, kelembapan, tutupan awan, indeks UV beserta kategorinya, tekanan beserta trennya, jarak pandang, intensitas curah hujan, kecepatan angin, hembusan angin, serta arah angin dalam derajat dan mata angin. Semua field ini datang dalam satu request yang sama, jadi menampilkan banyak field tidak menambah beban kuota.

## File utama
- `Models/WeatherSnapshot.swift` adalah nilai hasil ringkas yang siap ditampilkan: suhu, kondisi, nama simbol SF, kelembapan, dan kecepatan angin.
- `Services/WeatherProviding.swift` adalah protokol abstraksi sumber cuaca, supaya bisa di-inject dan di-mock.
- `Services/WeatherKitWeatherService.swift` implementasi nyata memakai `WeatherService.shared`, memanggil `weather(for:)`, lalu memetakan `currentWeather` ke `WeatherSnapshot` dengan konversi ke Celsius dan km/jam.
- `Services/PreviewWeatherService.swift` implementasi tiruan berdata tetap untuk `#Preview` dan testing tanpa memakai kuota.
- `ViewModels/WeatherViewModel.swift` memegang state (snapshot, loading, error) dan menyediakan teks terformat untuk suhu, kelembapan, dan angin.
- `Views/WeatherView.swift` menampilkan simbol cuaca, suhu, kondisi, detail, serta tombol untuk memicu pengambilan data.

## Alur data
Pengambilan hanya terjadi ketika user menekan tombol "Ambil Data Cuaca". Tombol memanggil `viewModel.fetch()`, ViewModel memanggil `weatherService.fetchCurrentWeather(latitude:longitude:)`, hasilnya disimpan sebagai `WeatherSnapshot`, dan View menggambar ulang lewat `@Observable`. Tidak ada `.task` yang otomatis memuat data saat view muncul, sehingga tidak ada request yang terbuang.

## Kenapa fetch-on-demand
WeatherKit memberi kuota 500.000 request per bulan per membership. Memuat otomatis di setiap kemunculan view bisa menghabiskan kuota tanpa disadari. Dengan hanya memuat saat tombol ditekan, jumlah request terkendali dan mudah diprediksi.

## Setup yang dibutuhkan
1. Aktifkan WeatherKit di Apple Developer Portal pada App ID Iyup, di tab Capabilities dan App Services. Tunggu sekitar 30 menit untuk propagasi.
2. Di Xcode, tambahkan capability WeatherKit pada target Iyup lewat Signing & Capabilities.
3. Tidak perlu private key atau Services ID; itu hanya untuk REST API di platform non-Apple.

## Atribusi
Apple mewajibkan menampilkan atribusi "Weather" beserta tautan legal ke sumber data saat menampilkan data cuaca. View saat ini menampilkan teks ringkas "Data: Apple Weather" sebagai penanda. Sebelum rilis, lengkapi atribusi resmi dengan mengambil `WeatherAttribution` dari `WeatherService.shared.attribution` (berisi logo dan URL legal) dan tampilkan sesuai pedoman Apple.

## Catatan
- Koordinat default saat ini di-hardcode ke area Jakarta (-6.2000, 106.8167) pada convenience init di `WeatherView`. Nanti saat feature dipakai, lewatkan koordinat nyata, misalnya lokasi user dari feature Location atau posisi sebuah `ParkSpot`, ke `WeatherViewModel`.
- Semua file di target sudah dipastikan masuk Target Membership Iyup agar bisa dikompilasi.

## Integrasi ke ContentView
`ContentView` menambahkan `Tab` baru berjudul "Cuaca" yang memanggil `WeatherView()`. Convenience init tanpa argumen merakit sendiri service WeatherKit dan koordinat default, sehingga `ContentView` tidak perlu mengurus dependensinya.
