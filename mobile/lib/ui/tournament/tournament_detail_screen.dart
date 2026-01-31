import 'package:flutter/material.dart';
import 'package:mobile/data/services/tournament_service.dart';
import 'package:intl/intl.dart';
import 'package:mobile/ui/chat/chat_screen.dart';
import 'package:mobile/ui/tournament/tournament_bracket_screen.dart';

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
    try {
      final data = await _service.getTournamentDetail(widget.tournamentId);
      if (mounted) {
        setState(() {
          _tournament = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    
    if (_tournament == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: const Text('Chi Tiết Giải Đấu'),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: const Center(child: Text('Không tìm thấy giải đấu')),
      );
    }

    final matches = (_tournament['matches'] as List<dynamic>?) ?? [];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          title: Text(
            _tournament['name'] ?? 'Chi Tiết',
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1a1a2e)),
          ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Color(0xFF1a1a2e)),
          bottom: const TabBar(
            labelColor: Color(0xFF667EEA),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF667EEA),
            tabs: [
                Tab(text: "Vòng Bảng"),
                Tab(text: "Vòng Loại"),
            ]
          ),
        ),
        floatingActionButton: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
            FloatingActionButton.extended(
                heroTag: 'bracket',
                onPressed: () => Navigator.push(
                context, 
                MaterialPageRoute(
                    builder: (_) => TournamentBracketScreen(
                    tournamentId: widget.tournamentId.toString(),
                    tournamentName: _tournament['name'] ?? 'Bracket',
                    matches: matches,
                    ),
                ),
                ),
                backgroundColor: const Color(0xFF667EEA),
                icon: const Icon(Icons.account_tree, color: Colors.white),
                label: const Text('Bracket', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.extended(
                heroTag: 'chat',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(tournamentId: widget.tournamentId))),
                backgroundColor: const Color(0xFF764BA2),
                icon: const Icon(Icons.chat, color: Colors.white),
                label: const Text('Chat', style: TextStyle(color: Colors.white)),
            ),
            ],
        ),
        body: TabBarView(
          children: [
            // GROUP STAGE TAB
            SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        _buildGroupTable("Bảng A"),
                        const SizedBox(height: 24),
                        _buildGroupTable("Bảng B"),
                    ],
                ),
            ),
            
            // KNOCKOUT BRACKET TAB
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.white, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _tournament['name'] ?? '',
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Giải thưởng: ${NumberFormat.currency(locale: 'vi', symbol: 'đ').format(_tournament['prizePool'] ?? 0)}',
                          style: TextStyle(color: Colors.white.withOpacity(0.8)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormat('dd/MM/yyyy').format(DateTime.parse(_tournament['startDate']))} - ${DateFormat('dd/MM/yyyy').format(DateTime.parse(_tournament['endDate']))}',
                          style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Matches Section
                  const Text('Lịch Thi Đấu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1a1a2e))),
                  const SizedBox(height: 12),

                  if (matches.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text('Chưa có lịch thi đấu', style: TextStyle(color: Colors.grey))),
                    ),

                  ...matches.map((m) => _buildMatchCard(m)).toList(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(dynamic m) {
    final isFinished = m['status'] == 2;
    final player1 = m['team1_Player1']?['fullName'] ?? 'TBD';
    final player2 = m['team2_Player1']?['fullName'] ?? 'TBD';
    final score1 = m['score1'] ?? 0;
    final score2 = m['score2'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isFinished ? null : Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(m['roundName'] ?? 'Round', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF1a1a2e).withOpacity(0.1),
                      child: Text(player1.isNotEmpty ? player1[0] : '?', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    Text(player1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isFinished ? const Color(0xFF10b981) : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$score1 - $score2',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isFinished ? Colors.white : Colors.grey.shade700),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: const Color(0xFF00d9ff).withOpacity(0.1),
                      child: Text(player2.isNotEmpty ? player2[0] : '?', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    Text(player2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isFinished ? 'Đã xong' : 'Sắp diễn ra',
            style: TextStyle(color: isFinished ? Colors.green : Colors.orange, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
  Widget _buildGroupTable(String title) {
      return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1a1a2e))),
                  const SizedBox(height: 16),
                  Table(
                      border: TableBorder(horizontalInside: BorderSide(color: Colors.grey.shade200)),
                      columnWidths: const {0: FlexColumnWidth(3), 1: FlexColumnWidth(1), 2: FlexColumnWidth(1), 3: FlexColumnWidth(1)},
                      children: [
                          const TableRow(children: [
                              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text('Đội', style: TextStyle(color: Colors.grey))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: Text('T', style: TextStyle(color: Colors.grey)))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: Text('L', style: TextStyle(color: Colors.grey)))),
                              Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Center(child: Text('Điểm', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)))),
                          ]),
                          _buildRow('Nguyễn Văn A', 3, 0, 9),
                          _buildRow('Trần Văn B', 2, 1, 6),
                          _buildRow('Lê Thị C', 1, 2, 3),
                          _buildRow('Phạm Văn D', 0, 3, 0),
                      ],
                  )
              ],
          ),
      );
  }

  TableRow _buildRow(String name, int win, int loss, int points) {
      return TableRow(children: [
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold))),
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Center(child: Text('$win'))),
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Center(child: Text('$loss'))),
          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Center(child: Text('$points', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF667EEA))))),
      ]);
  }
}
