import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/core/constants.dart';
import 'package:intl/intl.dart';

class ManageBookingsScreen extends StatefulWidget {
  const ManageBookingsScreen({super.key});

  @override
  State<ManageBookingsScreen> createState() => _ManageBookingsScreenState();
}

class _ManageBookingsScreenState extends State<ManageBookingsScreen> {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      // Fetch calendar bookings for a wide range to see all
      final now = DateTime.now();
      final response = await _dio.get('${AppConstants.apiUrl}/bookings/calendar', queryParameters: {
        'from': now.subtract(const Duration(days: 30)).toIso8601String(),
        'to': now.add(const Duration(days: 30)).toIso8601String(),
      });
      
      setState(() {
        _bookings = response.data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelBooking(int id) async {
     try {
      final token = await _storage.read(key: 'jwt_token');
      _dio.options.headers['Authorization'] = 'Bearer $token';
      
      final response = await _dio.post('${AppConstants.apiUrl}/bookings/cancel/$id');
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy lịch đặt sân!')));
        _loadBookings();
      }
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lỗi khi hủy'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Quản Lý Đặt Sân'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _bookings.length,
            itemBuilder: (context, index) {
              final b = _bookings[index];
              final start = DateTime.parse(b['startTime']);
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.sports_tennis, color: Colors.indigo),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(b['court']?['name'] ?? 'Sân tập', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Người đặt: ${b['member']?['fullName'] ?? 'Member'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(DateFormat('dd/MM HH:mm').format(start), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.indigo)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      onPressed: () => _cancelBooking(b['id']),
                    )
                  ],
                ),
              );
            },
          ),
    );
  }
}
