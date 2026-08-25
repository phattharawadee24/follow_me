import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../models/checkin_model.dart';
import '../../models/user_model.dart';
import '../constants/api_endpoints.dart';
import '../errors/api_exception.dart';
import 'storage_service.dart';

class ApiService {
  static const Duration timeoutDuration = Duration(seconds: 25);

  // ==========================================
  // AUTH & PROFILE ENDPOINTS
  // ==========================================

  /// POST /api/auth/register
  static Future<Map<String, dynamic>> register({
    required String fname,
    required String lname,
    required String email,
    required String password,
  }) async {
    return _request(
      'POST',
      ApiEndpoints.register,
      body: {
        'fname': fname.trim(),
        'lname': lname.trim(),
        'email': email.trim(),
        'password': password,
      },
    );
  }

  /// POST /api/auth/verify-otp
  static Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final res = await _request(
      'POST',
      ApiEndpoints.verifyOtp,
      body: {
        'email': email.trim(),
        'otp': otp.trim(),
      },
    );
    if (res['token'] != null) {
      await StorageService.saveToken(res['token'].toString());
    }
    if (res['user'] != null && res['user'] is Map<String, dynamic>) {
      await StorageService.saveUser(
        UserModel.fromJson(res['user'] as Map<String, dynamic>),
      );
    }
    return res;
  }

  /// POST /api/auth/resend-otp
  static Future<Map<String, dynamic>> resendOtp({
    required String email,
  }) async {
    return _request(
      'POST',
      ApiEndpoints.resendOtp,
      body: {'email': email.trim()},
    );
  }

  /// POST /api/auth/login
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await _request(
      'POST',
      ApiEndpoints.login,
      body: {
        'email': email.trim(),
        'password': password,
      },
    );
    if (res['token'] != null) {
      await StorageService.saveToken(res['token'].toString());
    }
    if (res['user'] != null && res['user'] is Map<String, dynamic>) {
      await StorageService.saveUser(
        UserModel.fromJson(res['user'] as Map<String, dynamic>),
      );
    }
    return res;
  }

  /// POST /api/auth/forgot-password
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    return _request(
      'POST',
      ApiEndpoints.forgotPassword,
      body: {'email': email.trim()},
    );
  }

  /// POST /api/auth/reset-password
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    return _request(
      'POST',
      ApiEndpoints.resetPassword,
      body: {
        'email': email.trim(),
        'otp': otp.trim(),
        'newPassword': newPassword,
      },
    );
  }

  /// GET /api/auth/me
  static Future<UserModel> getProfile() async {
    final res = await _request(
      'GET',
      ApiEndpoints.me,
      requiresAuth: true,
    );
    final userJson = res['user'] as Map<String, dynamic>;
    final user = UserModel.fromJson(userJson);
    await StorageService.saveUser(user);
    return user;
  }

  /// PUT /api/auth/me
  static Future<UserModel> updateProfile({
    String? name,
    String? bio,
    File? imageFile,
  }) async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('กรุณาเข้าสู่ระบบก่อนดำเนินการ', statusCode: 401);
    }

    if (imageFile != null && await imageFile.exists()) {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.me}'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      if (name != null) request.fields['name'] = name.trim();
      if (bio != null) request.fields['bio'] = bio.trim();
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await _sendMultipart(request);
      final bodyStr = await streamedResponse.stream.bytesToString();
      final res = _decodeResponse(streamedResponse.statusCode, bodyStr);
      final user = UserModel.fromJson(res['user'] as Map<String, dynamic>);
      await StorageService.saveUser(user);
      return user;
    } else {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name.trim();
      if (bio != null) body['bio'] = bio.trim();

      final res = await _request(
        'PUT',
        ApiEndpoints.me,
        body: body,
        requiresAuth: true,
      );
      final user = UserModel.fromJson(res['user'] as Map<String, dynamic>);
      await StorageService.saveUser(user);
      return user;
    }
  }

  /// PUT /api/auth/change-password
  static Future<Map<String, dynamic>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return _request(
      'PUT',
      ApiEndpoints.changePassword,
      body: {
        'oldPassword': oldPassword,
        'newPassword': newPassword,
      },
      requiresAuth: true,
    );
  }

  /// DELETE /api/auth/me
  static Future<Map<String, dynamic>> deleteAccount() async {
    final res = await _request(
      'DELETE',
      ApiEndpoints.me,
      requiresAuth: true,
    );
    await StorageService.clearSession();
    return res;
  }

  /// POST /api/auth/logout
  static Future<Map<String, dynamic>> logout() async {
    try {
      final res = await _request('POST', ApiEndpoints.logout);
      await StorageService.clearSession();
      return res;
    } catch (_) {
      await StorageService.clearSession();
      return {'message': 'Logged out'};
    }
  }

  // ==========================================
  // CHECKING ENDPOINTS
  // ==========================================

  /// POST /api/checking
  static Future<CheckinModel> createCheckin({
    required double lat,
    required double lng,
    required String locationName,
    String? address,
    double? accuracy,
    String? description,
    File? imageFile,
  }) async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('กรุณาเข้าสู่ระบบก่อนทำการเช็คอิน', statusCode: 401);
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.checking}'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    request.fields['lat'] = lat.toString();
    request.fields['lng'] = lng.toString();
    request.fields['locationName'] = locationName.trim();
    if (address != null && address.isNotEmpty) {
      request.fields['address'] = address.trim();
    }
    if (accuracy != null) {
      request.fields['accuracy'] = accuracy.toString();
    }
    if (description != null && description.isNotEmpty) {
      request.fields['description'] = description.trim();
    }
    if (imageFile != null && await imageFile.exists()) {
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );
    }

    final streamedResponse = await _sendMultipart(request);
    final bodyStr = await streamedResponse.stream.bytesToString();
    final res = _decodeResponse(streamedResponse.statusCode, bodyStr);
    return CheckinModel.fromJson(res['checkin'] as Map<String, dynamic>);
  }

  /// GET /api/checking
  static Future<List<CheckinModel>> getCheckins({
    bool myOnly = false,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    if (myOnly) queryParams['my'] = 'true';
    if (limit != null) queryParams['limit'] = limit.toString();

    String path = ApiEndpoints.checking;
    if (queryParams.isNotEmpty) {
      final query = Uri(queryParameters: queryParams).query;
      path = '$path?$query';
    }

    final res = await _request(
      'GET',
      path,
      requiresAuth: myOnly,
    );

    final list = res['checkins'] as List<dynamic>? ?? [];
    return list
        .map((item) => CheckinModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// PUT /api/checking
  static Future<CheckinModel> updateCheckin({
    required int id,
    String? locationName,
    String? description,
    File? imageFile,
  }) async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('กรุณาเข้าสู่ระบบก่อนแก้ไข', statusCode: 401);
    }

    if (imageFile != null && await imageFile.exists()) {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('${ApiEndpoints.baseUrl}${ApiEndpoints.checking}'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['id'] = id.toString();
      if (locationName != null) request.fields['locationName'] = locationName.trim();
      if (description != null) request.fields['description'] = description.trim();
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await _sendMultipart(request);
      final bodyStr = await streamedResponse.stream.bytesToString();
      final res = _decodeResponse(streamedResponse.statusCode, bodyStr);
      return CheckinModel.fromJson(res['checkin'] as Map<String, dynamic>);
    } else {
      final body = <String, dynamic>{'id': id};
      if (locationName != null) body['locationName'] = locationName.trim();
      if (description != null) body['description'] = description.trim();

      final res = await _request(
        'PUT',
        ApiEndpoints.checking,
        body: body,
        requiresAuth: true,
      );
      return CheckinModel.fromJson(res['checkin'] as Map<String, dynamic>);
    }
  }

  /// DELETE /api/checking?id={id}
  static Future<Map<String, dynamic>> deleteCheckin(int id) async {
    return _request(
      'DELETE',
      '${ApiEndpoints.checking}?id=$id',
      requiresAuth: true,
    );
  }

  // ==========================================
  // SYSTEM ENDPOINTS
  // ==========================================

  /// GET /api/health
  static Future<Map<String, dynamic>> checkHealth() async {
    return _request('GET', ApiEndpoints.health);
  }

  /// GET /api/test-db
  static Future<Map<String, dynamic>> testDb() async {
    return _request('GET', ApiEndpoints.testDb);
  }

  // ==========================================
  // HTTP HELPER METHODS
  // ==========================================

  static Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('${ApiEndpoints.baseUrl}$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await StorageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    late http.Response response;
    try {
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(uri, headers: headers).timeout(timeoutDuration);
          break;
        case 'POST':
          response = await http
              .post(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
              .timeout(timeoutDuration);
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
              .timeout(timeoutDuration);
          break;
        case 'DELETE':
          response = await http
              .delete(uri, headers: headers, body: body != null ? jsonEncode(body) : null)
              .timeout(timeoutDuration);
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

  static Future<http.StreamedResponse> _sendMultipart(
    http.MultipartRequest request,
  ) async {
    try {
      return await request.send().timeout(timeoutDuration);
    } on SocketException {
      throw const ApiException(
        'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ต',
      );
    } on TimeoutException {
      throw const ApiException('เซิร์ฟเวอร์ตอบสนองช้า กรุณาลองใหม่อีกครั้ง');
    } on http.ClientException catch (error) {
      throw ApiException(_clientErrorMessage(error));
    }
  }

  static Map<String, dynamic> _decodeResponse(int statusCode, String body) {
    Map<String, dynamic> data;
    try {
      data = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('เซิร์ฟเวอร์ตอบกลับไม่ถูกต้อง ($statusCode)', statusCode: statusCode);
    }

    if (statusCode < 200 || statusCode >= 300) {
      final message = data['message'] ??
          data['error'] ??
          data['detail'] ??
          'คำขอไม่สำเร็จ ($statusCode)';
      throw ApiException(message.toString(), statusCode: statusCode);
    }
    return data;
  }

  static String _clientErrorMessage(http.ClientException error) {
    final details = error.message.trim();
    if (details.isEmpty) {
      return 'เชื่อมต่อ API ไม่สำเร็จ กรุณาตรวจสอบการเชื่อมต่ออินเทอร์เน็ต';
    }
    return 'เชื่อมต่อ API ไม่สำเร็จ: $details';
  }
}
