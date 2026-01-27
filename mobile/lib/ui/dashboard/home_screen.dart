import 'package:flutter/material.dart';
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
import 'package:mobile/ui/shop/shop_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _role = 'Member';
  bool _isInit = false;

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> _getMemberOptions() => [
    const DashboardView(),
    const BookingScreen(),
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
      backgroundColor: const Color(0xFFF0F7FF), // Light professional blue background
      body: options.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          items: isAdmin 
            ? const <BottomNavigationBarItem>[
                BottomNavigationBarItem(icon: Icon(Icons.admin_panel_settings), label: 'Tổng Quan'),
                BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Giải Đấu'),
                BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Nạp Tiền'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Admin'),
              ]
            : const <BottomNavigationBarItem>[
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Trang Chủ'),
                BottomNavigationBarItem(icon: Icon(Icons.sports_tennis_rounded), label: 'Đặt Sân'),
                BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet_rounded), label: 'Ví'),
                BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Cá Nhân'),
              ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF0277BD), // Deep professional blue
          unselectedItemColor: Colors.blueGrey.shade300,
          showUnselectedLabels: false,
          type: BottomNavigationBarType.fixed,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F7FF), // Light Blue Background
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0288D1), Color(0xFF03A9F4)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Xin chào,', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    Text('Vợt Thủ', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.white),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () {
                        AuthService().logout();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
          
          // Rank Card
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade100, width: 1.5),
                boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 20, offset: Offset(0, 10))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(color: Colors.orange.shade100, shape: BoxShape.circle),
                    child: const Icon(Icons.emoji_events, color: Colors.orange, size: 30),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hạng Thành Viên', style: TextStyle(color: Colors.grey)),
                      Text('Gold Member', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Spacer(),
                  const Text('DUPR 3.5', style: TextStyle(color: Color(0xFF1A237E), fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text('Dịch Vụ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          
          const SizedBox(height: 16),

          // Grid Menu
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TournamentListScreen())),
                child: _buildMenuCard(context, 'Giải Đấu', Icons.emoji_events_outlined, Colors.purple)
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrainingScreen())),
                child: _buildMenuCard(context, 'Huấn Luyện', Icons.sports_handball_outlined, Colors.teal)
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewsListScreen())),
                child: _buildMenuCard(context, 'Tin Tức', Icons.newspaper_outlined, Colors.blue)
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen())),
                child: _buildMenuCard(context, 'Cửa Hàng', Icons.shopping_bag_outlined, Colors.orange)
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
