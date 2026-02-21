# Rencana Migrasi Framework dari KMP ke Flutter/React Native

Dokumen ini berisi saran dan strategi untuk migrasi aplikasi `AnimeDrawAI` dari Kotlin ke framework lain yang lebih stabil untuk pengembangan cross-platform (Android & iOS).

## User Review Required

> [!IMPORTANT]
> Pengembangan untuk iOS tetap memerlukan Mac di titik tertentu (untuk build akhir, signing, dan upload ke App Store). Framework seperti Flutter atau React Native mempermudah penulisan kode di Windows, namun proses build iOS tetap "terunci" di ekosistem Apple.

> [!WARNING]
> Migrasi adalah proses yang memakan waktu. Kami akan membandingkan opsi terbaik agar fitur-fitur seperti Firebase, Drawing (Photo Editor), dan AdMob tetap berjalan lancar.

## Proposed Changes

### 1. Pilihan Framework Alternatif

| Fitur | **Flutter (Dart)** | **React Native (JS/TS)** | **Compose Multiplatform** |
| :--- | :--- | :--- | :--- |
| **Kemitraan Bahasa** | Mirip Kotlin/Java | Mirip Web (JS/TS) | Sama (Kotlin) |
| **Performa UI** | Sangat Tinggi (Skia Engine) | Tinggi (Native Components) | Tinggi (Skia/Compose) |
| **Kemudahan iOS** | Sangat Baik (Tooling matang) | Baik | Sulit (Masih berbasis KMP) |
| **Ekosistem Lib** | Sangat Besar | Luar Biasa Besar | Sedang/Berkembang |

### 2. Strategi Migrasi untuk `AnimeDrawAI`

Berdasarkan struktur project saat ini:

#### A. Networking & Data
- **Android (Retrofit + Gson)** -> **Flutter (Dio + JSON Serializable)**.
- Implementasi API ComfyUI tetap bisa digunakan dengan logic yang sama.

#### B. Firebase & Auth
- Flutter memiliki library `firebase_core` dan `firebase_auth` yang sangat stabil dan sering mendahului KMP dalam hal update fitur.

#### C. Drawing / Photo Editor
- Penggunaan `com.burhanrashid52:photoeditor` di Android dapat diganti dengan library Flutter seperti `pro_image_editor` atau custom implementation menggunakan `CustomPainter` yang lebih fleksibel di Flutter.

#### D. AdMob & Billing
- Flutter memiliki plugin resmi `google_mobile_ads` dan `in_app_purchase` yang sangat mudah diintegrasikan dibandingkan KMP.

## Verification Plan

### Manual Verification
1. **Setup Development Environment**:
   - Install Flutter SDK di Windows.
   - Konfigurasi Android Studio untuk Flutter.
2. **Prototyping Fitur Utama**:
   - Membuat satu halaman "Draw" sederhana di Flutter untuk melihat performa rendering di Android.
   - Menghubungkan Firebase Auth (Google Sign-In) untuk memastikan interop berjalan lancar.
3. **iOS Build (Cloud/Mac)**:
   - Mencoba build aplikasi sederhana tersebut ke iOS emulator (jika ada akses Mac) atau menggunakan layanan seperti Codemagic/Appcircle untuk melihat apakah build berhasil tanpa pusing manual setup KMP.
