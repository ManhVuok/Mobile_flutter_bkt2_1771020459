import 'package:flutter/material.dart';
import 'package:mobile/data/services/tournament_service.dart';
import 'package:mobile/ui/tournament/tournament_detail_screen.dart';
import 'package:intl/intl.dart';

class MyTournamentsScreen extends StatefulWidget {
  const MyTournamentsScreen({super.key});

  @override
  State<MyTournamentsScreen> createState() => _MyTournamentsScreenState();
}

class _MyTournamentsScreenState extends State<MyTournamentsScreen> {
  final _service = TournamentService();
  List<dynamic> _tournaments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.getMyHistory();
    if (mounted) {
      setState(() {
        _tournaments = data;
        _isLoading = false;
      });
    }
  }

  int _parseStatus(dynamic status) {
    if (status is int) return status;
    if (status == 'Open') return 0;
    if (status == 'Registering') return 1;
    if (status == 'Ongoing') return 2;
    if (status == 'Finished') return 3;
    return 0;
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 0: return const Color(0xFF10B981);
      case 1: return const Color(0xFF667EEA);
      case 2: return const Color(0xFFF59E0B);
      case 3: return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 0: return 'Mở Đăng Ký';
      case 1: return 'Đang Đăng Ký';
      case 2: return 'Đang Diễn Ra';
      case 3: return 'Đã Kết Thúc';
      default: return 'Không Rõ';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Giải Đấu Của Tôi'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _tournaments.isEmpty 
          ? const Center(child: Text('Bạn chưa tham gia giải đấu nào.')) 
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _tournaments.length,
              itemBuilder: (context, index) {
                final t = _tournaments[index];
                final status = _parseStatus(t['status']);

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournamentId: t['id']))),
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (t['imageUrl'] != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: Image.network(
                              t['imageUrl'],
                              height: 120, width: double.infinity, fit: BoxFit.cover,
                              errorBuilder: (c,e,s) => Container(height: 120, color: Colors.grey.shade300),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(t['name'] ?? 'Giải đấu', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: _getStatusColor(status).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                    child: Text(_getStatusText(status), style: TextStyle(color: _getStatusColor(status), fontSize: 12, fontWeight: FontWeight.bold)),
                                  )
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Ngày bắt đầu: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(t['startDate']))}', style: TextStyle(color: Colors.grey.shade600)),
                              const SizedBox(height: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
