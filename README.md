# 📱 Ticketly Mobile

**Ticketly Mobile** is a cross-platform mobile application built using **Flutter (Dart)** that serves as the client interface for the **Ticketly** event ticketing system. 

It connects to the **CodeIgniter 4 (PHP 8.1+) Backend RESTful API** to deliver a seamless event discovery and ticket purchasing experience on mobile devices.

> This project is the mobile companion to the Ticketly event platform, built as a college project at **Politeknik Negeri Cilacap**, Informatics Engineering Department.

---

[![Flutter](https://img.shields.io/badge/Flutter-3.11+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![CodeIgniter](https://img.shields.io/badge/API_Integration-CodeIgniter_4-EE4326?style=for-the-badge&logo=codeigniter&logoColor=white)](https://codeigniter.com)
[![Google Fonts](https://img.shields.io/badge/Font-Poppins-FF5722?style=for-the-badge&logo=googlefonts&logoColor=white)](https://fonts.google.com/specimen/Poppins)

---

## Daftar Isi

- [Fitur Utama](#fitur-utama)
- [Tech Stack & Dependensi](#tech-stack--dependensi)
- [Persyaratan Sistem](#persyaratan-sistem)
- [Struktur Folder Project](#struktur-folder-project)
- [Konfigurasi & Setup Lokal](#konfigurasi--setup-lokal)
- [Integrasi API CodeIgniter 4](#integrasi-api-codeigniter-4)
- [Cara Menjalankan Aplikasi](#cara-menjalankan-aplikasi)
- [Desain UI/UX](#desain-uiux)
- [Tim Pengembang](#tim-pengembang)
- [Lisensi](#lisensi)

---

## Fitur Utama

### 🔐 Authentication & Session
- **Registrasi & Login**: Autentikasi stateless menggunakan custom JWT. Token disimpan secara lokal menggunakan `shared_preferences`.
- **Manajemen Sesi**: Deteksi otomatis status login ketika aplikasi pertama kali dibuka.
- **Logout**: Membersihkan token dan data pengguna dari penyimpanan lokal secara aman.

### 🎟️ Event Discovery
- **Hero Banner / Featured Events**: Menampilkan event-event pilihan secara visual dan dinamis di bagian atas beranda.
- **Kategori Event**: Menyaring event berdasarkan kategori seperti *Concert*, *Festival*, *Show*, dll.
- **Pencarian & Detail Event**: Informasi lengkap mengenai deskripsi event, tanggal, lokasi, denah kursi (*seatmap*), serta daftar tipe tiket yang tersedia beserta sisa kuotanya secara real-time.

### 🛒 Checkout Flow
- **Kalkulasi Keranjang**: Menghitung subtotal tiket secara real-time, biaya admin, serta grand total sebelum melakukan transaksi.
- **Pemesanan Tiket (Start Checkout)**: Mengunci kuota tiket sementara selama proses pemesanan berlangsung.
- **Konfirmasi Pembayaran**: Mengunggah bukti pembayaran untuk diverifikasi oleh admin.
- **Pembatalan Pesanan**: Fitur membatalkan pesanan jika diperlukan atau jika batas waktu pembayaran habis.

### 🎫 Tiket Saya & Riwayat Transaksi
- **Riwayat Pesanan**: Melihat daftar transaksi lama dengan status pembayaran (`pending`, `completed`, `cancelled`, `expired`).
- **Detail E-Ticket**: Menampilkan tiket yang sudah berhasil dibeli lengkap dengan visualisasi barcode/QR Code mockup untuk keperluan check-in.

---

## Tech Stack & Dependensi

**Core Framework & Libraries**
- **Flutter SDK**: `^3.11.0` (Dart `^3.x`)
- **Google Fonts**: `^8.1.0` (Menggunakan font **Poppins** secara global)
- **HTTP Client**: `http ^1.2.0` (Komunikasi stateless dengan CI4 REST API)
- **Local Storage**: `shared_preferences ^2.2.0` (Penyimpanan token JWT & cache data user)

---

## Persyaratan Sistem

Sebelum menjalankan aplikasi Ticketly Mobile di komputer Anda, pastikan telah memenuhi persyaratan berikut:
- **Flutter SDK** versi `3.11.0` atau yang lebih baru.
- **Android Studio** atau **Xcode** (untuk menjalankan emulator Android / iOS simulator).
- **Ticketly Backend (CodeIgniter 4)** harus dalam keadaan berjalan secara lokal (`php spark serve`) atau hosted di server internet.

---

## Struktur Folder Project

Aplikasi ini mengikuti arsitektur modular yang bersih untuk memudahkan pemeliharaan kode:

```text
lib/
  ├── constants/    # Konfigurasi konstan (API endpoint, path)
  ├── data/         # Mock data & data internal aplikasi
  ├── extensions/   # Flutter & Dart extensions helper
  ├── models/       # Model data mapping JSON dari API
  ├── providers/    # State management helper (jika digunakan)
  ├── screens/      # Semua halaman/UI utama (Splash, Onboarding, Home, Checkout, dll)
  ├── service/      # Service layer untuk logic API (ApiService & AuthService)
  ├── theme/        # Konfigurasi visual, warna, font, dan radius (AppTheme)
  ├── utils/        # Helper utilitas (format tanggal, format rupiah, dll)
  └── widgets/      # Reusable UI components (Custom Button, EventCard, HeroBanner)
```

---

## Konfigurasi & Setup Lokal

### 1. Clone & Ambil Dependensi
Clone repository ini ke komputer Anda, lalu jalankan perintah flutter pub get untuk mengunduh semua package:

```bash
git clone https://github.com/pratama1246/ticketly.git
cd ticketly
flutter pub get
```

### 2. Konfigurasi Base URL API
Untuk menghubungkan aplikasi Flutter dengan backend CodeIgniter 4, pastikan konfigurasi host di [api_constants.dart](file:///home/pputra/Documents/Project-Web/ticketly/lib/constants/api_constants.dart) sudah sesuai.

Aplikasi mendeteksi platform yang berjalan secara dinamis agar developer tidak perlu mengubah IP manual:

```dart
// lib/constants/api_constants.dart
static String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:8080';
  }
  if (Platform.isAndroid) {
    // 10.0.2.2 adalah alias IP khusus untuk mengakses localhost mesin host dari Android Emulator
    return 'http://10.0.2.2:8080'; 
  }
  return 'http://localhost:8080'; // iOS Emulator / Mac
}
```

*Pastikan backend CI4 Anda berjalan di port `8080` (default `php spark serve`). Jika Anda menggunakan port lain atau hosting online, silakan sesuaikan file tersebut.*

---

## Integrasi API CodeIgniter 4

Aplikasi Flutter ini mengonsumsi REST API berikut secara dinamis:

| Endpoint | Method | Keterangan | Auth |
|---|---|---|---|
| `/api/auth/register` | `POST` | Pendaftaran akun baru | Public |
| `/api/auth/login` | `POST` | Login & generate JWT token | Public |
| `/api/auth/logout` | `POST` | Invalidasi sesi user | JWT |
| `/api/events` | `GET` | Mengambil daftar event (paginated) | Public |
| `/api/events/featured`| `GET` | Mengambil event unggulan (Hero Banner) | Public |
| `/api/events/landing` | `GET` | Mengambil data homepage terpadu | Public |
| `/api/events/{slug}` | `GET` | Detail event & tipe tiket | Public |
| `/api/checkout/start` | `POST` | Memulai checkout & booking tiket | JWT |
| `/api/checkout/confirm`| `POST` | Konfirmasi pembayaran (upload bukti) | JWT |
| `/api/checkout/cancel`| `POST` | Batalkan pesanan aktif | JWT |
| `/api/profile` | `GET` | Detail profil pengguna | JWT |
| `/api/profile/update` | `POST` | Update biodata & foto profil | JWT |
| `/api/orders` | `GET` | Riwayat transaksi tiket | JWT |

> 🔒 **Auth JWT**: Endpoint bertanda **JWT** membutuhkan header `Authorization: Bearer <token>` yang diambil dari cache lokal.

---

## Cara Menjalankan Aplikasi

Jalankan perintah berikut pada terminal Anda untuk meluncurkan aplikasi ke emulator atau perangkat fisik yang terhubung:

```bash
# Cek perangkat yang terdeteksi
flutter devices

# Jalankan aplikasi (pilih device jika ada beberapa yang terhubung)
flutter run
```

---

## Desain UI/UX

Ticketly dirancang dengan pendekatan *design-first* di Figma dengan panduan visual sebagai berikut:
- **Warna Utama**: Cream/Soft Yellow sebagai background dasar (`0xFFFFFDE7`) untuk nuansa modern, dipadukan dengan **Blue Primary** (`0xFF072AC8`) sebagai warna aksi utama.
- **Tipografi**: Menggunakan font **Poppins** dengan berbagai tingkatan berat (Medium, Semi-Bold, Bold) untuk mempermudah hirarki informasi bagi pengguna.
- **Interaksi**: Efek transisi halus dan micro-animations pada tombol dan card untuk meningkatkan kenyamanan navigasi.

---

## Tim Pengembang

- **Hana**
- **Tama**
- **Jihan**

Proyek ini dikembangkan sebagai tugas kuliah pada **Jurusan Teknik Informatika, Politeknik Negeri Cilacap**.

**Kelas**: Teknik Informatika 2D  
**Mata Kuliah**: Pemrograman Web 2 (Integrasi Mobile)  
**Institusi**: Politeknik Negeri Cilacap  

---

## Lisensi

Aplikasi ini dilisensikan di bawah [MIT License](LICENSE).
