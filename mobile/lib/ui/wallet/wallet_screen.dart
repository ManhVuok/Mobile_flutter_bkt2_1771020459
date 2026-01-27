import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/data/services/wallet_service.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  final _walletService = WalletService();
  
  double _balance = 0;
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _walletService.getWalletData();
    if (mounted && data != null) {
      setState(() {
        _balance = (data['balance'] as num).toDouble();
        _transactions = data['transactions'];
        _isLoading = false;
      });
    }
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F7FF),
      appBar: AppBar(
        title: const Text('Ví Tài Chính', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: const Color(0xFFF0F7FF),
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadData,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Glassmorphism Card
                  _buildGlassCard(),
                  const SizedBox(height: 40),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionItem('Nạp Tiền', Icons.account_balance_wallet_rounded, Colors.indigo, _showDepositDialog),
                      _buildActionItem('Rút Tiền', Icons.payments_rounded, Colors.orange, () {}),
                      _buildActionItem('Quét Mã', Icons.qr_code_scanner_rounded, Colors.teal, () {}),
                      _buildActionItem('Thống Kê', Icons.bar_chart_rounded, Colors.purple, () {}),
                    ],
                  ),
                  const SizedBox(height: 40),
                  const Text('Giao Dịch Gần Đây', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF263238))),
                  const SizedBox(height: 16),
                  
                  // Transaction List
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final tx = _transactions[index];
                      return _buildTransactionItem(tx);
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildGlassCard() {
    return Container(
      width: double.infinity,
      height: 220,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [const Color(0xFF1A237E), const Color(0xFF3949AB), Colors.indigo.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 15))
        ],
      ),
      child: Stack(
        children: [
          Positioned(right: -20, bottom: -20, child: Icon(Icons.blur_circular, size: 200, color: Colors.white.withOpacity(0.1))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('DIAMOND MEMBER', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
                  Icon(Icons.nfc_rounded, color: Colors.white.withOpacity(0.5)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Số dư hiện tại', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(_formatter.format(_balance), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('PCM-FLUTTER-EDITION', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const Icon(Icons.credit_card_rounded, color: Colors.white, size: 24),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF455A64))),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(dynamic tx) {
    final bool isPositive = (tx['amount'] as num) > 0;
    final date = DateTime.parse(tx['createdDate']).toLocal();
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isPositive ? Colors.green.shade50 : Colors.red.shade50, borderRadius: BorderRadius.circular(15)),
            child: Icon(isPositive ? Icons.add_rounded : Icons.remove_rounded, color: isPositive ? Colors.green : Colors.red),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tx['description'] ?? 'Thanh toán', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF37474F))),
                const SizedBox(height: 4),
                Text(DateFormat('dd MMM, HH:mm').format(date), style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              ],
            ),
          ),
          Text(
            _formatter.format(tx['amount']),
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isPositive ? Colors.green.shade700 : Colors.red.shade700),
          ),
        ],
      ),
    );
  }

  void _showDepositDialog() {
    final amountController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(28, 32, 28, MediaQuery.of(ctx).viewInsets.bottom + 40),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nạp Tiền Vào Ví', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Yêu cầu sẽ được gửi tới Admin phê duyệt', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số tiền muốn nạp (đ)',
                prefixIcon: const Icon(Icons.payments_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF1A237E), width: 2)),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () async {
                  int amount = int.tryParse(amountController.text) ?? 0;
                  if (amount > 0) {
                     await _walletService.deposit(amount, 'Nạp tiền QR');
                     if(mounted) {
                       Navigator.pop(ctx);
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Yêu cầu nạp tiền đã được gửi! ✅')));
                       _loadData();
                     }
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A237E), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: const Text('GỬI YÊU CẦU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
