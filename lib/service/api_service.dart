import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/event_model.dart';
import '../widgets/hero_banner.dart';

class ApiService {
  static final http.Client _client = http.Client();

  // Helper untuk normalisasi URL poster_image dari API.
  // Jika baseURL mengandung localhost, dan kita di Android emulator (10.0.2.2),
  // kita perlu me-replace http://localhost:8080 dengan http://10.0.2.2:8080
  static String normalizeImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    if (ApiConstants.baseUrl.contains('10.0.2.2') && rawUrl.contains('localhost:8080')) {
      return rawUrl.replaceAll('localhost:8080', '10.0.2.2:8080');
    }
    return rawUrl;
  }

  // Fetch Featured Events -> Hero Banner
  static Future<List<HeroBannerItem>> fetchFeaturedEvents() async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConstants.baseUrl}${ApiConstants.featuredEvents}'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['status'] == 'success' && decoded['data'] != null) {
          final List dataList = decoded['data'];
          return dataList.map((item) {
            final poster = normalizeImageUrl(item['poster_image']);
            final name = item['name'] ?? '';
            final category = item['category'] ?? '';
            final venue = item['venue'] ?? '';
            
            String dateVenueStr = venue;
            try {
              final rawDate = item['event_date'];
              if (rawDate != null) {
                final parsedDate = DateTime.parse(rawDate);
                dateVenueStr = "${formatIndonesianDate(parsedDate)} • $venue";
              }
            } catch (_) {}

            return HeroBannerItem(
              imageUrl: poster,
              eventName: name,
              category: category,
              dateVenue: dateVenueStr,
            );
          }).toList();
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetchFeaturedEvents: $e');
    }
    return [];
  }

  // Fetch Events by Category -> EventCard List
  static Future<List<EventModel>> fetchEventsByCategory(String category) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.listEvents}').replace(
        queryParameters: {
          'category': category,
          'limit': '10',
        },
      );
      final response = await _client.get(uri).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['status'] == 'success' && decoded['data'] != null) {
          final List dataList = decoded['data'];
          return dataList.map((item) {
            final itemCopy = Map<String, dynamic>.from(item);
            itemCopy['poster_image'] = normalizeImageUrl(item['poster_image']);
            return EventModel.fromJson(itemCopy);
          }).toList();
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetchEventsByCategory: $e');
    }
    return [];
  }
}
