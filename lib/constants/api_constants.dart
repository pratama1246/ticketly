import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  // Memilih Base URL secara dinamis sesuai platform running
  //
  // CATATAN PORT BACKEND:
  //  - Laravel/Laragon (Windows) default port 80  → http://localhost
  //  - php spark serve (Linux/Mac) default port 8080 → http://localhost:8080
  //  - Android Emulator → http://10.0.2.2:8080
  static String get baseUrl {
    if (kIsWeb) {
      // php spark serve default port 8080
      return 'http://localhost:8080';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080';
    }
    return 'http://localhost:8080';
  }

  // Endpoints
  static const String featuredEvents = '/api/events/featured';
  static const String listEvents = '/api/events';
}
