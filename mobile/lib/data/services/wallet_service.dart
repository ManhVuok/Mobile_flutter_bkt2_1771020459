import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/constants.dart';

class WalletService {
  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
    validateStatus: (status) => status != null && status < 500,
  ));
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>?> getWalletData() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return null;

      _dio.options.headers['Authorization'] = 'Bearer $token';

      final responses = await Future.wait([
        _dio.get('${AppConstants.apiUrl}/wallet/balance'),
        _dio.get('${AppConstants.apiUrl}/wallet/transactions'),
      ]);

      final balanceResponse = responses[0];
      final transactionsResponse = responses[1];
      
      if (balanceResponse.statusCode != 200) return null;

      final dynamic balanceData = balanceResponse.data;
      
      // Handle both Object and Primitive return types to avoid "Receiver: ..." error
      double balance = 0;
      double totalSpent = 0;
      String tier = 'Thành Viên';

      if (balanceData is Map<String, dynamic>) {
          balance = (balanceData['balance'] as num?)?.toDouble() ?? 0;
          totalSpent = (balanceData['totalSpent'] as num?)?.toDouble() ?? 0;
          tier = balanceData['tier'] ?? 'Thành Viên';
      } else if (balanceData is num) {
          balance = balanceData.toDouble();
      }

      return {
        'balance': balance,
        'totalSpent': totalSpent,
        'tier': tier,
        'transactions': transactionsResponse.statusCode == 200 ? transactionsResponse.data : [],
      };
    } catch (e) {
      print('Error fetching wallet: $e');
      return null;
    }
  }

  Future<bool> deposit(int amount, String description, String? proofImageUrl) async {
     try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return false;

      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      final response = await _dio.post('${AppConstants.apiUrl}/wallet/deposit', data: {
        'amount': amount,
        'description': description,
        'proofImageUrl': proofImageUrl
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Restored method: getRevenueStats
  Future<List<dynamic>> getRevenueStats() async {
     try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      final response = await _dio.get('${AppConstants.apiUrl}/wallet/stats');
      return (response.data is List) ? response.data as List<dynamic> : [];
    } catch (e) {
      return [];
    }
  }

  // Restored method: exportRevenueReport
  Future<bool> exportRevenueReport() async {
     try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      final response = await _dio.get(
        '${AppConstants.apiUrl}/wallet/export-report',
        options: Options(responseType: ResponseType.plain)
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Export error: $e');
      return false;
    }
  }
}
