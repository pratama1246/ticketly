import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class AuthService {
  static final http.Client _client = http.Client();

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  // Save Session
  static Future<void> _saveSession(String token, Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, json.encode(user));
  }

  // Get Saved Token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Get Saved User Details
  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString(_userKey);
    if (userStr != null) {
      return json.decode(userStr) as Map<String, dynamic>;
    }
    return null;
  }

  // Check Login Status
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }

  // Login Request
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 5));

      final decoded = json.decode(response.body);

      if (response.statusCode == 200 && decoded['status'] == 'success') {
        final token = decoded['data']['token'];
        final user = decoded['data']['user'] as Map<String, dynamic>;
        await _saveSession(token, user);
        return {'success': true, 'message': decoded['message']};
      } else {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Email atau password salah.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

  // Logout Request
  static Future<void> logout() async {
    final token = await getToken();
    if (token != null) {
      try {
        // Call stateless logout on backend
        await _client.post(
          Uri.parse('${ApiConstants.baseUrl}/api/auth/logout'),
          headers: {'Authorization': 'Bearer $token'},
        ).timeout(const Duration(seconds: 3));
      } catch (_) {
        // Ignore errors for logout API call since token invalidation is client-side
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Fetch Profile from DB
  static Future<Map<String, dynamic>?> getProfile() async {
    final token = await getToken();
    if (token == null) return null;

    try {
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/api/profile'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 5));

      final decoded = json.decode(response.body);
      if (response.statusCode == 200 && decoded['status'] == 'success') {
        final user = decoded['data'] as Map<String, dynamic>;
        
        // Update local session data with latest from DB
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, json.encode(user));
        
        return user;
      }
    } catch (e) {
      // ignore: avoid_print
      print('Error getProfile: $e');
    }
    return null;
  }

  // Update Profile in DB (with optional photo filepath)
  static Future<Map<String, dynamic>> updateProfile({
    required String name,
    required String email,
    String? fotoPath,
    List<int>? fotoBytes,
    String? fotoFileName,
  }) async {
    final token = await getToken();
    if (token == null) {
      return {'success': false, 'message': 'Sesi habis. Silakan login kembali.'};
    }

    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}/api/profile/update');
      final request = http.MultipartRequest('POST', uri);
      
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['username'] = name;
      request.fields['email'] = email;

      if (fotoPath != null && fotoPath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('foto', fotoPath));
      } else if (fotoBytes != null && fotoFileName != null) {
        request.files.add(http.MultipartFile.fromBytes('foto', fotoBytes, filename: fotoFileName));
      }

      final streamedResponse = await request.send().timeout(const Duration(seconds: 10));
      final response = await http.Response.fromStream(streamedResponse);
      final decoded = json.decode(response.body);

      if (response.statusCode == 200 && decoded['status'] == 'success') {
        final updatedUser = decoded['data'] as Map<String, dynamic>;
        
        // Update local cache
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_userKey, json.encode(updatedUser));
        
        return {'success': true, 'data': updatedUser, 'message': decoded['message']};
      } else {
        return {
          'success': false,
          'message': decoded['message'] ?? 'Gagal memperbarui profil.'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }
}
