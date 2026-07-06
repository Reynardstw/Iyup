# Analytics Feature

## Tujuan

Fitur Analytics menjadi tempat terakhir untuk semua grafik, supaya `WeatherView` dan `IoTDashboardView` tetap fokus sebagai layar data mentah / data terakhir.

## Data yang ditampilkan

### Weather

Analytics mengambil data WeatherKit hanya saat tombol `Fetch Weather 7 Hari Jam 12` ditekan.

Target data:

- 7 hari terakhir
- 1 titik per hari
- jam 12:00 Asia/Jakarta

Chart weather:

- Suhu jam 12
- Kelembapan jam 12
- Tutupan awan jam 12
- Curah hujan jam 12

### IoT

Analytics dapat subscribe MQTT sendiri melalui tombol `Connect IoT`.

Topic:

```text
sensor/data
```

Payload ESP32 yang diterima:

```json
{"Orang":4,"Suhu":30.2,"Kelembapan":65.1,"Cahaya":1800}
```

Chart IoT:

- Suhu ESP32
- Jumlah orang
- Kelembapan ESP32
- Cahaya LDR dalam lux

## Catatan implementasi

- Analytics tidak fetch data weather otomatis saat view dibuka.
- Fetch weather hanya berjalan saat user menekan tombol.
- IoT chart hanya berjalan setelah user menekan `Connect IoT`.
- WeatherView dan IoTDashboardView tidak lagi menyimpan chart UI.
