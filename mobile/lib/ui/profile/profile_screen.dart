import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mobile/data/services/auth_service.dart';
import 'package:mobile/ui/auth/login_screen.dart';
import 'package:mobile/ui/members/members_list_screen.dart';
import 'package:mobile/data/services/cache_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _storage = const FlutterSecureStorage();
  
  static const Color primaryColor = Color(0xFF667EEA);
  static const Color secondaryColor = Color(0xFF764BA2);
  
  String _name = '';
  String _email = '';
  String _role = '';
  String _tier = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }



  Future<void> _loadProfile() async {
    // Try to load from cache first
    final cachedProfile = CacheService().getUserProfile();
    if (cachedProfile != null) {
      setState(() {
        _name = cachedProfile['name'] ?? '';
        _email = cachedProfile['email'] ?? '';
        _role = cachedProfile['role'] ?? 'Member';
        _tier = cachedProfile['tier'] ?? 'Standard';
      });
    }

    // Then load from secure storage (source of truth for session) and update cache
    final name = await _storage.read(key: 'user_name') ?? 'Người dùng';
    final email = await _storage.read(key: 'user_email') ?? '';
    final role = await _storage.read(key: 'user_role') ?? 'Member';
    final tier = await _storage.read(key: 'user_tier') ?? 'Standard';
    
    // Update cache
    await CacheService().cacheUserProfile({
      'name': name,
      'email': email,
      'role': role,
      'tier': tier,
    });

    if (mounted) {
      setState(() {
        _name = name;
        _email = email;
        _role = role;
        _tier = tier;
      });
    }
  }

  String _translateTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'diamond': return 'Kim Cương';
      case 'gold': return 'Vàng';
      case 'silver': return 'Bạc';
      default: return 'Thường';
    }
  }

  String _translateRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return 'Quản trị viên';
      case 'treasurer': return 'Thủ quỹ';
      case 'referee': return 'Trọng tài';
      default: return 'Hội viên';
    }
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Đăng Xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () {
              AuthService().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng Xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        title: const Text('Tài Khoản', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white24,
                    child: Text(
                      _name.isNotEmpty ? _name[0].toUpperCase() : 'U',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(_email, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildBadge(_translateRole(_role), secondaryColor),
                      const SizedBox(width: 8),
                      _buildBadge(_translateTier(_tier), const Color(0xFFF59E0B)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Menu Items
            _buildMenuItem(Icons.person_outline, 'Thông tin cá nhân', () {}),
            _buildMenuItem(Icons.people_outline, 'Danh sách Hội viên', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MembersListScreen()));
            }),
            _buildMenuItem(Icons.history, 'Lịch sử đặt sân', () {}),
            _buildMenuItem(Icons.emoji_events_outlined, 'Giải đấu đã tham gia', () {}),
            _buildMenuItem(Icons.settings_outlined, 'Cài đặt', () {}),
            _buildMenuItem(Icons.help_outline, 'Trợ giúp', () {}),
            _buildMenuItem(Icons.logout, 'Đăng xuất', _logout, isDestructive: true),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: isDestructive ? Colors.red : primaryColor),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: isDestructive ? Colors.red : const Color(0xFF1E3A5F))),
        trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
