import 'package:flutter/material.dart';
import 'package:mobile/data/services/profile_service.dart';

class MembersListScreen extends StatefulWidget {
  const MembersListScreen({super.key});

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  final _service = ProfileService();
  
  static const Color primaryColor = Color(0xFF667EEA);
  static const Color secondaryColor = Color(0xFF764BA2);
  
  List<dynamic> _members = [];
  List<dynamic> _filteredMembers = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.getMembers();
    if (mounted) {
      setState(() {
        _members = data;
        _filteredMembers = data;
        _isLoading = false;
      });
    }
  }

  void _filterMembers(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredMembers = _members;
      } else {
        _filteredMembers = _members.where((m) {
          final name = (m['fullName'] ?? '').toString().toLowerCase();
          final email = (m['email'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase()) || email.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  String _getTierText(int tier) {
    switch (tier) {
      case 3: return 'Kim Cương';
      case 2: return 'Vàng';
      case 1: return 'Bạc';
      default: return 'Thường';
    }
  }

  Color _getTierColor(int tier) {
    switch (tier) {
      case 3: return const Color(0xFF8B5CF6);
      case 2: return const Color(0xFFF59E0B);
      case 1: return const Color(0xFF94A3B8);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        title: const Text('Danh Sách Hội Viên', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A5F)),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterMembers,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm hội viên...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF0F9FF),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          
          // Member Count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_filteredMembers.length} hội viên',
                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          
          // Members List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMembers.isEmpty
                    ? const Center(child: Text('Không tìm thấy hội viên'))
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredMembers.length,
                          itemBuilder: (context, index) {
                            final member = _filteredMembers[index];
                            final tier = member['tier'] ?? 0;
                            final rank = (member['rankLevel'] ?? 2.5).toDouble();
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(12),
                                leading: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: primaryColor.withOpacity(0.1),
                                  backgroundImage: member['avatarUrl'] != null
                                      ? NetworkImage(member['avatarUrl'])
                                      : null,
                                  child: member['avatarUrl'] == null
                                      ? Text(
                                          (member['fullName'] ?? 'U')[0].toUpperCase(),
                                          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 18),
                                        )
                                      : null,
                                ),
                                title: Text(
                                  member['fullName'] ?? 'Hội viên',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(member['email'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: _getTierColor(tier),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            _getTierText(tier),
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: primaryColor,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            'DUPR ${rank.toStringAsFixed(1)}',
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: Icon(Icons.chevron_right, color: Colors.grey.shade400),
                                onTap: () {
                                  _showMemberDetail(member);
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showMemberDetail(dynamic member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Avatar
            CircleAvatar(
              radius: 50,
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Text(
                (member['fullName'] ?? 'U')[0].toUpperCase(),
                style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 36),
              ),
            ),
            const SizedBox(height: 16),
            
            // Name
            Text(
              member['fullName'] ?? 'Hội viên',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F)),
            ),
            const SizedBox(height: 4),
            Text(member['email'] ?? '', style: TextStyle(color: Colors.grey.shade600)),
            
            const SizedBox(height: 20),
            
            // Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatItem('DUPR', (member['rankLevel'] ?? 2.5).toDouble().toStringAsFixed(1)),
                  _buildStatItem('Hạng', _getTierText(member['tier'] ?? 0)),
                  _buildStatItem('Tham gia', _formatDate(member['joinDate'])),
                ],
              ),
            ),
            
            const Spacer(),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Đóng', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}
