# 📱 Ticketly Mobile

**Ticketly Mobile** is a cross-platform mobile application built using **Flutter (Dart)** that serves as the client interface for the **Ticketly** event ticketing system. 

It connects to the **CodeIgniter 4 (PHP 8.1+) Backend RESTful API** to deliver a seamless event discovery and ticket purchasing experience on mobile devices.

> This project is the mobile companion to the Ticketly event platform, built as a college project at **Politeknik Negeri Cilacap**, Informatics Engineering Department.

---

[![Flutter](https://img.shields.io/badge/Flutter-3.11+-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![CodeIgniter](https://img.shields.io/badge/API_Integration-CodeIgniter_4-EE4326?style=for-the-badge&logo=codeigniter&logoColor=white)](https://codeigniter.com)

---

## Table of Contents

- [Key Features](#key-features)
- [Tech Stack & Dependencies](#tech-stack--dependencies)
- [Requirements](#requirements)
- [Folder Structure](#folder-structure)
- [Local Setup & Configuration](#local-setup--configuration)
- [API Integration & Documentation (Scalar)](#api-integration--documentation-scalar)
- [How to Run](#how-to-run)
- [UI/UX Design](#uiux-design)
- [Team](#team)
- [License](#license)

---

## Key Features

### 🔐 Authentication & Session
- **Registration & Login**: Stateless authentication using a custom JWT. The token is stored locally using `shared_preferences`.
- **Password Recovery (OTP)**: Fully integrated flow to request and verify a 6-digit OTP code via email, allowing users to securely reset their password.
- **Session Management**: Automatically detects login status when the application is opened.
- **Logout**: Safely clears the local token and user details cache.

### 🎟️ Event Discovery
- **Hero Banner / Featured Events**: Dynamically showcases selected events at the top of the homepage.
- **Event Categories**: Filters events by category (e.g., *Concert*, *Festival*, *Show*, etc.).
- **Search & Event Details**: Comprehensive details of the event, date, venue, seatmap, and ticket types with real-time remaining quota.

### 🛒 Checkout Flow
- **Cart Calculation**: Real-time calculation of ticket subtotal, admin fees, and grand total.
- **Start Checkout**: Temporarily reserves and locks ticket quotas during checkout.
- **Payment Confirmation**: Allows users to upload a proof of payment image to be verified by the admin.
- **Cancel Booking**: Permits users to cancel an active booking or automatically expires unpaid bookings.

### 🎟️ My Tickets & Order History
- **Order History**: Displays past transactions along with checkout/payment status (`pending`, `completed`, `cancelled`, `expired`).
- **E-Ticket Details**: Displays successfully purchased tickets with barcode/QR code mockups for check-in validation.
- **Pull-to-Refresh & Posters**: Pull-to-refresh mechanism to reload tickets, displaying dynamic concert poster images from the backend.

---

## Tech Stack & Dependencies

**Core Framework & Libraries**
- **Flutter SDK**: `^3.11.0` (Dart `^3.x`)
- **Google Fonts**: `^8.1.0` (Using the **Poppins** font family globally)
- **HTTP Client**: `http ^1.2.0` (For stateless communication with the CI4 REST API)
- **Local Storage**: `shared_preferences ^2.2.0` (For caching JWT auth tokens & user profiles)
- **SVG Vector Rendering**: `flutter_svg ^2.3.0` (For rendering local vector graphics offline)

---

## Requirements

Before running the Ticketly Mobile app, ensure that you meet the following requirements:
- **Flutter SDK** version `3.11.0` or higher.
- **Android Studio** (Android Emulator) or **Xcode** (iOS Simulator) installed and configured.
- A running instance of the **Ticketly Backend (CodeIgniter 4)** (either locally via `php spark serve` or hosted).

---

## Folder Structure

This application is built using a clean, modular structure for easy code maintenance. Here is the layout of the project, showing the key directories:

```text
ticketly/
├── assets/                     # Media and graphics resources
│   ├── icons/                  # SVG icons (e.g., google.svg)
│   └── images/                 # App logos, onboarding screens, and illustrations
├── lib/                        # Core application source code
│   ├── constants/              # Global app configuration & API paths
│   ├── data/                   # Client-side static & mock data
│   ├── extensions/             # (Placeholder) Extension methods on Dart/Flutter types
│   ├── models/                 # Data transfer object models mapped from JSON responses
│   ├── providers/              # (Placeholder) State management files (e.g., ChangeNotifiers)
│   ├── screens/                # UI screens and navigation pages
│   ├── service/                # Business logic integration & HTTP services
│   ├── theme/                  # Global styling, themes, colors, and font styles
│   ├── utils/                  # (Placeholder) Global utility methods
│   └── widgets/                # Reusable UI widgets and layout modules
├── pubspec.yaml                # Flutter project package dependencies & assets mapping
└── README.md                   # Project documentation (this file)
```

---

## Local Setup & Configuration

### 1. Clone & Fetch Dependencies
Clone the repository, navigate into the directory, and download dependencies:

```bash
git clone https://github.com/pratama1246/ticketly.git
cd ticketly
flutter pub get
```

### 2. Configure API Base URL
To connect the Flutter application with the CodeIgniter 4 backend, check the configuration in [api_constants.dart](file:///home/pputra/Documents/Project-Web/ticketly/lib/constants/api_constants.dart).

The application dynamically detects the running platform so you do not have to manually edit the host IP address:

```dart
// lib/constants/api_constants.dart
static String get baseUrl {
  if (kIsWeb) {
    return 'http://localhost:8080';
  }
  if (Platform.isAndroid) {
    // 10.0.2.2 is a special loopback address to reach localhost on the host machine from the Android emulator
    return 'http://10.0.2.2:8080'; 
  }
  return 'http://localhost:8080'; // iOS Emulator / Mac
}
```

*Ensure your CI4 backend is running on port `8080` (default for `php spark serve`). If you use a custom port or live production URL, adjust this file accordingly.*

---

## API Integration & Documentation (Scalar)

The mobile client consumes REST API endpoints from the **Ticketly Backend (CodeIgniter 4)**. To run this project fully, you need the backend server running.

* **Backend CI4 Repository:** [ticketly-project](https://github.com/pratama1246/ticketly-project)
* **Interactive API Docs (Scalar):** When the CI4 backend is running locally, you can view interactive API documentation, request/response schemas, try out endpoints, and generate client integration code (e.g. Dart/curl):
  👉 **[http://localhost:8080/api/docs](http://localhost:8080/api/docs)**

### API Endpoints Consumed:

| Method | Endpoint | Auth | Description |
|---|---|---|---|
| **Auth** | | | |
| `POST` | `/api/auth/register` | Public | Register a new account |
| `POST` | `/api/auth/login` | Public | Login & receive custom JWT token |
| `POST` | `/api/auth/logout` | JWT | Logout & terminate authentication session |
| `POST` | `/api/auth/forgot-password` | Public | Request an OTP reset code via email |
| `POST` | `/api/auth/verify-code` | Public | Verify the 6-digit security OTP code |
| `POST` | `/api/auth/reset-password` | Public | Set new password using verified OTP code |
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

> 🔒 **JWT Auth**: Endpoints marked with **JWT** require an `Authorization: Bearer <token>` header containing the saved JWT token.

### 🔑 Default Testing Credentials

To log in and test the application, ensure the CI4 backend seeders have been run and use these credentials:

#### Administrator
- **Email:** `admin@ticketly.com`
- **Username:** `admin`
- **Password:** `admin123`

#### Mock Users (Customer)
- `budi@example.com` / `password123` (username: `budi_santoso`)
- `ani@example.com` / `password123` (username: `ani_wijaya`)
- `dewi@example.com` / `password123` (username: `dewi_sari`)
- `rudi@example.com` / `password123` (username: `rudi_hermawan`)

---

## How to Run

Run the following command in your terminal to launch the application on a connected device or emulator:

```bash
# Check connected devices
flutter devices

# Run the app (select target device if multiple are connected)
flutter run
```

---

## 🎨 UI/UX Design

Ticketly follows a design-first workflow using Figma with the following style guide:
- **Primary Colors**: Cream/Soft Yellow (`0xFFFFFDE7`) for a clean and modern canvas, paired with **Blue Primary** (`0xFF072AC8`) for main interaction elements.
- **Typography**: Uses the **Poppins** typeface with varying font weights (Medium, Semi-Bold, Bold) to create a clear informational hierarchy.
- **Interactions**: Smooth screen transitions and micro-animations on interactive elements to improve navigation comfort.

---

## 👥 Team

- **Hana**
- **Tama**
- **Jihan**

This project was built as a college project at **Politeknik Negeri Cilacap**, Informatics Engineering Department.

---

## License

This project is licensed under the [MIT License](LICENSE).

---

## ⚠️ Disclaimer

All event logos, promoter names, and concert posters featured in the screenshots and seed database of this project belong to their respective copyright owners (official promoters/events). They are used purely for educational and academic demonstration purposes to simulate a realistic ticketing catalog.

---

[![GitHub](https://img.shields.io/badge/GitHub-pratama1246-black?logo=github)](https://github.com/pratama1246)
