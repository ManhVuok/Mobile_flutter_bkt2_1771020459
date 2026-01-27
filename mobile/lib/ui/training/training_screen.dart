import 'package:flutter/material.dart';

class TrainingScreen extends StatelessWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        title: const Text('Huấn Luyện - Coaching', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F7FF),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Huấn Luyện Viên Hàng Đầu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildCoachCard(
              context,
              'HLV Nguyễn Văn A', 
              'Hơn 10 năm kinh nghiệm thi đấu chuyên nghiệp. Chuyên về kỹ năng volley và chiến thuật đôi.', 
              '4.8 (120 đánh giá)', 
              '200.000đ/giờ', 
              'https://i.pravatar.cc/150?u=coach1'
            ),
            const SizedBox(height: 16),
            _buildCoachCard(
              context,
              'HLV Trần Thị B', 
              'Vô địch giải Open 2025. Chuyên đào tạo học viên mới bắt đầu và kỹ thuật Forehand.', 
              '4.9 (85 đánh giá)', 
              '250.000đ/giờ', 
              'https://i.pravatar.cc/150?u=coach2'
            ),
            const SizedBox(height: 32),
            const Text('Khóa Học Gần Đây', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildCourseCard('Cơ bản cho người mới', '8 buổi - 1.500.000đ', Colors.blue),
            const SizedBox(height: 12),
            _buildCourseCard('Chiến thuật Pickleball nâng cao', '4 buổi - 1.200.000đ', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachCard(BuildContext context, String name, String bio, String rating, String price, String img) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          CircleAvatar(radius: 40, backgroundImage: NetworkImage(img)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 4),
                Text(bio, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(rating, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    Text(price, style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                       showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('Liên hệ HLV'),
                          content: Text('Bạn muốn đặt lịch với $name?\nVui lòng liên hệ hotline: 1900 1234 để được xếp lịch sớm nhất.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
                            ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Gọi ngay'))
                          ],
                        )
                      );
                    }, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0288D1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    child: const Text('ĐẶT LỊCH NGAY'),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCourseCard(String title, String detail, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
          const SizedBox(height: 4),
          Text(detail, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
