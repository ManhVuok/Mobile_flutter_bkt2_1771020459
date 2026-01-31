import 'package:flutter/material.dart';
import 'package:mobile/ui/theme/app_theme.dart';
import 'package:intl/intl.dart';

class DuelScreen extends StatefulWidget {
  const DuelScreen({super.key});

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends State<DuelScreen> {
  final List<Map<String, dynamic>> _duels = [
    {
      'challenger': 'Nguyễn Văn A',
      'rank': 3.5,
      'type': '1 vs 1',
      'bet': 50000,
      'status': 'Tìm đối thủ',
      'avatar': 'https://i.pravatar.cc/150?u=1',
      'time': '18:00 - Hôm nay'
    },
    {
      'challenger': 'Team Hỏa Long',
      'rank': 4.0,
      'type': '2 vs 2',
      'bet': 200000,
      'status': 'Chờ xác nhận',
      'avatar': 'https://i.pravatar.cc/150?u=2',
      'time': '19:30 - Ngày mai'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: const Text('Sàn Thách Đấu', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDuelDialog,
        backgroundColor: AppTheme.secondary,
        icon: const Icon(Icons.add_circle, color: Colors.white),
        label: const Text('Tạo Kèo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _duels.length,
        itemBuilder: (context, index) {
          final duel = _duels[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(duel['avatar']),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(duel['challenger'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text('DUPR: ${duel['rank']} • ${duel['type']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        ],
                      ),
                    ),
                    Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(12)),
                        child: Text(duel['status'], style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                    )
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(children: [
                        const Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(duel['time'], style: const TextStyle(fontWeight: FontWeight.w500)),
                    ]),
                    Text('${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(duel['bet'])}', style: const TextStyle(fontWeight: FontWeight.w900, color: AppTheme.primary, fontSize: 16)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                        onPressed: () => _confirmAcceptDuel(duel),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('CHẤP NHẬN THÁCH ĐẤU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  void _confirmAcceptDuel(Map<String, dynamic> duel) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
            title: const Text('Xác nhận nhận kèo'),
            content: Text('Bạn có chắc chắn muốn nhận kèo đấu này?\n\nĐối thủ: ${duel['challenger']}\nMức cược: ${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(duel['bet'])}'),
            actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                ElevatedButton(
                    onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã nhận kèo thành công! Hãy chuẩn bị thi đấu.')));
                    },
                    child: const Text('Xác nhận')
                ),
            ],
        )
      );
  }

  void _showCreateDuelDialog() {
      final betController = TextEditingController();
      String selectedType = '1 vs 1';
      TimeOfDay selectedTime = TimeOfDay.now();

      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (ctx) => Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 16, right: 16, top: 16),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      const Text('Tạo Kèo Mới', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary)),
                      const SizedBox(height: 16),
                      const Text('Loại hình thi đấu', style: TextStyle(fontWeight: FontWeight.w500)),
                      Row(
                          children: [
                              ChoiceChip(label: const Text('1 vs 1'), selected: true, onSelected: (v){}),
                              const SizedBox(width: 8),
                              ChoiceChip(label: const Text('2 vs 2'), selected: false, onSelected: (v){}),
                          ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Mức cược (VNĐ)', style: TextStyle(fontWeight: FontWeight.w500)),
                      TextField(
                          controller: betController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(hintText: 'Nhập số tiền cược (VD: 50000)', suffixText: 'đ'),
                      ),
                      const SizedBox(height: 16),
                      const Text('Thời gian', style: TextStyle(fontWeight: FontWeight.w500)),
                      ListTile(
                          title: Text('Giờ bắt đầu: ${selectedTime.format(context)}'),
                          trailing: const Icon(Icons.access_time),
                          onTap: () async {
                              final picked = await showTimePicker(context: context, initialTime: selectedTime);
                              if (picked != null) {
                                  // In a real app we would setState inside a StatefulBuilder or similar
                                  selectedTime = picked;
                              }
                          },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                              onPressed: () {
                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã tạo kèo mới! Đang tìm đối thủ...')));
                                  setState(() {
                                      _duels.insert(0, {
                                          'challenger': 'Tôi (Bạn)',
                                          'rank': 3.0,
                                          'type': '1 vs 1',
                                          'bet': int.tryParse(betController.text) ?? 50000,
                                          'status': 'Đang tìm',
                                          'avatar': 'https://i.pravatar.cc/150?u=99',
                                          'time': '${selectedTime.format(context)} - Hôm nay'
                                      });
                                  });
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary, padding: const EdgeInsets.symmetric(vertical: 14)),
                              child: const Text('ĐĂNG KÈO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          )
                      ),
                      const SizedBox(height: 24),
                  ],
              ),
          )
      );
  }
}
