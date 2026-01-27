import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:mobile/core/constants.dart';
import 'package:intl/intl.dart';

class NewsListScreen extends StatefulWidget {
  const NewsListScreen({super.key});

  @override
  State<NewsListScreen> createState() => _NewsListScreenState();
}

class _NewsListScreenState extends State<NewsListScreen> {
  final Dio _dio = Dio();
  List<dynamic> _newsList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    try {
      final response = await _dio.get('${AppConstants.apiUrl}/news');
      setState(() {
        _newsList = response.data;
        _isLoading = false;
      });
    } catch (e) {
      if(mounted) {
        setState(() => _isLoading = false);
        // Mock data for demo if backend news is empty
        _newsList = [
          {'title': 'Chào mừng sân Pickleball PCM khai trương!', 'content': 'Giảm giá 50% cho tất cả các giờ đặt sân trong tuần đầu tiên khai trương...', 'publishDate': DateTime.now().toIso8601String(), 'imageUrl': 'https://picsum.photos/800/400?sig=1'},
          {'title': 'Giải đấu Summer Open 2026 chính thức mở đăng ký', 'content': 'Tổng giải thưởng lên tới 50 triệu đồng. Các vđv có chỉ số DUPR từ 3.0 trở lên có thể đăng ký...', 'publishDate': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(), 'imageUrl': 'https://picsum.photos/800/400?sig=2'},
          {'title': 'Kỹ thuật đánh Forehand cực đỉnh từ HLV chuyên nghiệp', 'content': 'Trong bài viết này, HLV Nguyễn Văn A sẽ chia sẻ bí quyết để có cú thuận tay uy lực...', 'publishDate': DateTime.now().subtract(const Duration(days: 5)).toIso8601String(), 'imageUrl': 'https://picsum.photos/800/400?sig=3'},
        ];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        title: const Text('Tin Tức PCM', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F7FF),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _newsList.length,
            itemBuilder: (context, index) {
              final news = _newsList[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: Image.network(
                        news['imageUrl'] ?? 'https://picsum.photos/800/400?news',
                        height: 180, width: double.infinity, fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                child: const Text('SỰ KIỆN', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              const Spacer(),
                              Text(DateFormat('dd MMM, yyyy').format(DateTime.parse(news['publishDate'])), style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(news['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
                          const SizedBox(height: 8),
                          Text(news['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, height: 1.5)),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (ctx) => Container(
                                  height: MediaQuery.of(context).size.height * 0.85,
                                  decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                                  padding: const EdgeInsets.all(24),
                                  child: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
                                        const SizedBox(height: 24),
                                        ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(news['imageUrl'] ?? '', height: 200, width: double.infinity, fit: BoxFit.cover)),
                                        const SizedBox(height: 24),
                                        Text(news['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 16),
                                        Text(news['content'], style: TextStyle(fontSize: 16, height: 1.6, color: Colors.grey.shade800)),
                                      ],
                                    ),
                                  ),
                                )
                              );
                            }, 
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                            child: const Row(mainAxisSize: MainAxisSize.min, children: [Text('Đọc tiếp', style: TextStyle(fontWeight: FontWeight.bold)), Icon(Icons.arrow_right_alt, size: 20)])
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
    );
  }
}
