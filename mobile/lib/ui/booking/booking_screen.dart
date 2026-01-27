import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:intl/intl.dart';
import 'package:mobile/data/services/booking_service.dart';
import 'package:mobile/data/services/signalr_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final _bookingService = BookingService();
  
  List<dynamic> _courts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCourts();
    _initSignalR();
  }

  Future<void> _initSignalR() async {
    final token = await const FlutterSecureStorage().read(key: 'jwt_token');
    if (token != null) {
      final signalR = SignalRService();
      await signalR.init(token);
      signalR.listenToCalendarUpdate(() {
        if(mounted) {
            _loadCourts(); // Refresh data
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dữ liệu sân đã được cập nhật!')));
        }
      });
    }
  }

  Future<void> _loadCourts() async {
    final courts = await _bookingService.getCourts();
    if(mounted) {
      setState(() {
        _courts = courts;
        _isLoading = false;
      });
    }
  }
  
  Future<void> _bookSlot(int courtId, int startHour, String courtName) async {
    // Confirm Dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xác nhận đặt sân'),
        content: Text('Bạn muốn đặt $courtName khung giờ $startHour:00 - ${startHour+1}:00?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đồng ý')),
        ],
      )
    );
    
    if (confirm != true) return;

    final error = await _bookingService.createBooking(courtId, _selectedDay, startHour);
    if (mounted) {
      if(error == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đặt sân thành công!')));
      } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        title: const Text('Đặt Sân Pickleball', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F7FF),
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Calendar Card
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: TableCalendar(
              firstDay: DateTime.utc(2024, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: const CalendarStyle(
                selectedDecoration: BoxDecoration(color: Color(0xFF1A237E), shape: BoxShape.circle),
                todayDecoration: BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
          ),
          
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('Sân Trống ngày ${DateFormat('dd/MM/yyyy').format(_selectedDay)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // Empty Slots Demo - In production this should filter out booked slots
                  Expanded(
                    child: _isLoading 
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: _courts.length,
                      itemBuilder: (context, index) {
                        final court = _courts[index];
                        return Column(
                           children: List.generate(3, (i) {
                             int hour = 17 + i; // Demo slots: 17, 18, 19h
                             return Padding(
                               padding: const EdgeInsets.only(bottom: 12),
                               child: _buildSlotCard(court['name'], '$hour:00 - ${hour+1}:00', court['pricePerHour'], court['id'], hour),
                             );
                           }),
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSlotCard(String name, String time, dynamic price, int courtId, int startHour) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(time, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${(price as num) ~/ 1000}k', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
              ElevatedButton(
                onPressed: () => _bookSlot(courtId, startHour, name),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A237E),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(60, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Đặt', style: TextStyle(fontSize: 12)),
              )
            ],
          )
        ],
      ),
    );
  }
}
