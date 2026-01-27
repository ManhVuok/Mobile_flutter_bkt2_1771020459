import 'package:flutter/material.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        title: const Text('Chợ Pickleball', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF0F7FF),
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm vợt, bóng, phụ kiện...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Vợt Pickleball Hot', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.7,
              children: [
                _buildProductCard(context, 'Selkirk Invikta', '5.200.000đ', 'https://picsum.photos/400/400?sig=v1'),
                _buildProductCard(context, 'Joola Perseus', '4.800.000đ', 'https://picsum.photos/400/400?sig=v2'),
                _buildProductCard(context, 'Bóng Franklin X-40', '150.000đ', 'https://picsum.photos/400/400?sig=v3'),
                _buildProductCard(context, 'Túi đựng vợt PCM', '850.000đ', 'https://picsum.photos/400/400?sig=v4'),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, String name, String price, String img) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.network(img, width: double.infinity, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(price, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: const Text('Thông báo'),
                          content: const Text('Tính năng mua sắm trực tuyến đang được phát triển. Vui lòng ghé thăm cửa hàng trực tiếp tại CLB!'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))
                          ],
                        )
                      );
                    }, 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                    ),
                    child: const Text('MUA NGAY', style: TextStyle(fontSize: 11)),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
