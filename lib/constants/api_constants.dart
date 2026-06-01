import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConstants {
  ApiConstants._();

  // Memilih Base URL secara dinamis sesuai platform running
  static String get baseUrl {
    if (kIsWeb) {
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
