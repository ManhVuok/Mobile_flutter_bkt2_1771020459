import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:mobile/data/providers/user_provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/constants.dart';
import 'package:mobile/data/services/auth_service.dart';
import 'package:mobile/ui/auth/login_screen.dart';
import 'package:mobile/ui/booking/booking_screen.dart';
import 'package:mobile/ui/wallet/wallet_screen.dart';
import 'package:mobile/ui/tournament/tournament_list_screen.dart';
import 'package:mobile/ui/notification/notification_screen.dart';
import 'package:mobile/ui/profile/profile_screen.dart';
import 'package:mobile/ui/admin/admin_dashboard_screen.dart';
import 'package:mobile/ui/admin/manage_deposits_screen.dart';
import 'package:mobile/ui/news/news_list_screen.dart';
import 'package:mobile/ui/training/training_screen.dart';
import 'package:mobile/ui/duel/duel_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/data/services/signalr_service.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _role = 'Member';
  bool _isInit = false;

  // Premium Color Scheme
  static const Color primaryColor = Color(0xFF667EEA);
  static const Color secondaryColor = Color(0xFF764BA2);
  static const Color accentColor = Color(0xFF06D6A0);

  @override
  void initState() {
    super.initState();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final role = await const FlutterSecureStorage().read(key: 'user_role');
    setState(() {
      _role = role ?? 'Member';
      _isInit = true;
    });
  }

  List<Widget> _getMemberOptions() => [
    const DashboardView(),
    const BookingScreen(),
    const TournamentListScreen(),
    const WalletScreen(),
    const ProfileScreen(),
  ];

  List<Widget> _getAdminOptions() => [
    const AdminDashboardScreen(),
    const TournamentListScreen(),
    const ManageDepositsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    if (!_isInit) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isAdmin = _role == 'Admin';
    final options = isAdmin ? _getAdminOptions() : _getMemberOptions();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF), // Light blue background
      body: options.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2))],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (i) => setState(() => _selectedIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primaryColor,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          elevation: 0,
          items: isAdmin
              ? const [
                  BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Tổng Quan'),
                  BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), activeIcon: Icon(Icons.emoji_events), label: 'Giải Đấu'),
                  BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Nạp Tiền'),
                  BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Tài Khoản'),
                ]
              : const [
                  BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Trang Chủ'),
                  BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), activeIcon: Icon(Icons.calendar_today), label: 'Đặt Sân'),
                  BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), activeIcon: Icon(Icons.emoji_events), label: 'Giải Đấu'),
                  BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_outlined), activeIcon: Icon(Icons.account_balance_wallet), label: 'Ví'),
                  BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Cá Nhân'),
                ],
        ),
      ),
    );
  }
}

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  
  String _name = 'Vợt Thủ';
  String _tier = 'Standard';
  double _rank = 2.5;
  double _walletBalance = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _loadUserData();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    // Determine context safely
    if (!mounted) return;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUser();

    final storage = const FlutterSecureStorage();
    try {
      final token = await storage.read(key: 'jwt_token');
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer $token';
      final response = await dio.get('${AppConstants.apiUrl}/members/me');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (mounted) {
            // Update provider
            userProvider.updateUser(
                name: data['fullName'],
                tier: (data['tier'] ?? 0) == 3 ? 'Diamond' : 
                      (data['tier'] ?? 0) == 2 ? 'Gold' : 
                      (data['tier'] ?? 0) == 1 ? 'Silver' : 'Standard'
            );
            userProvider.updateBalance((data['walletBalance'] ?? 0).toDouble());

          setState(() {
           _isLoading = false;
          });
          _animController.forward();
        }
        return;
      }
    } catch (e) {}
    
    if (mounted) {
      setState(() => _isLoading = false);
      _animController.forward();
    }
  }

  String _translateTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'diamond': return '💎 Kim Cương';
      case 'gold': return '🥇 Vàng';
      case 'silver': return '🥈 Bạc';
      default: return '⭐ Thường';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'vi', symbol: 'đ');
    
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFF), Color(0xFFEEF2FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== PREMIUM HEADER =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(32),
                  bottomRight: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(color: Color(0x40667EEA), blurRadius: 20, offset: Offset(0, 10)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row
                  // Top Row
                  Consumer<UserProvider>(
                    builder: (context, user, _) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Xin chào,', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 15)),
                            const SizedBox(height: 4),
                            Text('${user.name} 🏸', style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                          ],
                        ),
                      Row(
                        children: [
                          StreamBuilder<String>(
                            stream: SignalRService().notificationStream,
                            builder: (context, snapshot) {
                              final hasNew = snapshot.hasData;
                              return Badge(
                                isLabelVisible: hasNew,
                                label: const Text('!', style: TextStyle(color: Colors.white)),
                                child: _buildIconBtn(Icons.notifications_outlined, () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
                                }),
                              );
                            }
                          ),
                          const SizedBox(width: 10),
                          _buildIconBtn(Icons.logout_rounded, () {
                            AuthService().logout();
                            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                          }),
                        ],
                      ),
                    ],
                  ),
                ),

                  const SizedBox(height: 28),

                  // ===== WALLET CARD - GLASS EFFECT =====
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.white.withOpacity(0.25), Colors.white.withOpacity(0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)],
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF667EEA), size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Số dư ví', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 4),
                              _isLoading
                                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : Consumer<UserProvider>(
                                      builder: (context, user, _) => Text(
                                        currencyFormat.format(user.walletBalance),
                                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                        _buildActionBtn('Nạp tiền', () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ===== MEMBERSHIP CARD =====
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Text(_translateTier(_tier), style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('DUPR ${_rank.toStringAsFixed(1)}', style: const TextStyle(color: Color(0xFF764BA2), fontWeight: FontWeight.w700, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ===== RANK CHART =====
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                                Text('Lịch Sử Rank', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                                Icon(Icons.show_chart, color: Color(0xFF1E3A5F)),
                            ]
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 200,
                          child: LineChart(
                            LineChartData(
                              gridData: FlGridData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 10)))),
                                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                                  switch (value.toInt()) {
                                    case 0: return const Text('T1');
                                    case 2: return const Text('T3');
                                    case 4: return const Text('T5');
                                    case 6: return const Text('T7');
                                  }
                                  return const Text('');
                                })),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: 6,
                              minY: 0,
                              maxY: 5,
                              lineBarsData: [
                                LineChartBarData(
                                  spots: [
                                    const FlSpot(0, 2.0),
                                    const FlSpot(1, 2.2),
                                    const FlSpot(2, 2.5),
                                    const FlSpot(3, 2.8),
                                    const FlSpot(4, 3.0),
                                    const FlSpot(5, 3.5),
                                    FlSpot(6, _rank),
                                  ],
                                  isCurved: true,
                                  color: const Color(0xFF667EEA),
                                  barWidth: 3,
                                  isStrokeCapRound: true,
                                  dotData: FlDotData(show: true),
                                  belowBarData: BarAreaData(show: true, color: const Color(0xFF667EEA).withOpacity(0.1)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                    ],
                  ),
                ),

                  // ===== QUICK ACTIONS =====
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
              child: Row(
                children: [
                  const Text('Truy cập nhanh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1F36))),
                  const Spacer(),
                  Text('Xem tất cả', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                ],
              ),
            ),

            // ===== SERVICE CARDS GRID =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
                childAspectRatio: 1.05,
                children: [
                  _buildServiceCard('Giải Đấu', 'Tranh tài cùng CLB', Icons.emoji_events_rounded, const Color(0xFF8B5CF6), const Color(0xFFA78BFA), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TournamentListScreen()));
                  }),
                  _buildServiceCard('Đặt Sân', 'Linh hoạt & tiện lợi', Icons.calendar_month_rounded, const Color(0xFF06D6A0), const Color(0xFF34D399), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const BookingScreen()));
                  }),
                  _buildServiceCard('Huấn Luyện', 'Nâng cao kỹ năng', Icons.sports_tennis_rounded, const Color(0xFFF59E0B), const Color(0xFFFBBF24), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainingScreen()));
                  }),
                  _buildServiceCard('Tin Tức', 'Cập nhật mới nhất', Icons.newspaper_rounded, const Color(0xFFFF6B9D), const Color(0xFFFDA4AF), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsListScreen()));
                  }),
                  _buildServiceCard('Thách Đấu', 'Kèo 1vs1, 2vs2', Icons.sports_mma, const Color(0xFF6366F1), const Color(0xFF818CF8), () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DuelScreen()));
                  }),
                ],
              ),
            ),

            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }

  Widget _buildActionBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
        ),
        child: Text(label, style: const TextStyle(color: Color(0xFF667EEA), fontWeight: FontWeight.w700, fontSize: 13)),
      ),
    );
  }

  Widget _buildServiceCard(String title, String subtitle, IconData icon, Color color1, Color color2, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(color: color1.withOpacity(0.15), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color1, color2]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const Spacer(),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Color(0xFF1A1F36))),
            const SizedBox(height: 3),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

