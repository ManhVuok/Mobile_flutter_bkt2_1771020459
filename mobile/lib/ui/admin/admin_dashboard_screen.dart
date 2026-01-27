import 'package:flutter/material.dart';
import 'package:mobile/ui/admin/manage_bookings_screen.dart';
import 'package:mobile/ui/admin/manage_deposits_screen.dart';
import 'package:mobile/ui/tournament/tournament_list_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        title: const Text('Quản Trị Hệ Thống', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFFF0F7FF),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tổng Quan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _buildStatCard('Doanh Thu', '45.2Mđ', Icons.payments, Colors.green)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Đặt Sân', '128', Icons.calendar_today, Colors.blue)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatCard('Thành Viên', '1,024', Icons.people, Colors.orange)),
                const SizedBox(width: 16),
                Expanded(child: _buildStatCard('Giải Đấu', '5', Icons.emoji_events, Colors.purple)),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Hành Động Nhanh', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildActionTile(
              context, 
              'Phê Duyệt Nạp Tiền', 
              'Có 12 yêu cầu đang chờ', 
              Icons.account_balance_wallet, 
              Colors.indigo,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageDepositsScreen()))
            ),
            _buildActionTile(
              context, 
              'Quản Lý Đặt Sân', 
              'Xem và hủy lịch đặt sân', 
              Icons.edit_calendar, 
              Colors.deepOrange,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageBookingsScreen()))
            ),
            _buildActionTile(
              context, 
              'Quản Lý Giải Đấu', 
              'Tạo và chỉnh sửa giải đấu', 
              Icons.emoji_events, 
              Colors.amber.shade700,
              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TournamentListScreen()))
            ),
            _buildActionTile(
              context, 
              'Báo Cáo Doanh Thu', 
              'Xuất file Excel báo cáo tháng', 
              Icons.summarize, 
              Colors.teal,
              () {}
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 1)),
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(subtitle, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
