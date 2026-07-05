# MLModels

Dokumentasi resource model dan JSON yang masih dipakai setelah cleanup.

## Models

1. `MLModels/Models/ModelLongLux.mlmodel` — model long-term untuk prediksi lux.
2. `MLModels/Models/ModelLongOccupancy.mlmodel` — model long-term untuk prediksi occupancy.
3. `MLModels/Models/ModelLongTemp.mlmodel` — model long-term untuk prediksi temperature.
4. `MLModels/Models/ModelShortLux.mlmodel` — model short-term untuk prediksi lux.
5. `MLModels/Models/ModelShortOccupancy.mlmodel` — model short-term untuk prediksi occupancy.
6. `MLModels/Models/ModelShortTemp.mlmodel` — model short-term untuk prediksi temperature.

## JSON Feature Files

1. `MLModels/Json/model_features_long_lux_xgb.json` — urutan 9 feature untuk model terkait.
2. `MLModels/Json/model_features_long_occupancy_xgb.json` — urutan 9 feature untuk model terkait.
3. `MLModels/Json/model_features_long_temp_xgb.json` — urutan 9 feature untuk model terkait.
4. `MLModels/Json/model_features_short_lux_xgb.json` — urutan 18 feature untuk model terkait.
5. `MLModels/Json/model_features_short_occupancy_xgb.json` — urutan 20 feature untuk model terkait.
6. `MLModels/Json/model_features_short_temp_xgb.json` — urutan 19 feature untuk model terkait.

## File yang dihapus dari output

1. `MLModels/Json/model_features.json` — Manifest JSON model lama; service aktif memakai JSON terpisah model_features_*_xgb.json.
   - File ini adalah manifest feature gabungan versi lama.
   - Service aktif tidak memakai manifest gabungan ini karena sudah memakai JSON terpisah per target model, misalnya model_features_short_lux_xgb.json dan model_features_long_temp_xgb.json.
