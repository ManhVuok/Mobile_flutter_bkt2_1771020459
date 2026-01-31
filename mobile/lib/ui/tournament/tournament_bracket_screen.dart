import 'package:flutter/material.dart';

class TournamentBracketScreen extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;
  final List<dynamic>? matches;

  const TournamentBracketScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    this.matches,
  });

  @override
  State<TournamentBracketScreen> createState() => _TournamentBracketScreenState();
}

class _TournamentBracketScreenState extends State<TournamentBracketScreen> {
  static const Color primaryColor = Color(0xFF667EEA);
  
  // Sample bracket data for demo
  late List<BracketMatch> _bracketData;

  @override
  void initState() {
    super.initState();
    _loadBracketData();
  }

  void _loadBracketData() {
    // If matches provided, use them; otherwise use demo data
    if (widget.matches != null && widget.matches!.isNotEmpty) {
      _bracketData = widget.matches!.map((m) => BracketMatch.fromJson(m)).toList();
    } else {
      // Demo bracket data
      _bracketData = [
        // Quarter Finals (Round 1)
        BracketMatch(id: '1', round: 1, position: 0, player1: 'Nguyễn Văn A', player2: 'Trần Văn B', score1: 21, score2: 15, winner: 1),
        BracketMatch(id: '2', round: 1, position: 1, player1: 'Lê Văn C', player2: 'Phạm Văn D', score1: 18, score2: 21, winner: 2),
        BracketMatch(id: '3', round: 1, position: 2, player1: 'Hoàng Văn E', player2: 'Vũ Văn F', score1: 21, score2: 19, winner: 1),
        BracketMatch(id: '4', round: 1, position: 3, player1: 'Đặng Văn G', player2: 'Bùi Văn H', score1: 15, score2: 21, winner: 2),
        // Semi Finals (Round 2)
        BracketMatch(id: '5', round: 2, position: 0, player1: 'Nguyễn Văn A', player2: 'Phạm Văn D', score1: 21, score2: 18, winner: 1),
        BracketMatch(id: '6', round: 2, position: 1, player1: 'Hoàng Văn E', player2: 'Bùi Văn H', score1: 17, score2: 21, winner: 2),
        // Final (Round 3)
        BracketMatch(id: '7', round: 3, position: 0, player1: 'Nguyễn Văn A', player2: 'Bùi Văn H', score1: null, score2: null, winner: null),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        title: Text(widget.tournamentName, style: const TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Round headers
                Row(
                  children: [
                    _buildRoundHeader('Tứ Kết', 0),
                    _buildRoundHeader('Bán Kết', 1),
                    _buildRoundHeader('Chung Kết', 2),
                    _buildRoundHeader('Vô Địch', 3),
                  ],
                ),
                const SizedBox(height: 20),
                // Bracket visualization
                CustomPaint(
                  painter: BracketPainter(_bracketData),
                  child: SizedBox(
                    width: 900,
                    height: 500,
                    child: Stack(
                      children: [
                        // Round 1 matches
                        ..._buildRoundMatches(1, 4, 0),
                        // Round 2 matches
                        ..._buildRoundMatches(2, 2, 230),
                        // Round 3 (Final)
                        ..._buildRoundMatches(3, 1, 460),
                        // Winner
                        Positioned(
                          left: 690,
                          top: 200,
                          child: _buildWinnerCard(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoundHeader(String title, int index) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 30),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor.withOpacity(0.8 - index * 0.15), primaryColor],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
      ),
    );
  }

  List<Widget> _buildRoundMatches(int round, int count, double leftOffset) {
    final roundMatches = _bracketData.where((m) => m.round == round).toList();
    final spacing = 500 / count;
    
    return List.generate(roundMatches.length, (index) {
      final match = roundMatches[index];
      return Positioned(
        left: leftOffset,
        top: (spacing / 2 - 40) + (index * spacing),
        child: _buildMatchCard(match),
      );
    });
  }

  Widget _buildMatchCard(BracketMatch match) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: primaryColor.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPlayerRow(match.player1, match.score1, match.winner == 1),
          const Divider(height: 16),
          _buildPlayerRow(match.player2, match.score2, match.winner == 2),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(String? name, int? score, bool isWinner) {
    return Row(
      children: [
        if (isWinner)
          Container(
            width: 4,
            height: 24,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              borderRadius: BorderRadius.circular(2),
            ),
          )
        else
          const SizedBox(width: 12),
        Expanded(
          child: Text(
            name ?? 'TBD',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isWinner ? FontWeight.bold : FontWeight.normal,
              color: isWinner ? const Color(0xFF1A1F36) : Colors.grey.shade600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isWinner ? const Color(0xFF10B981).withOpacity(0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            score?.toString() ?? '-',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: isWinner ? const Color(0xFF10B981) : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWinnerCard() {
    final finalMatch = _bracketData.where((m) => m.round == 3).firstOrNull;
    final winner = finalMatch?.winner == 1 ? finalMatch?.player1 : 
                   finalMatch?.winner == 2 ? finalMatch?.player2 : null;

    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: Colors.white, size: 40),
          const SizedBox(height: 8),
          const Text('🏆 VÔ ĐỊCH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          Text(
            winner ?? 'Chưa xác định',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class BracketMatch {
  final String id;
  final int round;
  final int position;
  final String? player1;
  final String? player2;
  final int? score1;
  final int? score2;
  final int? winner; // 1 or 2

  BracketMatch({
    required this.id,
    required this.round,
    required this.position,
    this.player1,
    this.player2,
    this.score1,
    this.score2,
    this.winner,
  });

  factory BracketMatch.fromJson(Map<String, dynamic> json) {
    return BracketMatch(
      id: json['id']?.toString() ?? '',
      round: json['round'] ?? 1,
      position: json['position'] ?? 0,
      player1: json['player1Name'] ?? json['player1'],
      player2: json['player2Name'] ?? json['player2'],
      score1: json['score1'],
      score2: json['score2'],
      winner: json['winner'],
    );
  }
}

class BracketPainter extends CustomPainter {
  final List<BracketMatch> matches;

  BracketPainter(this.matches);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF667EEA).withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Draw connecting lines between rounds
    // Round 1 to Round 2
    _drawConnector(canvas, paint, 200, 62.5, 230, 125);
    _drawConnector(canvas, paint, 200, 187.5, 230, 125);
    _drawConnector(canvas, paint, 200, 312.5, 230, 375);
    _drawConnector(canvas, paint, 200, 437.5, 230, 375);

    // Round 2 to Round 3
    _drawConnector(canvas, paint, 430, 125, 460, 250);
    _drawConnector(canvas, paint, 430, 375, 460, 250);

    // Round 3 to Winner
    _drawConnector(canvas, paint, 660, 250, 690, 250);
  }

  void _drawConnector(Canvas canvas, Paint paint, double x1, double y1, double x2, double y2) {
    final path = Path();
    path.moveTo(x1, y1);
    path.lineTo(x1 + 15, y1);
    path.lineTo(x1 + 15, y2);
    path.lineTo(x2, y2);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
