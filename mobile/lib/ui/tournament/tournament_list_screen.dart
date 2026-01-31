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
  final _currencyFormat = NumberFormat.currency(locale: 'vi', symbol: 'đ');
  
  static const Color primaryColor = Color(0xFF667EEA);
  static const Color secondaryColor = Color(0xFF764BA2);
  
  List<dynamic> _tournaments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.getTournaments();
    if (mounted) {
      setState(() {
        _tournaments = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _join(int id, String name, dynamic fee) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xác Nhận Đăng Ký'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Giải đấu: $name'),
            const SizedBox(height: 8),
            Text('Phí tham gia: ${_currencyFormat.format(fee)}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            child: const Text('Đăng Ký', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final error = await _service.joinTournament(id, null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Đăng ký thành công!'),
          backgroundColor: error == null ? Colors.green : Colors.red,
        ),
      );
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

  Color _getStatusColor(int status) {
    switch (status) {
      case 0: return const Color(0xFF10B981);
      case 1: return primaryColor;
      case 2: return const Color(0xFFF59E0B);
      case 3: return Colors.grey;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        title: const Text('Giải Đấu', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A5F)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tournaments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events_outlined, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Chưa có giải đấu nào', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      Text('Kéo xuống để làm mới', style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Tải lại'),
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tournaments.length,
                itemBuilder: (context, index) {
                  final t = _tournaments[index];
                  final status = t['status'] ?? 0;
                  final canJoin = status == 0 || status == 1;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: status == 3
                                  ? [Colors.grey.shade400, Colors.grey.shade600]
                                  : [primaryColor, secondaryColor],
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.emoji_events, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t['name'] ?? 'Giải đấu',
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${DateFormat('dd/MM').format(DateTime.parse(t['startDate']))} - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(t['endDate']))}',
                                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(_getStatusText(status), style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),

                        // Body
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _buildInfoItem('Phí vào', _currencyFormat.format(t['entryFee'] ?? 0))),
                                  const SizedBox(width: 12),
                                  Expanded(child: _buildInfoItem('Giải thưởng', _currencyFormat.format(t['prizePool'] ?? 0))),
                                ],
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                height: 44,
                                child: ElevatedButton(
                                  onPressed: canJoin
                                      ? () => _join(t['id'], t['name'], t['entryFee'])
                                      : () => Navigator.push(context, MaterialPageRoute(builder: (_) => TournamentDetailScreen(tournamentId: t['id']))),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: canJoin ? const Color(0xFF10B981) : primaryColor,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    canJoin ? 'THAM GIA' : 'XEM CHI TIẾT',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E3A5F)), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
