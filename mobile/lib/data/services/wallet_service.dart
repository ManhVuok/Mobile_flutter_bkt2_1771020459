import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/constants.dart';

class WalletService {
  final Dio _dio = Dio();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>?> getWalletData() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) return null;

      _dio.options.headers['Authorization'] = 'Bearer $token';

      final balanceResponse = await _dio.get('${AppConstants.apiUrl}/wallet/balance');
      final transactionsResponse = await _dio.get('${AppConstants.apiUrl}/wallet/transactions');

      return {
        'balance': balanceResponse.data,
        'transactions': transactionsResponse.data,
      };
    } catch (e) {
      print('Error fetching wallet: $e');
      return null;
    }
  }

  Future<bool> deposit(int amount, String description) async {
     try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      final response = await _dio.post('${AppConstants.apiUrl}/wallet/deposit', data: {
        'amount': amount,
        'description': description
      });
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
