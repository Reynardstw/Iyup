# IoT MQTT Feature

Fitur ini menerima data sensor dari ESP32 melalui MQTT over TLS ke HiveMQ Cloud.

## Input MQTT

- Host: HiveMQ Cloud
- Port: 8883
- Topic: `sensor/data`
- Payload JSON:

```json
{"Orang":4,"Suhu":30.2,"Kelembapan":65.1,"Cahaya":1800}
```

## Alur File

```text
IoTDashboardView.swift
→ IoTViewModel.swift
→ IoTMQTTClient.swift
→ HiveMQ MQTT broker
→ sensor/data
→ IoTSensorSnapshot.swift
→ IoTLDRCalibration.swift
→ IoTDashboardView.swift
```

## Konversi Cahaya LDR

Field `Cahaya` dari ESP32 masih berupa nilai ADC mentah 12-bit. Di iOS, nilai ini dikonversi menjadi estimasi lux menggunakan konfigurasi rangkaian LDR:

```text
VIN = 3.3 V
R_FIXED = 100 Ω
ADC_MAX = 4095
```

Rumus yang dipakai:

```text
Vout = ADC / 4095 × VIN
R_LDR = R_FIXED × (VIN - Vout) / Vout
Lux = (500000 / R_LDR) ^ (1 / 1.25)
```

Jika ADC bernilai `0`, atau hasil perhitungan tidak valid, UI menampilkan cahaya sebagai tidak valid/terlalu rendah.

## File

### Views/IoTDashboardView.swift
Menampilkan status koneksi MQTT, data sensor terakhir, grafik live, raw MQTT message, tombol connect, disconnect, dan clear. Grafik cahaya memakai satuan lux, bukan ADC mentah.

### ViewModels/IoTViewModel.swift
Mengatur state layar IoT, menyimpan data sensor terakhir, menyimpan riwayat data, mengubah snapshot menjadi data chart, dan memformat nilai lux, Vout, serta resistansi LDR untuk UI.

### Services/IoTMQTTClient.swift
MQTT client native berbasis `Network.framework`. File ini membuat koneksi TLS, mengirim CONNECT, SUBSCRIBE, PINGREQ, menerima PUBLISH, lalu decode payload JSON.

### Services/IoTMQTTConfiguration.swift
Menyimpan konfigurasi broker, topic, username, password, client ID prefix, dan keep alive.

### Services/PreviewIoTMQTTClient.swift
Client dummy untuk SwiftUI Preview.

### Models/IoTSensorSnapshot.swift
Model data sensor dari ESP32. Mapping JSON:

```text
Orang      → peopleCount
Suhu       → temperatureCelsius
Kelembapan → humidityPercent
Cahaya     → lightADC
```

Model ini juga menyediakan `estimatedLux` dari hasil konversi LDR.

### Models/IoTLDRCalibration.swift
Menyimpan konfigurasi kalibrasi LDR dan fungsi konversi ADC menjadi Vout, resistansi LDR, dan estimasi lux.

### Models/IoTMQTTConnectionState.swift
State koneksi MQTT untuk UI.

## Catatan Keamanan

Konfigurasi saat ini dibuat untuk demo langsung. Untuk production, password MQTT sebaiknya tidak disimpan hardcoded di source code. Gunakan backend token exchange, Keychain, atau konfigurasi private yang tidak ikut commit.
