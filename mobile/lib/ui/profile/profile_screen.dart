import 'package:flutter/material.dart';
import 'package:mobile/data/services/profile_service.dart';
import 'package:intl/intl.dart';

import 'package:mobile/data/services/auth_service.dart';
import 'package:mobile/ui/auth/login_screen.dart';
import 'package:mobile/ui/admin/admin_dashboard_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = ProfileService();
  dynamic _profile;
  bool _isLoading = true;
  String _role = 'Member';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.getMyProfile();
    final role = await const FlutterSecureStorage().read(key: 'user_role');
    if(mounted) {
      setState(() {
        _profile = data;
        _role = role ?? 'Member';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_profile == null) return const Scaffold(body: Center(child: Text("Lỗi tải thông tin")));

    final bool isAdmin = _role == 'Admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        title: const Text("Hồ Sơ Cá Nhân", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar Section
            _buildAvatarSection(),
            const SizedBox(height: 32),
            
            // Info Sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                   _buildProfileCard(
                    Icons.workspace_premium_rounded, 
                    "Hạng Thành Viên", 
                    _getTierName(_profile['tier']), 
                    color: _getTierColor(_profile['tier'])
                  ),
                  _buildProfileCard(Icons.leaderboard_rounded, "Chỉ số DUPR", "${_profile['rankLevel'] ?? 1.0}", color: Colors.blue),
                  _buildProfileCard(Icons.calendar_today_rounded, "Ngày tham gia", DateFormat('dd/MM/yyyy').format(DateTime.parse(_profile['joinDate'])), color: Colors.indigo),
                  _buildProfileCard(Icons.email_outlined, "Email", _profile['email'] ?? '', color: Colors.grey),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  if (isAdmin)
                    _buildFullWidthButton("BẢNG ĐIỀU KHIỂN QUẢN TRỊ", Icons.admin_panel_settings_rounded, Colors.red.shade700, () {
                       Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                    }),
                  const SizedBox(height: 12),
                  _buildFullWidthButton("CHỈNH SỬA THÔNG TIN", Icons.edit_rounded, const Color(0xFF1A237E), () {}),
                  const SizedBox(height: 12),
                  _buildFullWidthButton("ĐĂNG XUẤT", Icons.logout_rounded, Colors.grey.shade700, () {
                    AuthService().logout();
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                  }),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0xFF1A237E), width: 2)),
          child: const CircleAvatar(
            radius: 60,
            backgroundImage: NetworkImage('https://i.pravatar.cc/300'),
          ),
        ),
        const SizedBox(height: 16),
        Text(_profile['fullName'] ?? 'Người Dùng', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF1A237E))),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: _getTierColor(_profile['tier']).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Text(
            _getTierName(_profile['tier']).toUpperCase(), 
            style: TextStyle(color: _getTierColor(_profile['tier']), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)
          ),
        )
      ],
    );
  }

  Widget _buildProfileCard(IconData icon, String title, String value, {required Color color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade50),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF263238))),
        ],
      ),
    );
  }

  Widget _buildFullWidthButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  Color _getTierColor(int tier) {
     switch(tier) {
       case 0: return Colors.brown;
       case 1: return Colors.blueGrey;
       case 2: return Colors.orange;
       case 3: return Colors.cyan.shade700;
       default: return Colors.grey;
     }
  }

  String _getTierName(int tier) {
     switch(tier) {
       case 0: return "Standard";
       case 1: return "Silver";
       case 2: return "Gold";
       case 3: return "Diamond";
       default: return "Unknown";
     }
  }
}
