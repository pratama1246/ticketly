import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';
import '../models/event_model.dart';
import '../models/event_detail_model.dart';
import '../widgets/hero_banner.dart';

class ApiService {
  static final http.Client _client = http.Client();

  // Helper untuk normalisasi URL poster_image dari API.
  // Mengubah localhost:8080 secara dinamis ke host & port aktif dari ApiConstants.baseUrl
  static String normalizeImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return '';
    try {
      final baseUri = Uri.parse(ApiConstants.baseUrl);
      final activeAuthority = baseUri.authority; // e.g. "10.0.2.2:8080", "192.168.1.50:8080", "localhost:8080"
      if (rawUrl.contains('localhost:8080')) {
        return rawUrl.replaceAll('localhost:8080', activeAuthority);
      }
    } catch (_) {}
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

  // Fetch Event Detail by Slug
  static Future<EventDetailModel?> fetchEventDetail(String slug) async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConstants.baseUrl}/api/events/$slug'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['status'] == 'success' && decoded['data'] != null) {
          final data = Map<String, dynamic>.from(decoded['data']);
          data['poster_image'] = normalizeImageUrl(data['poster_image']);
          data['seatmap_image'] = normalizeImageUrl(data['seatmap_image']);
          return EventDetailModel.fromJson(data);
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetchEventDetail: $e');
    }
    return null;
  }

  // Fetch Landing Page Data (Featured, Concerts, Festivals, and Events in one request)
  static Future<LandingPageData> fetchLandingPageData() async {
    try {
      final response = await _client
          .get(Uri.parse('${ApiConstants.baseUrl}${ApiConstants.landingEvents}'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['status'] == 'success' && decoded['data'] != null) {
          final data = decoded['data'];

          // Parse Featured
          final List featuredList = data['featured'] ?? [];
          final featured = featuredList.map((item) {
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

          // Parse Concerts
          final List concertsList = data['concerts'] ?? [];
          final concerts = concertsList.map((item) {
            final itemCopy = Map<String, dynamic>.from(item);
            itemCopy['poster_image'] = normalizeImageUrl(item['poster_image']);
            return EventModel.fromJson(itemCopy);
          }).toList();

          // Parse Festivals
          final List festivalsList = data['festivals'] ?? [];
          final festivals = festivalsList.map((item) {
            final itemCopy = Map<String, dynamic>.from(item);
            itemCopy['poster_image'] = normalizeImageUrl(item['poster_image']);
            return EventModel.fromJson(itemCopy);
          }).toList();

          // Parse Events
          final List eventsList = data['events'] ?? [];
          final events = eventsList.map((item) {
            final itemCopy = Map<String, dynamic>.from(item);
            itemCopy['poster_image'] = normalizeImageUrl(item['poster_image']);
            return EventModel.fromJson(itemCopy);
          }).toList();

          return LandingPageData(
            featured: featured,
            concerts: concerts,
            festivals: festivals,
            events: events,
          );
        }
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error fetchLandingPageData: $e');
    }
    return LandingPageData(featured: [], concerts: [], festivals: [], events: []);
  }
}

class LandingPageData {
  final List<HeroBannerItem> featured;
  final List<EventModel> concerts;
  final List<EventModel> festivals;
  final List<EventModel> events;

  LandingPageData({
    required this.featured,
    required this.concerts,
    required this.festivals,
    required this.events,
  });
}
