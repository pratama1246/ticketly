# 🎟️ Ticketly Mobile (PNC)

**Ticketly Mobile** is the cross-platform mobile client application built using **Flutter (Dart)** that integrates with the **CodeIgniter 4 (PHP 8.1+) RESTful API** to deliver a seamless event discovery and ticket purchasing experience.

> Built as a college project at **Politeknik Negeri Cilacap**, Informatics Engineering Department.

---

[![Flutter](https://img.shields.io/badge/Flutter-3.11+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![CodeIgniter](https://img.shields.io/badge/API_Integration-CodeIgniter_4-EE4326?style=for-the-badge&logo=codeigniter&logoColor=white)](https://codeigniter.com)
[![Google Fonts](https://img.shields.io/badge/Font-Poppins-FF5722?style=for-the-badge&logo=googlefonts&logoColor=white)](https://fonts.google.com/specimen/Poppins)

---

## Table of Contents

- [Key Features](#key-features)
- [Tech Stack](#tech-stack)
- [Requirements](#requirements)
- [Folder Structure](#folder-structure)
- [Local Setup](#local-setup)
- [REST API Endpoints](#rest-api-endpoints)
- [Run the App](#run-the-app)
- [UI/UX Design](#uiux-design)
- [Team](#team)
- [License](#license)
- [Disclaimer](#disclaimer)

---

## Key Features

### Authentication & Profile

- Custom registration for mobile users
- Login & logout (securing custom JWT)
- Forgot password request (OTP via email) & secure password reset
- View and manage user transaction records
- Stateless JWT authentication filter injection

### Mobile API (Flutter Integration)

- Home banner/landing events & featured events
- Event category filtering (Concerts, Festivals, Shows)
- Detailed event information, ticket categories, & remaining ticket quota
- Real-time shopping cart (cart) calculation
- Booking transactions (start checkout, upload proof of payment/confirm, cancel booking)
- Dynamic and clean webp event poster images
- Pull-to-refresh list update mechanism

---

## Tech Stack

**Mobile Client**

- Flutter SDK `^3.11.0` (Dart `^3.x`)
- Google Fonts `^8.1.0` (Poppins font family globally)
- HTTP Client: `http ^1.2.0` (for REST API requests)
- Local Storage: `shared_preferences ^2.2.0` (for JWT & user session cache)
- SVG Vector Rendering: `flutter_svg ^2.3.0` (for local vector graphics)

**Backend Integration**

- CodeIgniter Framework `^4.0` (PHP 8.1+)
- Custom JWT Auth (`firebase/php-jwt`)

---

## Requirements

- Flutter SDK version **3.11.0** or higher
- Android Studio (Android Emulator) or Xcode (iOS Simulator)
- Running instance of the **Ticketly Backend (CodeIgniter 4)** (locally or hosted)

---

## Folder Structure

```text
lib/
  ├── constants/    # App constants (API endpoints, asset paths)
  ├── data/         # Mock data & internal application data
  ├── extensions/   # Flutter & Dart extensions and helpers
  ├── models/       # Data models mapped from JSON API responses
  ├── screens/      # Main UI screens (Splash, Onboarding, Home, Checkout, etc.)
  ├── service/      # Service layer for API & Auth logic (ApiService & AuthService)
  ├── theme/        # App styling, color palettes, fonts, and borders (AppTheme)
  ├── utils/        # Utility functions (date formatting, currency formatting, etc.)
  └── widgets/      # Reusable UI components (Custom Buttons, EventCards, HeroBanner)
```

---

## Local Setup

### 1) Clone Repository
```bash
git clone https://github.com/pratama1246/ticketly.git
cd ticketly
```

### 2) Fetch Dependencies
```bash
flutter pub get
```

### 3) Configure API Base URL
The application dynamically detects the platform in [api_constants.dart](lib/constants/api_constants.dart):
```dart
static String get baseUrl {
  if (kIsWeb) return 'http://localhost:8080';
  if (Platform.isAndroid) return 'http://10.0.2.2:8080';
  return 'http://localhost:8080';
}
```

---

## REST API Endpoints

All API endpoints consumed by the Flutter app are prefixed with `/api`. Endpoints protected by the `api_jwt` filter require a valid JWT Bearer token in the `Authorization: Bearer <token>` header.

### Response Format

Returned responses have a consistent JSON structure:

```json
{
  "status": "success" | "error",
  "message": "Response message description.",
  "data": { ... } | [ ... ] | null
}
```

For paginated list data, the response includes a sidecar `meta` object:

```json
{
  "status": "success",
  "message": "...",
  "data": [],
  "meta": {
    "total": 42,
    "per_page": 10,
    "current_page": 1,
    "last_page": 5
  }
}
```

### Endpoint List

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| **Auth** | | | |
| `POST` | `/api/auth/register` | Public | Register a new account |
| `POST` | `/api/auth/login` | Public | Login & receive custom JWT token |
| `POST` | `/api/auth/logout` | JWT | Logout & terminate authentication session |
| `POST` | `/api/auth/forgot-password` | Public | Request password reset verification code (OTP) |
| `POST` | `/api/auth/verify-code` | Public | Validate OTP verification code |
| `POST` | `/api/auth/reset-password` | Public | Update user password with new credentials |
| **Events & Tickets** | | | |
| `GET` | `/api/events` | Public | Get paginated list of events |
| `GET` | `/api/events/featured` | Public | Get featured events list |
| `GET` | `/api/events/landing` | Public | Get events list for the main/landing page |
| `GET` | `/api/events/{slug}` | Public | Event details by slug |
| `GET` | `/api/events/{id}/tickets` | Public | List of ticket categories & quotas per event |
| **Checkout** | | | |
| `GET` | `/api/checkout/payment-methods` | Public | List of available payment methods |
| `POST` | `/api/checkout/calculate` | Public | Calculate cart, subtotal, admin fee, & total |
| `POST` | `/api/checkout/start` | JWT | Start checkout & lock remaining ticket quota |
| `POST` | `/api/checkout/confirm` | JWT | Upload proof of payment / confirm transaction |
| `POST` | `/api/checkout/cancel` | JWT | Cancel booking transaction |
| **Profile & Orders** | | | |
| `GET` | `/api/profile` | JWT | Get current user's profile details |
| `POST` | `/api/profile/update` | JWT | Update current user's profile details |
| `GET` | `/api/orders` | JWT | User order history |
| `GET` | `/api/orders/{id}` | JWT | Specific order transaction details |

---

## Run the App

Launch the application on a connected device or emulator:

```bash
# Check connected devices
flutter devices

# Run the app
flutter run
```

---

## 🎨 UI/UX Design

The interface was designed in Figma before development, following a design-first workflow. The prototype covers user flows for browsing events, ticket purchasing, and account management.

---

## 👥 Team

- **Hana**
- **Tama**
- **Jihan**

Built as a college project at **Politeknik Negeri Cilacap**, Informatics Engineering Department.

**Class:** Teknik Informatika 2D  
**Course:** Pemrograman Web 2 (Mobile Integration)  
**Institution:** Politeknik Negeri Cilacap  

---

## License

This project is licensed under the [MIT License](LICENSE).

---

## ⚠️ Disclaimer

All event logos, promoter names, and concert posters featured in the screenshots and seed database of this project belong to their respective copyright owners (official promoters/events). They are used purely for educational and academic demonstration purposes to simulate a realistic ticketing catalog.

---

[![GitHub](https://img.shields.io/badge/GitHub-pratama1246-black?logo=github)](https://github.com/pratama1246)
