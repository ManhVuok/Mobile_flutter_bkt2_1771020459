import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/constants.dart';

class TournamentService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<List<dynamic>> getTournaments() async {
    try {
      print('Fetching tournaments from: ${AppConstants.apiUrl}/tournaments');
      final response = await _dio.get('${AppConstants.apiUrl}/tournaments');
      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');
      return response.data as List<dynamic>;
    } catch (e) {
      print('Error fetching tournaments: $e');
      return [];
    }
  }

  Future<dynamic> getTournamentDetail(int id) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.get('${AppConstants.apiUrl}/tournaments/$id');
      return response.data;
    } catch (e) {
      return null;
    }
  }

  Future<String?> joinTournament(int tournamentId, String? teamName) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      final response = await _dio.post('${AppConstants.apiUrl}/tournaments/$tournamentId/join', data: teamName);
      
      if (response.statusCode == 200) return null;
      return "Join failed";
    } on DioException catch (e) {
       if (e.response != null) {
        return e.response?.data?.toString() ?? e.message;
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> createTournament(Map<String, dynamic> data) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      final response = await _dio.post('${AppConstants.apiUrl}/tournaments', data: data);
      
      if (response.statusCode == 201 || response.statusCode == 200) return null;
      return "Create failed";
    } on DioException catch (e) {
       if (e.response != null) {
        return e.response?.data?.toString() ?? e.message;
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<dynamic>> getMyHistory() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('${AppConstants.apiUrl}/tournaments/my-history');
      return response.data as List<dynamic>;
    } catch (e) {
      return [];
    }
  }
}
