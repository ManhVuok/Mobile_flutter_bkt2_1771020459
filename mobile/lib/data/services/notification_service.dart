import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/constants.dart';

class NotificationService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<dynamic>> getNotifications() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('${AppConstants.apiUrl}/notifications');
      return response.data as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
      await _dio.put('${AppConstants.apiUrl}/notifications/$id/read');
    } catch (e) {
      // Ignore
    }
  }
}
