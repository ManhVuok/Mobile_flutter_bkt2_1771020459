import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/data/services/booking_service.dart';

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final _bookingService = BookingService();
  List<dynamic> _bookings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _bookingService.getMyHistory();
    if (mounted) {
      setState(() {
        _bookings = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelBooking(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hủy Đặt Sân?'),
        content: const Text('Bạn có chắc chắn muốn hủy? Tiền sẽ được hoàn lại ví nếu trước 24h.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Không')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hủy', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final error = await _bookingService.cancelBooking(id);
      if (mounted) {
        setState(() => _isLoading = false);
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã hủy thành công!')));
          _loadData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $error'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Lịch Sử Đặt Sân', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF5F5F5),
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _bookings.isEmpty 
          ? const Center(child: Text('Chưa có lịch sử đặt sân nào.')) 
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                try {
                  final item = _bookings[index];
                  final status = item['status'] ?? 'Unknown';
                  final date = item['startTime'] != null ? DateTime.tryParse(item['startTime']) ?? DateTime.now() : DateTime.now();
                  final price = item['totalPrice'] ?? 0;
                  final courtName = item['court']?['name'] ?? 'Sân ?';
                  
                  Color statusColor = Colors.grey;
                  if (status == 'Confirmed') statusColor = Colors.green;
                  else if (status == 'PendingPayment') statusColor = Colors.orange;
                  else if (status == 'Cancelled') statusColor = Colors.red;

                  final canCancel = status != 'Cancelled' && date.isAfter(DateTime.now());

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))]
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(courtName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text(DateFormat('dd/MM/yyyy HH:mm').format(date), style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20)
                              ),
                              child: Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                            )
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(price)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A237E))),
                            if (canCancel)
                              TextButton.icon(
                                onPressed: () => _cancelBooking(item['id']),
                                icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.red),
                                label: const Text('Hủy', style: TextStyle(color: Colors.red)),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.red.withOpacity(0.05),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                                ),
                              )
                          ],
                        )
                      ],
                    ),
                  );
                } catch (e) {
                   return const SizedBox.shrink(); // Hide faulty items
                }
              },
            ),
    );
  }
}
