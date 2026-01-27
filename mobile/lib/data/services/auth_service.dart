import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/constants.dart';

class AuthService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<String?> login(String email, String password) async {
    try {
      final response = await _dio.post('${AppConstants.apiUrl}/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final token = response.data['token'];
        final role = response.data['role'] ?? 'Member';
        await _storage.write(key: 'jwt_token', value: token);
        await _storage.write(key: 'user_role', value: role);
        return null; // Success
      }
      return 'Login failed';
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response?.data['message'] ?? 'Login failed';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> register(String email, String password, String fullName) async {
    try {
      final response = await _dio.post('${AppConstants.apiUrl}/auth/register', data: {
        'email': email,
        'password': password,
        'fullName': fullName,
      });

      if (response.statusCode == 200) {
        return null; // Success
      }
      return 'Registration failed';
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response?.data['message'] ?? 'Registration failed';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }
}
