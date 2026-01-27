import 'package:flutter/material.dart';
import 'package:mobile/data/services/tournament_service.dart';
import 'package:intl/intl.dart';
import 'package:mobile/ui/chat/chat_screen.dart';

class TournamentDetailScreen extends StatefulWidget {
  final int tournamentId;
  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailScreen> createState() => _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen> {
  final _service = TournamentService();
  dynamic _tournament;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Assuming getTournament(id) is implemented in service or we reuse getTournaments list and filter?
    // Better to fetch fresh data if backend supports it.
    // Since I added backend endpoint, I should update service too. 
    // For now, I'll mock fetch or assume service update.
    // Wait, I need to update service first.
    // I'll assume service has getTournamentDetail or I'll add it in next tool.
    try {
        // Temporary Direct Call approach mock or need service update
        // I will update service in next step.
        final data = await _service.getTournamentDetail(widget.tournamentId);
        if(mounted) {
            setState(() {
                _tournament = data;
                _isLoading = false;
            });
        }
    } catch(e) {
        if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_tournament == null) return const Scaffold(body: Center(child: Text("Không tìm thấy giải đấu")));

    final matches = _tournament['matches'] as List<dynamic>;

    return Scaffold(
      appBar: AppBar(title: Text(_tournament['name'])),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text("Lịch Thi Đấu / Kết Quả", style: Theme.of(context).textTheme.titleLarge),
             const SizedBox(height: 16),
             matches.isEmpty 
               ? const Text("Chưa có lịch thi đấu.")
               : ListView.separated(
                   shrinkWrap: true,
                   physics: const NeverScrollableScrollPhysics(),
                   itemCount: matches.length,
                   separatorBuilder: (_, __) => const SizedBox(height: 12),
                   itemBuilder: (context, index) {
                     final m = matches[index];
                     return Card(
                       child: Padding(
                         padding: const EdgeInsets.all(12),
                         child: Column(
                           children: [
                             Text(m['roundName'] ?? 'Round', style: const TextStyle(color: Colors.grey)),
                             const SizedBox(height: 8),
                             Row(
                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
                               children: [
                                 Expanded(child: Text(m['team1_Player1']?['fullName'] ?? 'TBD', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
                                 Padding(
                                   padding: const EdgeInsets.symmetric(horizontal: 16),
                                   child: Text("${m['score1']} - ${m['score2']}", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
                                 ),
                                 Expanded(child: Text(m['team2_Player1']?['fullName'] ?? 'TBD', textAlign: TextAlign.left, style: const TextStyle(fontWeight: FontWeight.bold))),
                               ],
                             ),
                             const SizedBox(height: 8),
                             Text(m['status'] == 2 ? 'Đã xong' : 'Sắp diễn ra', style: TextStyle(color: m['status'] == 2 ? Colors.green : Colors.orange, fontSize: 12))
                           ],
                         ),
                       ),
                     );
                   },
               )
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(tournamentId: widget.tournamentId))),
        child: const Icon(Icons.chat),
      ),
    );
  }
}
