A new Flutter project.
📦 Build & Release Flutter App
🔧 Build APK (Android)
flutter build apk --release
flutter run --release
File hasil build dapat ditemukan di
build/app/outputs/flutter-apk/app-release.apk
📲 Install APK ke Device/Emulator
Pastikan device terhubung (adb devices), lalu jalankan:
adb install build/app/outputs/flutter-apk/app-release.apk
🧾 Build App Bundle (AAB) — untuk Google Play Store
flutter build appbundle --release
Hasil build AAB akan berada di:
arduino
build/app/outputs/bundle/release/app-release.aab
🍎 Build iOS (Release Mode)
flutter build ios --release
⚠️ Harus dijalankan di macOS dengan Xcode, dan pastikan provisioning profile & signing sudah dikonfigurasi.
🧪 Analisis Ukuran Build
flutter build apk --release --analyze-size
🚀 Jalankan Langsung ke Device (Release Mode)
flutter run --release
Atau langsung install APK hasil build (jika device/emulator terhubung):
flutter install --release
JDK 17
JAVA VERSION 17
KOTLIN 2.0.0
curl -o assets/icon/app_icon.png https://cdn.yoursite.com/app_icon.png
flutter pub run flutter_launcher_icons:main
flutter pub global activate rename
flutter pub global run rename --appname "Presensi Jasnita"
RUN EMULATOR
emulator -list-avds
Run a AVD from the list
emulator -avd {avd_name}
emulator -avd Pixel_5_API_34_-_Android_14
flutter build apk --release -t lib/main_prod.dart
upgrading Flutter to 3.32.5 from 3.22.3