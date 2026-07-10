# Weather Feature

## Tujuan
Menyediakan akses cuaca native melalui WeatherKit untuk fitur utama seperti ParkDetail dan kebutuhan forecast lain di masa depan.

## Status UI
Standalone/demo `WeatherView` dari tab lama sudah dihapus. ViewModel dan service cuaca tetap disimpan supaya logic fetch masih bisa dipakai lagi nanti.

## File utama
- `Models/WeatherSnapshot.swift` adalah nilai hasil ringkas: suhu, kondisi, nama simbol SF, kelembapan, dan kecepatan angin.
- `Models/HourlyWeatherPoint.swift` adalah data forecast per jam yang dipakai ParkDetail.
- `Services/WeatherProviding.swift` adalah protokol abstraksi sumber cuaca, supaya bisa di-inject dan di-mock.
- `Services/WeatherKitWeatherService.swift` implementasi nyata memakai `WeatherService.shared`.
- `Services/PreviewWeatherService.swift` implementasi tiruan berdata tetap untuk preview/testing tanpa memakai kuota.
- `ViewModels/WeatherViewModel.swift` disimpan sebagai wrapper state fetch-on-demand bila standalone weather UI dipakai lagi.

## Alur data
Feature lain memanggil `WeatherProviding` untuk mengambil current weather atau hourly forecast. Implementasi nyata memetakan WeatherKit menjadi model internal Iyup agar UI utama tidak bergantung langsung ke detail framework.

## Kenapa fetch-on-demand tetap disarankan
WeatherKit memiliki kuota request. Untuk UI masa depan, hindari fetch otomatis yang berulang setiap view muncul. Trigger lewat event yang jelas atau cache hasil fetch jika datanya masih relevan.

## Setup yang dibutuhkan
1. Aktifkan WeatherKit di Apple Developer Portal pada App ID Iyup.
2. Tambahkan capability WeatherKit pada target Iyup lewat Signing & Capabilities.
3. Tidak perlu private key atau Services ID untuk penggunaan native WeatherKit di iOS app.

## Atribusi
Saat menampilkan data cuaca di UI rilis, tampilkan atribusi Apple Weather sesuai pedoman WeatherKit.
