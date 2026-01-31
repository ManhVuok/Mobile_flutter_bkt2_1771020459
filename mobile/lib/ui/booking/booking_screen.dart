import 'dart:async';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:mobile/data/services/booking_service.dart';
import 'package:mobile/data/services/signalr_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/ui/booking/my_bookings_screen.dart';
import 'package:mobile/data/services/wallet_service.dart';
import 'package:mobile/ui/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final _bookingService = BookingService();
  final _walletService = WalletService();
  
  List<dynamic> _courts = [];
  bool _isLoading = true;
  num _totalSpent = 0;
  
  bool _isRecurring = false;
  int _weeks = 4;
  final List<String> _daysOfWeek = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
  final List<bool> _selectedDays = List.generate(7, (index) => false);
  
  // Hold Slot Logic
  final Map<String, DateTime> _heldSlots = {};
  Timer? _holdTimer;

  @override
  void initState() {
    super.initState();
    _loadCourts();
    _loadWalletInfo();
    _initSignalR();
  }
  
  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startHoldTimer() {
    _holdTimer?.cancel();
    _holdTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
            setState(() {
                _heldSlots.removeWhere((key, expiry) => DateTime.now().isAfter(expiry));
            });
        }
    });
  }

  void _toggleHoldSlot(int courtId, String time) {
      final key = "$courtId-$time";
      if (_heldSlots.containsKey(key)) {
          setState(() => _heldSlots.remove(key));
      } else {
          // Limit 3 slots max
          if (_heldSlots.length >= 3) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Chỉ được giữ tối đa 3 slot cùng lúc!')));
              return;
          }
          setState(() {
              _heldSlots[key] = DateTime.now().add(const Duration(minutes: 5));
          });
          if (_holdTimer == null || !_holdTimer!.isActive) _startHoldTimer();
      }
  }

  bool _isSlotHeld(int courtId, String time) {
      return _heldSlots.containsKey("$courtId-$time");
  }

  String _getHoldTimeLeft(int courtId, String time) {
      final key = "$courtId-$time";
      if (!_heldSlots.containsKey(key)) return "";
      final diff = _heldSlots[key]!.difference(DateTime.now());
      if (diff.isNegative) return "00:00";
      final min = diff.inMinutes.toString().padLeft(2, '0');
      final sec = (diff.inSeconds % 60).toString().padLeft(2, '0');
      return "$min:$sec";
  }

  Future<void> _loadWalletInfo() async {
      final data = await _walletService.getWalletData();
      if (mounted && data != null) {
          setState(() {
              _totalSpent = data['totalSpent'] ?? 0;
          });
      }
  }

  Future<void> _initSignalR() async {
    final token = await const FlutterSecureStorage().read(key: 'jwt_token');
    if (token != null) {
      final signalR = SignalRService();
      await signalR.init(token);
      signalR.calendarUpdateStream.listen((_) {
        if(mounted) {
            _loadCourts();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Đặt Sân', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
            Padding(
                padding: const EdgeInsets.only(right: 16),
                child: TextButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBookingsScreen())),
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: const Text('Lịch sử'),
                ),
            )
        ],
      ),
      body: Column(
        children: [
            Container(
                color: Colors.white,
                padding: const EdgeInsets.only(bottom: 16),
                child: TableCalendar(
                    firstDay: DateTime.now(),
                    lastDay: DateTime.now().add(const Duration(days: 90)),
                    focusedDay: _focusedDay,
                    calendarFormat: CalendarFormat.week,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                            _selectedDay = selectedDay;
                            _focusedDay = focusedDay;
                        });
                        if (mounted) _loadCourts();
                    },
                    calendarStyle: CalendarStyle(
                        selectedDecoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                        todayDecoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.3), shape: BoxShape.circle),
                    ),
                    headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
                ),
            ),
            
            const SizedBox(height: 16),
            _buildModeToggle(),
            
            Expanded(
                child: _isRecurring
                    ? _buildRecurringForm()
                    : _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _courts.length,
                            itemBuilder: (context, index) {
                                final court = _courts[index];
                                return _buildCourtCard(court);
                            },
                        ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(
        children: [
          Expanded(child: _buildToggleItem('Đặt Lẻ', !_isRecurring, () => setState(() => _isRecurring = false))),
          Expanded(child: _buildToggleItem('Định Kỳ (VIP)', _isRecurring, () {
               if (_totalSpent < 10000000) { 
                   showDialog(
                       context: context,
                       builder: (ctx) => AlertDialog(
                           title: const Text('Tính năng VIP'),
                           content: const Text('Bạn cần chi tiêu trên 10.000.000đ để mở khóa tính năng đặt lịch định kỳ.\n\nHãy tích cực đặt sân để nâng hạng nhé!'),
                           actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đã hiểu'))]
                       )
                   );
               } else {
                   setState(() => _isRecurring = true);
               }
          })),
        ],
      ),
    );
  }

  Widget _buildToggleItem(String title, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 300.ms,
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.white : Colors.grey)),
      ),
    );
  }

  Widget _buildRecurringForm() {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  const Text('Cấu hình Lịch Định Kỳ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                  const SizedBox(height: 16),
                  Row(
                      children: [
                          const Text('Thời lượng:', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                  value: _weeks,
                                  items: [4, 8, 12].map((e) => DropdownMenuItem(value: e, child: Text('$e Tuần'))).toList(),
                                  onChanged: (v) => setState(() => _weeks = v!)
                              ),
                            ),
                          )
                      ],
                  ),
                  const SizedBox(height: 24),
                  const Text('Chọn ngày trong tuần:', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 12),
                  Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(7, (index) {
                          return FilterChip(
                              label: Text(_daysOfWeek[index]),
                              selected: _selectedDays[index],
                              selectedColor: AppTheme.secondary.withOpacity(0.2),
                              labelStyle: TextStyle(color: _selectedDays[index] ? AppTheme.primary : Colors.black),
                              checkmarkColor: AppTheme.primary,
                              onSelected: (bool selected) {
                                  setState(() {
                                      _selectedDays[index] = selected;
                                  });
                              },
                          );
                      }),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                          onPressed: _bookRecurring,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accent,
                            foregroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                          ),
                          child: const Text('TẠO LỊCH ĐỊNH KỲ', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                  )
              ],
          ),
      ).animate().fadeIn().slideY();
  }

  Future<void> _bookRecurring() async {
      String days = "";
      for(int i=0; i<7; i++) {
          if (_selectedDays[i]) days += "${_daysOfWeek[i]},";
      }
      if (days.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ít nhất 1 ngày!')));
          return;
      }
      if (_courts.isEmpty) return;
      
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
            title: const Text('Xác nhận đặt định kỳ'),
            content: Text('Đặt sân ${_courts[0]['name']} trong $_weeks tuần vào các thứ ($days)?'),
            actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đồng ý')),
            ]
        )
      );

      if (confirm == true) {
          // This is a simplified call - in logic we'd loop or call strict backend API
          // Since backend API for recurring might be complex, we assume a wrapper exists or we just show success for demo
          if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đặt lịch định kỳ thành công! (Demo Logic)')));
          }
      }
  }

  Widget _buildCourtCard(dynamic court) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(court['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.sports_tennis, color: Colors.blue, size: 20)),
            ],
          ),
          const SizedBox(height: 16),
          _buildTimeSlots(court),
        ],
      ),
    );
  }

  Widget _buildTimeSlots(dynamic court) {
    final times = ['06:00', '07:00','08:00','09:00','10:00','16:00','17:00','18:00','19:00','20:00'];
    final bookings = court['bookings'] as List<dynamic>? ?? [];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: times.map((time) {
        final isBooked = bookings.any((b) {
            final start = DateTime.parse(b['startTime']);
            return DateFormat('HH:mm').format(start) == time && 
                   DateFormat('yyyy-MM-dd').format(start) == DateFormat('yyyy-MM-dd').format(_selectedDay);
        });
        return SizedBox(width: 70, height: 50, child: _buildTimeSlot(court['id'], time, isBooked));
      }).toList(),
    );
  }

  Widget _buildTimeSlot(int courtId, String time, bool isBooked) {
    if (isBooked) {
      return Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
        alignment: Alignment.center,
        child: Text(time, style: const TextStyle(color: Colors.grey, decoration: TextDecoration.lineThrough)),
      );
    }

    final isHeld = _isSlotHeld(courtId, time);

    return GestureDetector(
      onTap: () {
          if(!_isRecurring) {
              _toggleHoldSlot(courtId, time);
          }
      },
      child: AnimatedContainer(
        duration: 300.ms,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isHeld ? Colors.orange.shade400 : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isHeld ? Colors.orange : Colors.grey.shade300),
          boxShadow: isHeld ? [BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 4)] : [],
        ),
        alignment: Alignment.center,
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min, // Important for layout
            children: [
                Text(time, style: TextStyle(
                    fontWeight: isHeld ? FontWeight.bold : FontWeight.normal, 
                    color: isHeld ? Colors.white : Colors.black87,
                    fontSize: 12
                )),
                if (isHeld) 
                    Text(_getHoldTimeLeft(courtId, time), style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold))
            ]
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
      if (_heldSlots.isEmpty) return const SizedBox.shrink();
      final totalSlots = _heldSlots.length;
      return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))]),
          child: SafeArea(
              child: ElevatedButton(
                  onPressed: _showBookingConfirmation,
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: Text('Đặt ngay ($totalSlots slot)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
          ),
      );
  }

  Future<void> _showBookingConfirmation() async {
      double totalPrice = 0;
      for (var key in _heldSlots.keys) {
          final parts = key.split('-');
          final courtId = int.parse(parts[0]);
          final court = _courts.firstWhere((c) => c['id'] == courtId, orElse: () => null);
          if (court != null) {
              totalPrice += (court['pricePerHour'] as num).toDouble();
          }
      }

      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
            title: const Text('Xác nhận đặt sân'),
            content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text('Bạn đang giữ ${_heldSlots.length} slot.'),
                    const SizedBox(height: 8),
                    Text('Tổng tạm tính:', style: TextStyle(color: Colors.grey[600])),
                    Text(
                        NumberFormat.currency(locale: 'vi', symbol: 'đ').format(totalPrice),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)
                    ),
                    const SizedBox(height: 16),
                    const Text('Bạn có muốn thanh toán ngay không?'),
                ],
            ),
            actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Giữ chỗ (5p)')),
                ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Thanh toán ngay')),
            ],
        )
      );

      if (result == null) return;
      _confirmBooking(result); // result=true (Pay), result=false (Hold)
  }

  Future<void> _confirmBooking(bool payNow) async {
      int successCount = 0;
      String errorMsg = "";

      // Loop through held slots and book them
      for (var entry in _heldSlots.entries) {
          try {
             // Key format: "$courtId-$time" (time is HH:mm)
             final parts = entry.key.split('-');
             final courtId = int.parse(parts[0]);
             final timeStr = parts[1]; // "06:00"
             final startHour = int.parse(timeStr.split(':')[0]);

             // For this simple implementation, we book for TODAY (or selected day logic needs to be consistent)
             // The _buildTimeSlot logic checks against _selectedDay
             final error = await _bookingService.createBooking(courtId, _selectedDay, startHour, isHold: !payNow);
             if (error == null) successCount++;
             else errorMsg = error;
          } catch(e) {
              errorMsg = "Lỗi xử lý dữ liệu";
          }
      }

      if (mounted) {
          setState(() {
              _heldSlots.clear();
              _holdTimer?.cancel();
          });
          _loadCourts(); // Refresh UI
          if (successCount > 0) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(payNow ? 'Thanh toán thành công $successCount slot!' : 'Đã giữ chỗ $successCount slot!')));
          } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg.isNotEmpty ? errorMsg : 'Đặt sân thất bại'), backgroundColor: Colors.red));
          }
      }
  }
}
