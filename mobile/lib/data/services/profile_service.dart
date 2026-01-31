import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/constants.dart';

class ProfileService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<dynamic> getMyProfile() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('${AppConstants.apiUrl}/members/me');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<List<dynamic>> getMembers() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('${AppConstants.apiUrl}/members');
      return response.data as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  Future<dynamic> getMemberProfile(String id) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('${AppConstants.apiUrl}/members/$id');
      return response.data;
    } catch (e) {
      return null;
    }
  }
}
