import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/data/services/cache_service.dart';

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
      
      final courts = response.data as List<dynamic>;
      await CacheService().cacheCourts(courts); // Cache new data
      return courts;
    } catch (e) {
      // Offline fallback
      final cached = CacheService().getCourts();
      if (cached != null) return cached;
      return [];
    }
  }

  // Create Booking
  Future<String?> createBooking(int courtId, DateTime date, int startHour, {bool isHold = false}) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      final response = await _dio.post('${AppConstants.apiUrl}/bookings', 
        data: {
          'courtId': courtId,
          'date': date.toIso8601String(),
          'startHour': startHour,
          'durationHours': 1
        },
        queryParameters: {'isHold': isHold}
      );
      
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

  // Create Recurring Booking
  Future<String?> createRecurringBooking(int courtId, DateTime startDate, int startHour, int weeks, String daysOfWeek) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.post('${AppConstants.apiUrl}/bookings/recurring', data: {
        'courtId': courtId,
        'date': startDate.toIso8601String(),
        'startHour': startHour,
        'durationHours': 1,
        'weeks': weeks,
        'daysOfWeek': daysOfWeek // e.g., "Monday,Wednesday"
      });

      if (response.statusCode == 200) return null;
      return "Failed";
    } on DioException catch (e) {
       return e.response?.data?.toString() ?? e.message;
    } catch (e) {
      return e.toString();
    }
  }
  // Cancel Booking
  Future<String?> cancelBooking(int id) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      final response = await _dio.post('${AppConstants.apiUrl}/bookings/cancel/$id');
      
      if (response.statusCode == 200) return null;
      return "Cancel failed";
    } on DioException catch (e) {
       return e.response?.data?.toString() ?? e.message;
    } catch (e) {
      return e.toString();
    }
  }

  // Get My History
  Future<List<dynamic>> getMyHistory() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final response = await _dio.get('${AppConstants.apiUrl}/bookings/my-history');
      return response.data as List<dynamic>;
    } catch (e) {
      return [];
    }
  }
}
