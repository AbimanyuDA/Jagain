# 📱 Jagain - Aplikasi Pelaporan Infrastruktur Rusak

**Jagain** adalah aplikasi sosial media berbasis mobile yang dirancang untuk memudahkan warga melaporkan kerusakan infrastruktur (jalan berlubang, lampu jalan padam, jembatan rusak, dll) agar dapat segera ditanggapi dan diperbaiki oleh pejabat setempat.

---

## 🛠️ Tech Stack & Arsitektur

* **Framework:** Flutter (Dart)
* **State Management:** BLoC / Cubit (`flutter_bloc` & `bloc`)
* **Backend:** Firebase (Firebase Auth, Cloud Firestore, Firebase Storage)
* **Navigasi:** GoRouter (`go_router`)
* **Peta & GPS:** Google Maps SDK (`google_maps_flutter` & `geolocator`)

---

## 📁 Struktur Folder (Feature-First Architecture)

Proyek ini menggunakan pendekatan **Feature-First** untuk mengisolasi setiap fitur secara mandiri. Hal ini bertujuan agar beberapa developer dapat bekerja secara paralel tanpa adanya konflik Git (*merge conflicts*).

```text
lib/
├── main.dart                  # Titik masuk utama aplikasi (Inisialisasi Firebase)
├── app/
│   ├── app.dart               # Konfigurasi MaterialApp & Routing
│   └── routes.dart            # Konfigurasi GoRouter (Daftar semua Halaman/Screens)
├── core/                      # Sumber daya bersama (Shared Resources)
│   ├── constants/             # Konstanta string, warna, ukuran
│   ├── theme/                 # Pengaturan tema visual (Desain premium, rounded borders 12-16px)
│   ├── utils/                 # Helper fungsi (Tanggal, validasi, geolokasi)
│   └── widgets/               # Komponen UI global (Custom buttons, input fields, loading)
└── features/                  # Implementasi Fitur Mandiri (Feature Modules)
    ├── auth/                  # Fitur Autentikasi & Profil (Warga, Pejabat, Admin)
    ├── feed/                  # Fitur Feed Utama, Voting (Up/Down), & Komentar
    ├── report_creation/       # Fitur Form Laporan Baru, Kamera & Pin Peta GPS
    ├── pejabat_dashboard/     # Fitur Peta Pengawasan & Update Status untuk Pejabat
    └── admin_panel/           # Fitur Moderasi Laporan & Manajemen Akun untuk Admin
```

Setiap folder fitur di dalam `features/` dibagi menjadi 3 layer:
1. **`data/`**: Repositori dan sumber data ( Firestore query, upload Firebase Storage).
2. **`domain/`**: Model data / Entitas (contoh: `ReportModel`, `UserModel`).
3. **`presentation/`**: Komponen tampilan UI (Screens/Widgets) dan pengelola state (BLoC/Cubit).

---

## 📋 Alokasi Tugas Tim (WBS 3 Developer)

Waktu pengembangan dibatasi selama **2 Minggu (14 Hari)**. Tugas dibagi secara adil di bawah koordinasi Project Manager (PM):

### 👨‍💻 Developer A: Arsitektur Utama, Autentikasi & Admin Control
* **Modul Core & Auth (`lib/features/auth/` & `lib/app/`)**: Konfigurasi GoRouter, tema visual, Firebase Auth (login/register multi-role).
* **Modul Admin Control & Global Stats (`lib/features/admin_panel/`)**: Halaman moderasi laporan, verifikasi akun pejabat baru, dan grafik statistik global nasional.

### 👨‍💻 Developer B: Feed Utama & Interaksi Sosial
* **Modul Feed & Engagement (`lib/features/feed/`)**: Desain linimasa/feed postingan, sorting feed (upvote/terbaru/terdekat), interaksi Upvote/Downvote, komentar umum, dan pinned official comments.

### 👨‍💻 Developer C: Pembuatan Laporan, Integrasi GPS & Dashboard Pejabat
* **Modul Report Creation (`lib/features/report_creation/`)**: Halaman tambah laporan, kamera picker, upload foto ke Firebase Storage, integrasi Google Maps SDK (pinpoint lokasi).
* **Modul Pejabat Dashboard & Regional Stats (`lib/features/pejabat_dashboard/`)**: Peta wilayah kerja pejabat, update status laporan (Dilaporkan -> Selesai) dengan lampiran foto bukti, dan statistik regional khusus daerah kerjanya.

---

## 🚀 Cara Memulai Setup Lokal

### 1. Unduh Dependensi
Jalankan perintah berikut pada terminal di direktori root proyek:
```bash
flutter pub get
```

### 2. Hubungkan Proyek ke Firebase Anda
Aplikasi ini membutuhkan Firebase. Lakukan langkah-langkah berikut:
1. Pastikan Anda sudah menginstal FlutterFire CLI secara global:
   ```bash
   dart pub global activate flutterfire_cli
   ```
2. Pastikan Anda sudah login ke akun Firebase di terminal:
   ```bash
   firebase login
   ```
3. Hubungkan proyek ini ke Firebase project resmi:
   ```bash
   flutterfire configure
   ```
4. Setelah berkas `firebase_options.dart` terbuat otomatis, buka [lib/main.dart](file:///Users/abimanyudans/Coolyeah/Mobile%20Programming/Final-Project/jagain/lib/main.dart) lalu impor berkas tersebut dan aktifkan opsi inisialisasi Firebase.

### 3. Masukkan API Key Google Maps
Pelaporan koordinat membutuhkan Google Maps SDK:
* **Android:** Buka file `android/app/src/main/AndroidManifest.xml`, lalu cari tag `<meta-data>` dan isi nilai `API_KEY` Google Cloud Platform Anda.
* **iOS:** Buka file `ios/Runner/AppDelegate.swift`, kemudian cari fungsi `GMSServices.provideAPIKey("YOUR_KEY")` dan ganti dengan API Key Anda.

### 4. Analisis Kode (Linter Check)
Sebelum melakukan *pull request* / *push*, pastikan kode Anda bersih dan tidak merusak build dengan menjalankan:
```bash
flutter analyze
```
Jika tidak ada isu yang ditemukan, kode aman untuk digabungkan!
