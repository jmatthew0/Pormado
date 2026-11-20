# Pormado 

A digital wardrobe: digitize your clothes, build outfits without opening your closet,
plan them on a calendar, and get suggestions based on **Philippine weather**.

## Screens
Today (home) · Wardrobe · Category list · Add item (2 steps) · Item detail ·
Outfit builder / Saved · Outfit calendar · Favorites · Weather outfits

## Setup
```bash
git clone https://github.com/jmatthew0/Pormado.git && cd Pormado
flutter create . --project-name pormado --org com.pormado --platforms android,ios
flutter pub get
flutter run
```
`flutter create .` only adds the missing `android/` and `ios/` folders; it keeps `lib/` and `pubspec.yaml`.

### Permissions (required)
**Android** – `android/app/src/main/AndroidManifest.xml`, inside `<manifest>`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
```
**iOS** – `ios/Runner/Info.plist`:
```xml
<key>NSCameraUsageDescription</key><string>Photograph clothes to add them to your wardrobe.</string>
<key>NSPhotoLibraryUsageDescription</key><string>Choose clothing photos from your gallery.</string>
```

## Weather 
`lib/services/weather.dart` uses the free [Open-Meteo](https://open-meteo.com) API (no key), timezone
`Asia/Manila`, °C and km/h. Pick Manila, Quezon City, Calamba, Baguio, Cebu, Iloilo or Davao from
the weather screen. Rain risk (≥50% in the next 12h) drives the "bring an umbrella" advice and the
outfit "smart fit" score. Offline → typical Manila-style conditions are shown.

## Notes / next steps
- Sample wardrobe uses emoji placeholders; photos you add replace them.
- `lib/services/image_processing.dart`: colour detection from the photo works; **background removal is a
  stub** (`removesBackground = false`). Plug in ML Kit subject segmentation or remove.bg there.
- Data is in memory only. Add `shared_preferences`/`sqflite` in `AppState` for persistence.
