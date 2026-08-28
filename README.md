# Iyup

<p align="center">
  <img
    src="https://github.com/Reynardstw/Iyup/blob/main/iYupLogo.jpeg"
    alt="Iyup Logo"
    width="200"
  />
</p>

<p align="center">
  <strong>Iyup: Find the Shade. Plan Your Visit. Stay Cool.</strong>
</p>

---

## 🎯 Problem Statement

Visiting an outdoor park under the sun is uncomfortable, and knowing where the shade will be — right now or later in the day — is hard to predict:

* Shade position constantly shifts as the sun moves across the sky.
* Environmental conditions (light, temperature, crowd) at a spot are hard to estimate ahead of time.
* Planning a comfortable visit time means guessing instead of knowing.

---

## ✨ The Iyup Solution

**Iyup** helps users find and plan visits to shaded spots in a park by combining **geometric shadow simulation**, **on-device ML forecasting**, and **IoT sensor integration**. Instead of guessing, users can see which bench or spot will be shaded at a given time, how conditions are trending, and plan a trip around it — all visualized on an interactive 3D map of the park. When a physical sensor node isn't connected, the app still runs end-to-end on shadow simulation and ML forecasting alone.

---

## 🚀 Key Features

* 🗺️ **3D Shade Map**: Interactive RealityKit-based 3D visualization of the park, spots, and tree shadows.
* ☀️ **Shadow Simulation**: Calculates real shade coverage per spot using sun position and geometric raycasting against tree occluders.
* 🧠 **ML Environment Forecasting**: On-device Core ML models predict light (lux), temperature, and occupancy for each spot — both short-horizon (next few hours) and long-horizon (next several days).
* 📡 **IoT Sensor Integration**: Receives real-time light, temperature, and occupancy readings over MQTT whenever an ESP32 sensor node is deployed and online; falls back gracefully to ML-forecasted estimates when no device is connected.
* 🌤️ **Weather-Aware Recommendations**: Pulls live weather via WeatherKit and suggests outfits based on temperature, condition, and time of day.
* 🧭 **Trip Planning & Reminders**: Plan a visit to a specific spot and get a scheduled local notification before it starts.
* 📍 **Nearby Park Discovery**: Shows distance from the user's current location to the park.

---

## 👥 Target Users

* People looking for a comfortable, shaded spot to relax outdoors
* Park visitors who want to plan a visit around the best time of day
* Anyone wanting a quick outdoor-comfort forecast before heading out

---

## 🧰 Tech Stack

### iOS App (Swift)

* **Framework**: SwiftUI
* **3D Visualization**: RealityKit
* **ML Inference**: Core ML (6 custom-trained models — short/long horizon × lux/temperature/occupancy)
* **Shadow Simulation**: Custom geometric raycasting engine (SIMD-based)
* **Location**: Core Location
* **Weather**: WeatherKit
* **Sun Position**: SunKit
* **Notifications**: UserNotifications (local, scheduled trip reminders)
* **Architecture**: Feature-based modular MVVM with protocol-based dependency injection and a manual composition root

### IoT Integration

* **Protocol**: MQTT (custom lightweight client built over Network.framework, TLS)
* **Device**: ESP32 sensor node streaming live light/temperature/occupancy readings — currently a prototype integration; not permanently deployed on-site, so live readings are only available while a configured device is powered on and connected. Without it, the app falls back to safe defaults and ML forecasts.

---

## 📱 App Flow

1. **Home / Nearby Park**
   → View distance to the park → Open the park's Shade Map.
2. **Shade Map (3D)**
   → Explore spots on an interactive RealityKit map → See real-time shade status per spot → Scrub the time slider to preview shade coverage later in the day.
3. **Spot Detail**
   → View ML-forecasted lux, temperature, and occupancy → See live IoT sensor readings when a sensor node is connected, otherwise ML forecasts and safe defaults are used → Get an outfit recommendation based on current weather.
4. **Plan Trip**
   → Choose a spot and time → Set a reminder lead time → Receive a local notification before the visit.
5. **IoT Dashboard**
   → Connect to the MQTT broker → View live incoming sensor snapshots from the ESP32 device when it's deployed and online.

---

## 📦 Installation Guide

```bash
git clone https://github.com/Reynardstw/Iyup.git
cd Iyup
open Iyup.xcodeproj
```

Ensure you have:

* Xcode with iOS 26+ SDK
* A physical device or simulator supporting RealityKit
* (Optional) An ESP32 device configured to publish sensor data to the configured MQTT broker/topic for the live IoT feature — this is a prototype integration and is not permanently running on-site; without it, the app still works fully using ML forecasts and safe fallback values

---

## 🌍 Roadmap

* [x] Geometric shadow simulation with raycasting
* [x] Core ML environment forecasting (short & long horizon)
* [x] MQTT sensor integration (prototype — works when ESP32 device is deployed and online)
* [x] 3D RealityKit shade map
* [x] Trip planning with local notifications
* [ ] Multi-park support
* [ ] Historical trend charts per spot

---

## 👨‍💻 Contributors

*(to be added)*

---

## 📄 License

*(to be added)*
