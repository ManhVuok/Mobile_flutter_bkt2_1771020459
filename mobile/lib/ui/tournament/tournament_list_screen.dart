import 'package:flutter/material.dart';
import 'package:mobile/data/services/tournament_service.dart';
import 'package:intl/intl.dart';
import 'package:mobile/ui/tournament/tournament_detail_screen.dart';

class TournamentListScreen extends StatefulWidget {
  const TournamentListScreen({super.key});

  @override
  State<TournamentListScreen> createState() => _TournamentListScreenState();
}

class _TournamentListScreenState extends State<TournamentListScreen> {
  final _service = TournamentService();
  List<dynamic> _tournaments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.getTournaments();
    if(mounted) {
      setState(() {
        _tournaments = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _join(int id, String name, dynamic fee) async {
      // Confirm
      final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng Ký Giải Đấu'),
        content: Text('Phí tham gia: ${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(fee)}\nBạn có chắc muốn tham gia?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đồng ý')),
        ],
      )
    );

    if (confirm != true) return;

    final error = await _service.joinTournament(id, null);
     if (mounted) {
      if(error == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng ký thành công!')));
      } else {
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh Sách Giải Đấu')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _tournaments.length,
            itemBuilder: (context, index) {
              final t = _tournaments[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text(t['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(8)),
                            child: Text(t['status'] == 0 ? 'Mở Đăng Ký' : 'Đang Diễn Ra', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Thời gian: ${DateFormat('dd/MM').format(DateTime.parse(t['startDate']))} - ${DateFormat('dd/MM').format(DateTime.parse(t['endDate']))}'),
                      const SizedBox(height: 8),
                      Text('Giải thưởng: ${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(t['prizePool'])}'),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: t['status'] == 0 
                            ? () => _join(t['id'], t['name'], t['entryFee']) 
                            : () => Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournamentId: t['id']))),
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), foregroundColor: Colors.white),
                          child: Text(t['status'] == 0 ? 'Tham Gia Ngay (${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(t['entryFee'])})' : 'Xem Chi Tiết'),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
        ),
    );
  }
}
