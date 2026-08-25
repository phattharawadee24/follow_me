import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  const ApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ApiService {
  static const baseUrl = 'https://where-am-i-silk.vercel.app';

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final fname = parts.first;
    final lname = parts.length > 1 ? parts.sublist(1).join(' ') : '-';
    return _request(
      'POST',
      '/api/auth/register',
      body: {
        'fname': fname,
        'lname': lname,
        'email': email.trim(),
        'password': password,
      },
    );
  }

  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) {
    return _request(
      'POST',
      '/api/auth/verify-otp',
      body: {'email': email.trim(), 'otp': otp.trim()},
    );
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _request(
      'POST',
      '/api/auth/login',
      body: {'email': email.trim(), 'password': password},
    );
  }

  static Future<Map<String, dynamic>> checkin({
    required String token,
    required double lat,
    required double lng,
    required String locationName,
    File? imageFile,
  }) async {
    final request =
        http.MultipartRequest('POST', Uri.parse('$baseUrl/api/checking'))
          ..headers['Authorization'] = 'Bearer $token'
          ..fields['lat'] = lat.toString()
          ..fields['lng'] = lng.toString()
          ..fields['locationName'] = locationName;

    if (imageFile != null && await imageFile.exists()) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }

    late http.StreamedResponse response;
    try {
      response = await request.send().timeout(const Duration(seconds: 20));
    } on SocketException {
      throw const ApiException(
        'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ต',
      );
    } on TimeoutException {
      throw const ApiException('เซิร์ฟเวอร์ตอบสนองช้า กรุณาลองใหม่อีกครั้ง');
    } on http.ClientException catch (error) {
      throw ApiException(_clientErrorMessage(error));
    }
    final body = await response.stream.bytesToString();
    return _decodeResponse(response.statusCode, body);
  }

  static Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final headers = {'Content-Type': 'application/json'};
    late http.Response response;

    try {
      switch (method) {
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: jsonEncode(body))
              .timeout(const Duration(seconds: 20));
          break;
        default:
          throw const ApiException('ไม่รองรับ HTTP method นี้');
      }
    } on SocketException {
      throw const ApiException(
        'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ต',
      );
    } on TimeoutException {
      throw const ApiException('เซิร์ฟเวอร์ตอบสนองช้า กรุณาลองใหม่อีกครั้ง');
    } on http.ClientException catch (error) {
      throw ApiException(_clientErrorMessage(error));
    }

    return _decodeResponse(response.statusCode, response.body);
  }

  static Map<String, dynamic> _decodeResponse(int statusCode, String body) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('เซิร์ฟเวอร์ตอบกลับไม่ถูกต้อง ($statusCode)');
    }

    if (statusCode < 200 || statusCode >= 300) {
      final message =
          data['message'] ?? data['error'] ?? 'คำขอไม่สำเร็จ ($statusCode)';
      throw ApiException(message.toString());
    }
    return data;
  }

  static String _clientErrorMessage(http.ClientException error) {
    final details = error.message.trim();
    if (details.isEmpty) {
      return 'เชื่อมต่อ API ไม่สำเร็จ กรุณาตรวจสอบอินเทอร์เน็ตหรือ CORS ของเซิร์ฟเวอร์';
    }
    return 'เชื่อมต่อ API ไม่สำเร็จ: $details';
  }

  static Future<void> saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final user = data['user'];
    if (user is Map<String, dynamic>) {
      await prefs.setString('name', user['name']?.toString() ?? '');
      await prefs.setString('email', user['email']?.toString() ?? '');
    }
    final token = data['token']?.toString();
    if (token != null && token.isNotEmpty) {
      await prefs.setString('apiToken', token);
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('apiToken');
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('apiToken');
  }
}
