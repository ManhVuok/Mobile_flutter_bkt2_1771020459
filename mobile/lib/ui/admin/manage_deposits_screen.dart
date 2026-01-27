import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/constants.dart';
import 'package:intl/intl.dart';

class ManageDepositsScreen extends StatefulWidget {
  const ManageDepositsScreen({super.key});

  @override
  State<ManageDepositsScreen> createState() => _ManageDepositsScreenState();
}

class _ManageDepositsScreenState extends State<ManageDepositsScreen> {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();
  List<dynamic> _pendingRequests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      // In a real app, we need an admin endpoint to get ALL pending transactions.
      // For now, I'll assume we have a mock list or the existing endpoint can be filtered.
      // Actually, standard users see only theirs. Admin should have a separate endpoint.
      // I'll mock some data if fetching fails, to show the UI.
      setState(() => _isLoading = true);
      
      final response = await _dio.get('${AppConstants.apiUrl}/wallet/all-pending');
      
      setState(() {
        _pendingRequests = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _approve(int id) async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      final response = await _dio.put('${AppConstants.apiUrl}/wallet/approve/$id');
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã phê duyệt thành công!')));
        _loadRequests();
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phê duyệt thất bại'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Phê Duyệt Nạp Tiền'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _pendingRequests.length,
            itemBuilder: (context, index) {
              final req = _pendingRequests[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade100),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(req['fullName'] ?? 'Khách hàng', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        Text(
                          NumberFormat.currency(locale: 'vi', symbol: 'đ', decimalDigits: 0).format(req['amount']),
                          style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Lý do: ${req['description']}', style: TextStyle(color: Colors.grey.shade600)),
                    Text(DateFormat('dd/MM HH:mm').format(DateTime.parse(req['createdDate'])), style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {}, 
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                            ),
                            child: const Text('Từ chối'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _approve(req['id']), 
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.indigo,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0
                            ),
                            child: const Text('Phê duyệt'),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              );
            },
          ),
    );
  }
}
