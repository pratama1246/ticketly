# Ticketly - Flutter App Design Documentation

> Dokumentasi desain lengkap untuk implementasi aplikasi Ticketly ke Flutter.
> Semua ikon menggunakan SVG inline. Tidak ada emoji di kode UI.

---

## Daftar Isi

1. [Design Tokens](#1-design-tokens)
2. [Typography](#2-typography)
3. [Iconography](#3-iconography)
4. [Components](#4-components)
   - [Buttons](#41-buttons)
   - [Input Fields](#42-input-fields)
   - [Cards](#43-cards)
   - [Bottom Navigation](#44-bottom-navigation)
   - [Dialogs & Popups](#45-dialogs--popups)
   - [FAQ Accordion](#46-faq-accordion)
   - [Step Indicator (Cara Beli Tiket)](#47-step-indicator-cara-beli-tiket)
   - [Ticket Tier Card](#48-ticket-tier-card)
   - [Payment Method Item](#49-payment-method-item)
5. [Screens](#5-screens)
   - [Splash & Onboarding](#51-splash--onboarding)
   - [Auth Screens](#52-auth-screens)
   - [Beranda (Home)](#53-beranda-home)
   - [Konser / Festival / Event List](#54-konser--festival--event-list)
   - [Event Detail](#55-event-detail)
   - [Checkout Flow](#56-checkout-flow)
   - [My Ticket](#57-my-ticket)
   - [Akun & Edit Profile](#58-akun--edit-profile)
6. [Navigation Structure](#6-navigation-structure)
7. [State & Interaction Notes](#7-state--interaction-notes)

---

## 1. Design Tokens

### Colors

```dart
// lib/core/theme/app_colors.dart

class AppColors {
  // Background utama semua screen (non-dark)
  static const Color background = Color(0xFFFFFDE7); // cream/light yellow

  // Blue Primary
  static const Color bluePrimaryLight        = Color(0xFFE6EAFA);
  static const Color bluePrimaryNormal       = Color(0xFF072AC8);
  static const Color bluePrimaryNormalHover  = Color(0xFF0626B4);
  static const Color bluePrimaryDark         = Color(0xFF052096);
  static const Color bluePrimaryDarker       = Color(0xFF020F46);

  // Blue Secondary
  static const Color blueSecondaryLight      = Color(0xFFE9F5FF);
  static const Color blueSecondaryNormal     = Color(0xFF1E96FC);
  static const Color blueSecondaryDark       = Color(0xFF1771BD);

  // Blue Soft
  static const Color blueSoftLight           = Color(0xFFF6FBFE);
  static const Color blueSoftNormal          = Color(0xFFA2D6F9);
  static const Color blueSoftDark            = Color(0xFF7AA1BB);

  // Yellow Accent
  static const Color yellowAccentNormal      = Color(0xFFFFC600);
  static const Color yellowAccentLight       = Color(0xFFFFF9E6);

  // Yellow Bright
  static const Color yellowBrightNormal      = Color(0xFFFCF300);

  // Orange
  static const Color orangeNormal            = Color(0xFFF4AE00);

  // Purple
  static const Color purpleNormal            = Color(0xFF523FFC);
  static const Color purpleLight             = Color(0xFFEEECFF);

  // Neutrals
  static const Color white                   = Color(0xFFFFFFFF);
  static const Color black                   = Color(0xFF000000);
  static const Color textPrimary             = Color(0xFF1A1A1A);
  static const Color textSecondary          = Color(0xFF6B7280);
  static const Color textHint               = Color(0xFF9CA3AF);
  static const Color border                 = Color(0xFFE5E7EB);
  static const Color cardBackground         = Color(0xFFFFFFFF);
  static const Color divider                = Color(0xFFF3F4F6);

  // Status
  static const Color success                 = Color(0xFF22C55E);
  static const Color successLight            = Color(0xFFDCFCE7);
  static const Color error                   = Color(0xFFEF4444);
  static const Color errorLight              = Color(0xFFFEE2E2);
  static const Color warning                 = Color(0xFFF59E0B);

  // Ticket Tier Colors
  static const Color tierDreamZone           = Color(0xFF4ADE80); // hijau
  static const Color tierFutureZone          = Color(0xFF60A5FA); // biru muda
  static const Color tierCat1               = Color(0xFFFBBF24); // kuning
  static const Color tierCat2               = Color(0xFFF472B6); // pink
  static const Color tierCat3               = Color(0xFFF87171); // merah
  static const Color tierCat4               = Color(0xFFA78BFA); // ungu

  // Onboarding gradient (dark overlay)
  static const Color onboardingOverlayStart = Color(0x00000000);
  static const Color onboardingOverlayEnd   = Color(0xCC000000);
}
```

### Spacing & Radius

```dart
// lib/core/theme/app_dimensions.dart

class AppDimensions {
  // Spacing
  static const double xs   = 4.0;
  static const double sm   = 8.0;
  static const double md   = 12.0;
  static const double base = 16.0;
  static const double lg   = 20.0;
  static const double xl   = 24.0;
  static const double xxl  = 32.0;
  static const double xxxl = 48.0;

  // Border Radius
  static const double radiusSm   = 8.0;
  static const double radiusMd   = 12.0;
  static const double radiusLg   = 16.0;
  static const double radiusXl   = 20.0;
  static const double radiusFull = 999.0;

  // Card elevation
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;

  // Bottom nav height
  static const double bottomNavHeight = 64.0;

  // Screen horizontal padding
  static const double screenPadding = 16.0;
}
```

---

## 2. Typography

Font: **Poppins** (Google Fonts)

```dart
// lib/core/theme/app_text_styles.dart
// Tambahkan dependency: google_fonts: ^6.x.x

import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextStyle get displayLarge => GoogleFonts.poppins(
    fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  static TextStyle get displayMedium => GoogleFonts.poppins(
    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary);

  static TextStyle get headingLarge => GoogleFonts.poppins(
    fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static TextStyle get headingMedium => GoogleFonts.poppins(
    fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static TextStyle get headingSmall => GoogleFonts.poppins(
    fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static TextStyle get bodyLarge => GoogleFonts.poppins(
    fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary);

  static TextStyle get bodyMedium => GoogleFonts.poppins(
    fontSize: 13, fontWeight: FontWeight.w400, color: AppColors.textPrimary);

  static TextStyle get bodySmall => GoogleFonts.poppins(
    fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary);

  static TextStyle get caption => GoogleFonts.poppins(
    fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textHint);

  static TextStyle get buttonText => GoogleFonts.poppins(
    fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.white);

  static TextStyle get labelMedium => GoogleFonts.poppins(
    fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textSecondary);

  static TextStyle get linkText => GoogleFonts.poppins(
    fontSize: 13, fontWeight: FontWeight.w500,
    color: AppColors.bluePrimaryNormal,
    decoration: TextDecoration.underline);
}
```

---

## 3. Iconography

Semua ikon menggunakan **SVG via `flutter_svg`** package.

```yaml
# pubspec.yaml
dependencies:
  flutter_svg: ^2.0.0
```

### SVG Asset List

Letakkan semua file di `assets/icons/`

| Nama File | Digunakan Di | Deskripsi |
|-----------|-------------|-----------|
| `home.svg` | Bottom Nav | Ikon rumah |
| `ticket.svg` | Bottom Nav | Ikon tiket |
| `person.svg` | Bottom Nav | Ikon profil |
| `search.svg` | Beranda | Search bar |
| `calendar.svg` | Event Detail, My Ticket | Tanggal |
| `clock.svg` | Event Detail, My Ticket | Waktu |
| `location_pin.svg` | Event Detail, My Ticket | Lokasi |
| `chevron_right.svg` | Akun menu | Arrow kanan |
| `chevron_down.svg` | FAQ Accordion | Arrow bawah |
| `chevron_left.svg` | AppBar back | Arrow kiri |
| `eye.svg` | Input password | Show password |
| `eye_off.svg` | Input password | Hide password |
| `edit_pencil.svg` | Akun menu | Edit profil |
| `lock.svg` | Akun menu | Kata sandi |
| `settings_gear.svg` | Akun menu | Pengaturan |
| `logout.svg` | Akun menu | Keluar (merah) |
| `check.svg` | Pembayaran berhasil | Centang hijau |
| `dollar_circle.svg` | Popup konfirmasi bayar | Ikon $ |
| `copy.svg` | VA number | Copy nomor |
| `qr_code.svg` | E-Tiket | QR placeholder |
| `facebook.svg` | Auth SSO | Facebook |
| `google.svg` | Auth SSO | Google |
| `apple.svg` | Auth SSO | Apple |
| `shield_key.svg` | Lupa Kata Sandi | Ilustrasi |
| `shield_lock.svg` | Verifikasi Kode | Ilustrasi |
| `ovo.svg` | Payment | OVO logo |
| `dana.svg` | Payment | DANA logo |
| `gopay.svg` | Payment | GoPay logo |
| `shopeepay.svg` | Payment | ShopeePay logo |
| `bri.svg` | Payment | BRI logo |
| `bca.svg` | Payment | BCA logo |
| `bni.svg` | Payment | BNI logo |
| `mandiri.svg` | Payment | Mandiri logo |
| `akulaku.svg` | Payment | Akulaku logo |
| `allobank.svg` | Payment | Allobank logo |
| `info_circle.svg` | Ketentuan umum | Info icon |
| `badge_live.svg` | Event Detail | Sedang Berlangsung |
| `notification_bell.svg` | Header (opsional) | Notifikasi |

### Cara Penggunaan SVG

```dart
// Gunakan SvgPicture.asset untuk semua ikon
SvgPicture.asset(
  'assets/icons/home.svg',
  width: 24,
  height: 24,
  colorFilter: ColorFilter.mode(
    AppColors.bluePrimaryNormal,
    BlendMode.srcIn,
  ),
)
```

---

## 4. Components

### 4.1 Buttons

#### Primary Button (Full Width)

```
Appearance : Background bluePrimaryNormal, teks putih, bold, rounded-full
Height     : 52px
Font       : Poppins SemiBold 15px
Radius     : 999 (pill)
State      :
  - Default  : bg #072AC8
  - Hover    : bg #0626B4
  - Disabled : bg #E6EAFA, teks #9CA3AF
```

```dart
// AppPrimaryButton widget
ElevatedButton(
  onPressed: onPressed,
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.bluePrimaryNormal,
    foregroundColor: AppColors.white,
    minimumSize: const Size(double.infinity, 52),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
    ),
    elevation: 0,
  ),
  child: Text(label, style: AppTextStyles.buttonText),
)
```

#### Secondary / Outlined Button

```
Appearance : Border bluePrimaryNormal, teks bluePrimaryNormal, transparan bg
Height     : 52px
Radius     : 999 (pill)
Contoh     : Tombol "Batal", "Coba Lagi"
```

#### Green Button (Success Action)

```
Appearance : Background #22C55E, teks putih
Contoh     : "Lihat Tiket Saya" di popup pembayaran berhasil
```

#### Danger/Outlined Red Button

```
Appearance : Border error, teks error
Contoh     : "Batalkan Pesanan"
```

---

### 4.2 Input Fields

#### Text Field - Default

```
Height     : 52px
Radius     : 12px
Border     : 1.5px #E5E7EB
Focus      : Border 2px #072AC8
Filled     : bg #FFFFFF
Font       : Poppins Regular 14px
Hint color : #9CA3AF
Label      : Poppins Medium 13px, di atas field, warna #1A1A1A
Required   : Asterisk (*) merah di label
```

#### Text Field States (dari field.png)

| State | Border | Background |
|-------|--------|-----------|
| Empty | #E5E7EB 1.5px | #FFFFFF |
| Filled | #072AC8 1.5px | #FFFFFF |
| Focus | #072AC8 2px | #FFFFFF |
| Error | #EF4444 1.5px | #FEE2E2 |

#### Password Field

```
Tambahan : Ikon eye/eye_off di trailing (SVG)
Toggle   : tap untuk show/hide
```

#### Date Field

```
Leading icon : calendar.svg (SVG)
Placeholder  : DD/MM/YYYY
Contoh       : Tanggal lahir di form Data Diri
```

#### Radio Button (Iya / Tidak)

```
Label  : "Iya" dan "Tidak" berdampingan
Style  : Radio biasa Flutter, active color bluePrimaryNormal
Contoh : Form data diri (pertanyaan boolean)
```

#### Checkbox

```
Unchecked : border abu, bg putih
Checked   : bg bluePrimaryNormal, ikon centang putih
Contoh    : Syarat & Ketentuan, Kebijakan Privasi di checkout
```

#### OTP Input (6 digit)

```
Layout   : Row 6 kotak
Size     : 48x56px per kotak
Radius   : 12px
Border   : 1.5px #E5E7EB
Focus    : Border 2px #072AC8
Font     : Poppins Bold 20px center
```

---

### 4.3 Cards

#### Event Card (Horizontal Scroll / Grid)

```
Size       : 160x200px (horizontal scroll) atau full-col width (grid)
Radius     : 16px
Shadow     : 0 2px 8px rgba(0,0,0,0.08)
Background : #FFFFFF
Structure  :
  - Thumbnail image (top, rounded atas 16px, height ~100px)
  - Badge "SOLD OUT" jika habis (overlay, bg merah, teks putih)
  - Content padding 10px:
      - Nama event (Poppins SemiBold 12px, max 2 lines)
      - Row: ikon location_pin.svg + lokasi (caption)
      - Row: ikon clock.svg + waktu (caption)
      - Tombol "Selengkapnya" (outline biru kecil, height 28px)
```

#### My Ticket Card

```
Radius     : 16px
Background : #FFFFFF
Shadow     : elevationSm
Structure  :
  - Row:
      Left  : Thumbnail square (64x64px, radius 8px)
      Right : Nama event (SemiBold 14px), tanggal, waktu, lokasi (caption)
  - Tombol "Lihat Tiket" (outline biru full width, height 36px)
  - Dashed divider horizontal di tengah card (efek tiket)
```

#### E-Tiket Card

```
Background : bluePrimaryNormal (#072AC8)
Teks       : putih
Radius     : 20px
Structure  :
  - Header: Logo Ticketly + "E-TIKET RESMI" + Order ID
  - Divider putih dashed
  - Info grid (label + value): PEMBELI, TANGGAL, WAKTU, LOKASI, KATEGORI, NOMOR KURSI
  - Divider putih dashed
  - QR Code (hitam, bg putih, padding 12px)
  - Kode tiket teks di bawah QR
  - Footer: copyright text
```

#### Promo Banner Card

```
Background : gradient (biru ke ungu)
Radius     : 16px
Content    : Label "Flash Discount", headline promo, CTA button
```

#### Step Card (Cara Beli Tiket)

```
Layout     : Grid 2x2
Size       : ~150x150px
Radius     : 16px
Background : #FFFFFF
Shadow     : elevationSm
Structure  :
  - Nomor step (circle, ukuran 32px):
      Step 1: bg bluePrimaryLight, teks bluePrimaryNormal
      Step 2: bg blueSecondaryLight, teks blueSecondaryNormal
      Step 3: bg yellowAccentLight, teks orangeNormal
      Step 4: bg successLight, teks success
  - Judul (SemiBold 13px)
  - Deskripsi (caption, 11px)
```

#### Ticket Tier Card

```
Radius     : 12px
Background : #FFFFFF
Border-left: 4px solid [warna tier] - lihat tier colors
Structure  :
  - Header row: nama tier (SemiBold, warna tier) + badge "Seating" (outline kecil)
  - Bullet list fitur (bodySmall)
  - Batas waktu (caption, ikon clock.svg)
  - Harga (SemiBold 16px, #1A1A1A)
  - Counter row (- angka +) atau badge "Habis" (bg abu, teks abu)
State Habis:
  - Overlay semi-transparan di card
  - Badge "Habis" (bg #E5E7EB, teks #9CA3AF) menggantikan counter
```

#### Payment Method Card

```
Radius     : 12px
Background : #FFFFFF
Border     : 1.5px #E5E7EB
Structure  :
  - Row: Radio button + Logo SVG bank/ewallet + Nama metode
Selected   :
  - Border berubah 2px bluePrimaryNormal
  - Background blueSecondaryLight (#E9F5FF)
  - Radio filled bluePrimaryNormal
```

---

### 4.4 Bottom Navigation

```
Height     : 64px
Background : #FFFFFF
Shadow     : 0 -2px 8px rgba(0,0,0,0.06)
Tabs       : Beranda | Tiket Saya | Akun
Icon size  : 24x24px (SVG)
Label      : Poppins Medium 11px

Active tab :
  - Icon color : bluePrimaryNormal
  - Label color: bluePrimaryNormal
  - Indicator  : tidak ada dot/background tambahan (clean)

Inactive tab:
  - Icon color : #9CA3AF
  - Label color: #9CA3AF
```

```dart
// SVG icon untuk bottom nav
BottomNavigationBarItem(
  icon: SvgPicture.asset('assets/icons/home.svg',
    width: 24, height: 24,
    colorFilter: ColorFilter.mode(AppColors.textHint, BlendMode.srcIn)),
  activeIcon: SvgPicture.asset('assets/icons/home.svg',
    width: 24, height: 24,
    colorFilter: ColorFilter.mode(AppColors.bluePrimaryNormal, BlendMode.srcIn)),
  label: 'Beranda',
)
```

---

### 4.5 Dialogs & Popups

#### Dialog - Konfirmasi Pembayaran ("Sudah Melakukan Pembayaran?")

```
Trigger    : Tap "Konfirmasi Pembayaran" di halaman VA
Shape      : RoundedRectangleBorder radius 20px
Background : #FFFFFF
Content    :
  - Ikon dollar_circle.svg (SVG, 56x56px, bg bluePrimaryLight circle)
  - Judul: "Sudah Melakukan Pembayaran?" (SemiBold 18px, center)
  - Body: instruksi nominal transfer (Regular 13px, center, textSecondary)
  - Dua tombol berdampingan:
      Kiri  : "Coba Lagi" (outlined, border abu)
      Kanan : "Ya, Sudah Bayar" (primary button biru)
```

#### Dialog - Pembayaran Berhasil

```
Trigger    : Konfirmasi bayar berhasil
Shape      : RoundedRectangleBorder radius 20px
Background : #FFFFFF
Content    :
  - Ikon check.svg (SVG, 56x56px, bg successLight circle, warna success)
  - Judul: "Pembayaran Berhasil" (SemiBold 18px, center)
  - Body: info tiket dikirim ke email / halaman Tiket Saya (Regular 13px, center)
  - Info box (bg #F9FAFB, radius 8px):
      - Email pengguna (SemiBold 13px, center)
      - Transaction ID (Regular 12px, center, textSecondary)
  - Tombol "Lihat Tiket Saya" (green button, full width)
```

#### Countdown Timer Widget

```
Muncul di  : Header halaman Metode Pembayaran dan Konfirmasi Pembayaran
Style      : Row ikon clock.svg + "Sisa waktu" + angka merah bold
Format     : MM:SS
Warna      : merah (#EF4444) saat < 1 menit, normal abu saat > 1 menit
Aksi       : Auto-cancel order jika timer habis
```

---

### 4.6 FAQ Accordion

```
Structure per item :
  - Row: pertanyaan (SemiBold 13px) + chevron_down.svg / chevron_up.svg (SVG)
  - Animated expand/collapse
  - Jawaban di dalam: Regular 13px, textSecondary, padding 12px
  - Divider antar item

Background item   : #FFFFFF
Radius            : 12px
Shadow            : elevationSm
Margin antar item : 8px
```

---

### 4.7 Step Indicator (Cara Beli Tiket)

```
Layout  : GridView 2x2
Padding : 16px
Gap     : 12px antar card

Step warna badge circle:
  1 - Biru   : bg bluePrimaryLight, teks bluePrimaryNormal
  2 - Biru   : bg blueSecondaryLight, teks blueSecondaryNormal (badge aktif lebih gelap)
  3 - Kuning : bg yellowAccentLight, teks orangeNormal
  4 - Hijau  : bg successLight, teks success

Setiap card: lihat Card Step (4.3)
```

---

### 4.8 Ticket Tier Card

Lihat Section 4.3 - Ticket Tier Card.

Counter widget:

```dart
Row(
  children: [
    IconButton(icon: Icon(Icons.remove), onPressed: decrement),
    Text('$count', style: AppTextStyles.headingSmall),
    IconButton(icon: Icon(Icons.add), onPressed: increment),
  ],
)
// Minimum 0, maximum sesuai stok tersedia
```

---

### 4.9 Payment Method Item

Lihat Section 4.3 - Payment Method Card.

Grouping:

```
Grup 1: E-Wallet
  - OVO, DANA, GoPay, ShopeePay

Grup 2: Virtual Account
  - BRI Virtual Account
  - BCA Virtual Account
  - BNI Virtual Account
  - Mandiri Virtual Account

Grup 3: PayLater & Digital Bank
  - Akulaku
  - Allobank
```

Header grup: `Text(nama_grup, style: AppTextStyles.labelMedium)` dengan padding bawah 8px.

---

## 5. Screens

### 5.1 Splash & Onboarding

#### Splash Screen 1 (Initial)

```
Background : AppColors.background (#FFFDE7)
Content    : Kosong (loading state app)
Duration   : 500ms lalu transisi ke Splash 2
```

#### Splash Screen 2 (Logo)

```
Background : AppColors.background
Content    : Logo "Ticketly" centered (SVG / PNG asset)
Logo size  : 120x120px
Duration   : 1500ms lalu ke onboarding jika first-time, atau Home jika sudah login
```

#### Onboarding Pages (3 halaman)

```
Layout     : PageView dengan background gelap (foto konser + gradient overlay)
Gradient   : LinearGradient dari transparan (atas) ke rgba(0,0,0,0.8) (bawah)

Elemen tiap halaman:
  - Foto konser full-screen background
  - Gradient overlay bawah
  - Teks judul (Poppins Bold 26px, putih)
  - Teks deskripsi (Regular 13px, putih 80%)
  - Dot indicator: 3 dots, active = putih solid, inactive = putih 40%
  - Tombol "Lewati" (text button, top right, putih)
  - Halaman 3: Tambah tombol "Masuk" (Primary Button, full width)

Konten:
  Halaman 1: "Selamat Datang di Dunia Musikmu!"
             "Temukan konser impian dan rasakan energi panggung yang tak terlupakan."
  Halaman 2: "Dapatkan Tiket Konser Artis Favoritmu Sekarang!"
             "Pesan tiket resmi dan nikmati pengalaman menonton tanpa khawatir."
  Halaman 3: "Rasakan Getaran Musik, Langsung dari Panggung!"
             "Bergabunglah bersama ribuan penonton dan buat momen berharga tak terlupakan."
             + Tombol "Masuk" -> Auth Screen
```

---

### 5.2 Auth Screens

Semua auth screen background: `AppColors.background`

#### Masuk (Login)

```
Layout (atas ke bawah):
  - Judul "Masuk" (displayMedium, center)
  - Subjudul (bodyMedium, textSecondary, center)
  - Spacer 32px
  - Field: Email
  - Field: Kata Sandi (password + eye toggle SVG)
  - Align right: "Lupa Kata Sandi?" (linkText)
  - Primary Button "Masuk"
  - Divider "Masuk dengan"
  - Row SSO: facebook.svg | google.svg | apple.svg (masing-masing 48x48px, circle border)
  - Footer: "Belum memiliki Akun? Daftar" (linkText)
```

#### Daftar (Register)

```
Layout:
  - Judul "Daftar"
  - Subjudul
  - Field: Email
  - Field: Nama Pengguna
  - Field: Kata Sandi (password)
  - Field: Konfirmasi Kata Sandi (password)
  - Primary Button "Daftar"
  - Divider "Daftar dengan"
  - Row SSO
  - Footer: "Sudah memiliki Akun? Masuk"
```

#### Lupa Kata Sandi

```
Layout:
  - Judul "Lupa Kata Sandi"
  - Subjudul
  - Ilustrasi: shield_key.svg (SVG, 180x180px, center)
  - Field: Email
  - Primary Button "Konfirmasi Email"
```

#### Verifikasi Kode

```
Layout:
  - Judul "Verifikasi Kode"
  - Subjudul
  - Ilustrasi: shield_lock.svg (SVG, 180x180px, center)
  - OTP Input: 6 kotak (lihat 4.2)
  - Primary Button "Konfirmasi Kode"
```

#### Kata Sandi Baru

```
Layout:
  - Judul "Kata Sandi Baru"
  - Subjudul
  - Field: Kata Sandi (password + eye toggle)
  - Field: Konfirmasi Kata Sandi (password + eye toggle)
  - Primary Button "Konfirmasi Kata Sandi"
```

---

### 5.3 Beranda (Home)

```
Scaffold:
  appBar: Custom (tidak pakai default AppBar)
  body   : SingleChildScrollView
  bottomNavigationBar: AppBottomNav (active: Beranda)
```

#### Header

```
Padding    : 16px horizontal, 16px top
Row        :
  Left : Column
    - "Hallo, Selamat Datang" (bodyMedium, textSecondary)
    - "[Nama User]" (headingMedium)
  Right: CircleAvatar 40px (foto profil)
```

#### Hero Banner Carousel

```
Height     : 180px
Radius     : 16px
Margin     : 16px horizontal
Content    : Image event + overlay gradient + teks nama event + tombol "Lihat Detail & Beli Tiket"
Dots       : bawah carousel, putih
Auto-play  : 4 detik
```

#### Search Bar

```
Margin     : 16px
Radius     : 999px (pill)
Background : #FFFFFF
Border     : 1.5px #E5E7EB
Leading    : search.svg SVG 20px
Placeholder: "Cari berdasarkan artis, lokasi, atau event..."
OnTap      : navigasi ke Search Screen
```

#### Section Template

Semua section menggunakan pola:

```
Padding    : 16px horizontal
Header row :
  - Judul section (headingSmall, left)
  - "Lihat Semua >" (linkText, right) -> navigasi ke list screen
Content    : SingleChildScrollView horizontal, spacing 12px antar card
```

Sections:
- "Konser Terbaru" -> EventCard horizontal scroll
- "Festival Seru" -> EventCard horizontal scroll
- "Event Lainnya" -> EventCard horizontal scroll

#### Promo Banner

```
Margin     : 16px
Radius     : 16px
Background : gradient bluePrimaryNormal -> purpleNormal
Content    :
  - Badge "Flash Discount" (kuning)
  - "Payday Sale! Diskon 20%" (Bold 16px, putih)
  - Subjudul (putih 80%)
  - Tombol "Cek Promo Sekarang" (outlined putih, pill)
```

#### Cara Beli Tiket

```
Judul      : "Cara Beli Tiket" (headingMedium)
Subjudul   : "Dapatkan tiketmu hanya dalam hitungan menit."
Layout     : GridView 2x2 (lihat Step Indicator 4.7)
```

#### FAQ

```
Judul      : "Pertanyaan Populer"
Layout     : Column accordion (lihat FAQ Accordion 4.6)
Items      :
  1. Bagaimana cara menerima tiket setelah bayar?
  2. Apakah tiket bisa dipindahtangankan ke orang lain?
  3. Saya sudah bayar tapi belum terima tiket di Email ataupun Tiket Saya?
  4. Apakah E-Tiket perlu dicetak (print)?
```

#### Newsletter

```
Background : gradient bluePrimaryLight
Radius     : 16px
Content    :
  - Judul "Jangan Ketinggalan Info Konser!"
  - Subjudul
  - Row: TextField email + Tombol "Berlangganan"
```

#### Why Ticketly

```
Judul      : "Kenapa Beli di Ticketly"
Layout     : Row 3 item dengan ikon SVG masing-masing
Items      :
  - "Transaksi 100% Aman" (shield.svg)
  - "E-Tiket Instan" (ticket.svg)
  - "Bantuan 24/7" (headset.svg)
```

---

### 5.4 Konser / Festival / Event List

```
Scaffold:
  appBar : Back chevron_left.svg + judul ("Konser" / "Festival" / "Event")
  body   : GridView 2 kolom, padding 16px, spacing 12px
  item   : EventCard (full col-width)
```

---

### 5.5 Event Detail

#### Tab 1: Info Event

```
Layout: CustomScrollView dengan SliverAppBar (hero image collapsible)

Hero image    : Full width, height 240px
Back button   : chevron_left.svg SVG putih, bg rgba hitam bulat

Content (scroll):
  - Judul event (headingLarge)
  - Row: calendar.svg + tanggal
  - Row: clock.svg + waktu
  - Row: location_pin.svg + lokasi
  - Badge "Sedang Berlangsung" (bg successLight, teks success, pill, ikon badge_live.svg)
  - Deskripsi panjang (bodyMedium, expandable)
  - Seat map image (rounded 12px)
  - "Ketentuan Umum" (headingSmall)
  - Bullet list ketentuan (bodySmall)
  - Sticky bottom: Primary Button "Beli Tiket Sekarang"
```

#### Tab 2: Pilih Tiket (setelah tap "Beli Tiket Sekarang")

```
AppBar     : Judul "Detail Konser" + back
Body       : ListView tier cards (lihat Ticket Tier Card 4.3)
Sticky bottom:
  - "Total Estimasi" + harga (SemiBold biru)
  - Primary Button "Pesan Sekarang" (disabled jika total = 0)
```

---

### 5.6 Checkout Flow

Flow navigasi: **Syarat & Ketentuan -> Metode Pembayaran -> Konfirmasi Pesanan -> Konfirmasi Pembayaran**

#### Progress Stepper (Header checkout)

```
Tampil di  : semua halaman checkout
Style      : Row 4 step dengan ikon SVG + label
Active     : warna bluePrimaryNormal, lingkaran solid
Inactive   : warna abu, lingkaran outline
Connector  : garis horizontal antara step
Steps      : Pembayaran | Metode Bayar | Cek Pesanan | Konfirmasi
```

#### Halaman 1: Syarat & Ketentuan

```
AppBar     : "Syarat & Ketentuan" + back
Body       :
  - Bullet list syarat (bodySmall)
  - Checkbox: "Klik Untuk Melanjutkan" dengan link S&K dan Kebijakan Privasi
  - Primary Button "Lanjut" (disabled sampai checkbox dicentang)
```

#### Halaman 2: Metode Pembayaran

```
AppBar     : "Metode Pembayaran" + back + stepper
Header     : Countdown timer (lihat 4.5)
Body       :
  - Section "E-Wallet" + list payment cards
  - Section "Virtual Account" + list
  - Section "PayLater & Digital Bank" + list
Footer     :
  - Primary Button "Lanjut"
  - Outlined Button "Batal"
```

#### Halaman 3: Konfirmasi Pesanan

```
AppBar     : "Konfirmasi Pesanan" + back + stepper
Body       :
  - Event thumbnail + nama event
  - Info: tanggal, waktu, lokasi (row dengan SVG ikon)
  - "Tiket yang Dipesan": list tier x jumlah x harga
  - "Data Diri": nama, email, telepon, nomor identitas
  - "Rincian Biaya":
      - Subtotal tiket
      - PPN 10%
      - Biaya Admin
      - Biaya Platform
      - Total Bayar (Bold biru, lebih besar)
  - "Metode Pembayaran": nama metode terpilih (linkText -> edit)
Footer     :
  - Primary Button "Lanjut"
  - Outlined Button "Batal"
```

#### Halaman 4: Konfirmasi Pembayaran

```
AppBar     : "Konfirmasi Pesanan" + back + stepper
Body       :
  - Event thumbnail + nama event
  - Countdown "Masih ada waktu untuk menyelesaikan pembayaran" + timer merah
  - Deadline pembayaran (caption)
  - Warning: auto-cancel jika timer habis
  - Metode pembayaran + logo SVG
  - Nomor VA + tombol copy (copy.svg)
  - Total Pembayaran (Bold biru besar)
  - Detail Pesanan: Order ID, Tanggal Event, Range waktu
  - Primary Button "Konfirmasi Pembayaran" -> trigger Dialog Konfirmasi
  - Outlined Danger "Batalkan Pesanan"
  - "Instruksi Pembayaran" (numbered list, 5 langkah)
```

---

### 5.7 My Ticket

```
Scaffold:
  appBar  : "My Ticket" (headingLarge, no back)
  body    : ListView ticket cards (lihat My Ticket Card 4.3)
  bottomNav: active Tiket Saya
```

#### Detail E-Tiket (modal/screen)

```
Trigger    : Tap "Lihat Tiket"
Layout     : SafeArea, background AppColors.background
Content    :
  - E-Tiket Card (lihat 4.3)
  - Tombol share/download (opsional)
```

---

### 5.8 Akun & Edit Profile

#### Halaman Akun

```
Scaffold:
  appBar     : "Akun" (headingLarge, no back)
  body       :
    - Header biru: CircleAvatar 100px + nama (headingMedium putih) + email (bodySmall putih)
    - Menu list (ListTile style):
        1. edit_pencil.svg + "Edit Name Profil" + chevron_right.svg
        2. lock.svg + "Ubah Kata Sandi" + chevron_right.svg
        3. settings_gear.svg + "Pengaturan" + chevron_right.svg
        4. logout.svg (merah) + "Keluar" (merah) + chevron_right.svg
    - Background menu item: #FFFFFF, radius 12px, margin 8px horizontal
  bottomNav  : active Akun
```

#### Halaman Edit Profile

```
AppBar     : back (chevron_left.svg) + "Edit Profile"
Body       :
  - "Ganti Foto" (labelMedium)
  - Row: CircleAvatar + Tombol "Pilih File" (outlined pill kecil) + "Tidak ada file yang dipilih"
  - Field: Nama Pengguna
  - Field: Email
  - Primary Button "Simpan Perubahan"
```

#### Form Data Diri (saat checkout)

```
Fields     :
  - Nama Lengkap *
  - Nama (displayed filled)
  - Nomor Telepon *
  - Nomor Identitas *
  - Tanggal Lahir * (DatePicker, format DD/MM/YYYY, ikon calendar.svg)
  - Radio Iya/Tidak per pertanyaan boolean
  - Checkbox Syarat & Ketentuan (linkText biru) + Kebijakan Privasi (linkText biru)
  - Checkbox Kebijakan Pemrosesan Data Pribadi (linkText biru)
Footer     :
  - Primary Button "Lanjut"
  - Outlined Button "Batal"
```

---

## 6. Navigation Structure

```
App
├── Splash (initial route)
│   └── Onboarding (first time)
│       └── Auth
│           ├── Login
│           ├── Register
│           └── Forgot Password
│               ├── Verify OTP
│               └── New Password
└── Main Shell (BottomNav)
    ├── Tab 0: Beranda
    │   ├── Search Screen
    │   ├── Konser List (Lihat Semua)
    │   ├── Festival List (Lihat Semua)
    │   ├── Event List (Lihat Semua)
    │   └── Event Detail
    │       └── Checkout Flow (4 halaman)
    │           └── Popup Konfirmasi Bayar
    │               └── Popup Pembayaran Berhasil
    │                   └── [redirect ke Tab 1]
    ├── Tab 1: Tiket Saya
    │   └── E-Tiket Detail
    └── Tab 2: Akun
        ├── Edit Profile
        └── Ubah Kata Sandi
```

---

## 7. State & Interaction Notes

### Global State

| State | Keterangan |
|-------|-----------|
| `isLoggedIn` | Routing ke onboarding vs home |
| `currentUser` | Nama, email, foto profil |
| `cartItems` | Tier tiket yang dipilih (list) |
| `selectedPaymentMethod` | Metode pembayaran terpilih |
| `checkoutTimer` | Countdown 5 menit, auto-cancel |

### Interaksi Penting

1. **Tier counter** - min 0, jika semua 0 maka tombol "Pesan Sekarang" disabled
2. **Checkout timer** - mulai saat masuk halaman Metode Pembayaran, persist sampai halaman 4
3. **OTP resend** - tambahkan tombol "Kirim Ulang" dengan cooldown 60 detik
4. **VA number copy** - pakai `Clipboard.setData`, tampilkan SnackBar "Disalin"
5. **QR Code** - generate menggunakan package `qr_flutter`
6. **Image picker** - edit profile menggunakan `image_picker` package
7. **FAQ accordion** - gunakan `ExpansionTile` Flutter built-in, kustomisasi ikon dengan SVG
8. **Hero carousel** - gunakan `carousel_slider` package, interval 4000ms
9. **Onboarding PageView** - `PageController`, tombol Lewati skip ke Auth
10. **Password visibility toggle** - `ValueNotifier<bool>` per field

### Packages yang Diperlukan

```yaml
dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.2.0          # Poppins
  flutter_svg: ^2.0.0           # Semua ikon SVG
  carousel_slider: ^5.0.0       # Hero banner
  qr_flutter: ^4.1.0            # QR code e-tiket
  image_picker: ^1.1.0          # Upload foto profil
  go_router: ^14.0.0            # Navigasi
  provider: ^6.1.0              # State management (atau gunakan Riverpod/BLoC)
  intl: ^0.19.0                 # Format tanggal & mata uang
  pinput: ^5.0.0                # OTP input field yang clean
```

---

## Appendix: Asset Directory Structure

```
assets/
├── icons/
│   ├── home.svg
│   ├── ticket.svg
│   ├── person.svg
│   ├── search.svg
│   ├── calendar.svg
│   ├── clock.svg
│   ├── location_pin.svg
│   ├── chevron_right.svg
│   ├── chevron_down.svg
│   ├── chevron_left.svg
│   ├── eye.svg
│   ├── eye_off.svg
│   ├── edit_pencil.svg
│   ├── lock.svg
│   ├── settings_gear.svg
│   ├── logout.svg
│   ├── check.svg
│   ├── dollar_circle.svg
│   ├── copy.svg
│   ├── facebook.svg
│   ├── google.svg
│   ├── apple.svg
│   ├── shield_key.svg
│   ├── shield_lock.svg
│   ├── info_circle.svg
│   ├── badge_live.svg
│   ├── notification_bell.svg
│   ├── shield.svg
│   ├── headset.svg
│   └── payment/
│       ├── ovo.svg
│       ├── dana.svg
│       ├── gopay.svg
│       ├── shopeepay.svg
│       ├── bri.svg
│       ├── bca.svg
│       ├── bni.svg
│       ├── mandiri.svg
│       ├── akulaku.svg
│       └── allobank.svg
├── images/
│   ├── logo_ticketly.png
│   ├── onboarding_1.jpg
│   ├── onboarding_2.jpg
│   ├── onboarding_3.jpg
│   └── placeholder_event.png
└── fonts/ (opsional, jika tidak pakai google_fonts)
```

---

*Dokumen ini dibuat berdasarkan desain Figma Ticketly v1.0*
*Last updated: Mei 2026*
*Dibuat untuk implementasi Flutter - Proyek Ticketly PNC*
