import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/constants.dart';

class BookingService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Fetch Bookings to show on calendar
  Future<List<dynamic>> getBookings(DateTime from, DateTime to) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('${AppConstants.apiUrl}/bookings/calendar', queryParameters: {
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      });
      return response.data as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  // Fetch Courts
  Future<List<dynamic>> getCourts() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await _dio.get('${AppConstants.apiUrl}/courts');
      return response.data as List<dynamic>;
    } catch (e) {
      return [];
    }
  }

  // Create Booking
  Future<String?> createBooking(int courtId, DateTime date, int startHour) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      final response = await _dio.post('${AppConstants.apiUrl}/bookings', data: {
        'courtId': courtId,
        'date': date.toIso8601String(),
        'startHour': startHour,
        'durationHours': 1
      });
      
      if (response.statusCode == 200) return null;
      return "Booking failed";
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response?.data?.toString() ?? e.message;
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}
