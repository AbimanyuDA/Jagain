# Panduan Developer: Proyek Jagain (Social Media Pelaporan Infrastruktur)

Selamat datang di proyek **Jagain**! Dokumen ini dirancang oleh Project Manager untuk membantu seluruh developer memahami standar koding, struktur proyek, dan cara memulai pekerjaan pada fitur masing-masing.

---

## 🚀 Persiapan Awal (Setup Environment)

Sebelum mulai menulis kode, harap lakukan langkah-langkah berikut:

1. **Unduh Dependensi:**
   Jalankan perintah ini di root direktori proyek untuk memastikan semua paket terbaru terpasang:
   ```bash
   flutter pub get
   ```

2. **Inisialisasi Firebase:**
   Aplikasi ini menggunakan Firebase untuk Backend (Auth, Firestore, Storage). Harap hubungkan perangkat Anda ke Firebase project resmi:
   - Pastikan Anda sudah menginstal FlutterFire CLI secara global:
     ```bash
     dart pub global activate flutterfire_cli
     ```
   - Jalankan konfigurasi (pastikan sudah login ke akun firebase Anda menggunakan `firebase login`):
     ```bash
     flutterfire configure
     ```
   - Setelah selesai, impor `firebase_options.dart` yang dihasilkan ke dalam [lib/main.dart](file:///Users/abimanyudans/Coolyeah/Mobile%20Programming/Final-Project/jagain/lib/main.dart) dan ubah bagian inisialisasi Firebase.

3. **Inisialisasi API Key Google Maps:**
   - **Android:** Tambahkan API Key Google Maps Anda di `android/app/src/main/AndroidManifest.xml` pada tag `<meta-data>`:
     ```xml
     <meta-data android:name="com.google.android.geo.API_KEY"
                android:value="API_KEY_ANDA_DISINI"/>
     ```
   - **iOS:** Inisialisasi API Key di `ios/Runner/AppDelegate.swift` sebelum `GeneratedPluginRegistrant.register`:
     ```swift
     GMSServices.provideAPIKey("API_KEY_ANDA_DISINI")
     ```

---

## 📁 Struktur Arsitektur (Feature-First)

Kita menggunakan arsitektur **Feature-First** untuk memudahkan pembagian kerja tanpa adanya konflik Git yang berlebihan. Setiap folder di dalam `lib/features/` berisi kode spesifik untuk fitur tersebut yang dibagi menjadi 3 layer:

1. **`data/`**: Berisi sumber data (Firebase data sources) dan Repositories yang menangani pengambilan data, query Firestore, atau unggah foto ke Storage.
2. **`domain/`**: Berisi entity model data (contoh: `ReportModel`, `UserModel`) dan business logic murni.
3. **`presentation/`**: Berisi widget UI (Screens, Cards, Buttons) dan BLoC/Cubit yang mengelola state untuk UI tersebut.

### Contoh Alur Kerja BLoC di Proyek Ini
Jika ingin membuat fitur baru (misal: Feed):
- Buat Event di `presentation/bloc/feed_event.dart` (contoh: `FetchFeedRequested`).
- Buat State di `presentation/bloc/feed_state.dart` (contoh: `FeedLoading`, `FeedLoadSuccess`).
- Implementasikan logika transisi di `presentation/bloc/feed_bloc.dart`.
- Tampilkan di UI menggunakan `BlocBuilder` atau `BlocConsumer` pada Screen Anda.

*Contoh BLoC yang sudah di-setup dapat dilihat pada fitur Auth:*
- [auth_event.dart](file:///Users/abimanyudans/Coolyeah/Mobile%20Programming/Final-Project/jagain/lib/features/auth/presentation/bloc/auth_event.dart)
- [auth_state.dart](file:///Users/abimanyudans/Coolyeah/Mobile%20Programming/Final-Project/jagain/lib/features/auth/presentation/bloc/auth_state.dart)
- [auth_bloc.dart](file:///Users/abimanyudans/Coolyeah/Mobile%20Programming/Final-Project/jagain/lib/features/auth/presentation/bloc/auth_bloc.dart)

---

## 📋 Alokasi Tugas Tim (WBS 3 Developer)

Untuk kenyamanan kerja bersama, pembagian tugas dibagi secara adil di antara **3 Developer**:

### 👨‍💻 Developer A: Arsitektur Utama, Autentikasi & Admin Control
* **Modul Core & Auth (`lib/features/auth/` & `lib/app/`)**: Konfigurasi GoRouter, inisialisasi Firebase, tema dasar, dan fitur login/register multi-role.
* **Modul Admin Control (`lib/features/admin_panel/`)**: Moderasi laporan, verifikasi akun pejabat baru, dan analitik.

### 👨‍💻 Developer B: Feed Utama & Interaksi Sosial
* **Modul Feed & Engagement (`lib/features/feed/`)**: List feed laporan, sorting (upvote/terbaru/terdekat), interaksi Upvote/Downvote, komentar umum, dan pinned official comments.

### 👨‍💻 Developer C: Pembuatan Laporan, Integrasi GPS & Dashboard Pejabat
* **Modul Report Creation (`lib/features/report_creation/`)**: Halaman tambah laporan, kamera picker, upload Firebase Storage, integrasi Google Maps SDK (pinpoint lokasi).
* **Modul Pejabat Dashboard (`lib/features/pejabat_dashboard/`)**: Peta wilayah kerja pejabat, update status laporan (Dilaporkan -> Selesai) dengan lampiran foto bukti.

---

## 🎨 Panduan Desain (Theme Guidelines)

Jangan membuat warna secara manual (`Colors.blue`, `Colors.orange`, dsb) di UI Anda. Gunakan tema global yang sudah didefinisikan di [theme.dart](file:///Users/abimanyudans/Coolyeah/Mobile%20Programming/Final-Project/jagain/lib/core/theme/theme.dart):

- **Warna Utama (Primary):** `Theme.of(context).colorScheme.primary` (Warna biru elektrik premium).
- **Warna Aksen (Secondary):** `Theme.of(context).colorScheme.secondary` (Warna amber/jingga untuk status warning atau highlight kerusakan).
- **Card, Input, & Button:** Gunakan widget bawaan Flutter (`Card`, `TextField`, `ElevatedButton`). Desainnya telah diubah secara global agar memiliki sudut membulat (*rounded corners*) 12-16px dan bayangan (*elevation*) yang halus.
