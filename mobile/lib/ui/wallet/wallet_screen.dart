import 'package:flutter/material.dart';
import 'package:mobile/data/services/wallet_service.dart';
import 'package:intl/intl.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final _service = WalletService();
  final _formatter = NumberFormat.currency(locale: 'vi', symbol: 'đ');

  // Premium Color Scheme
  static const Color primaryColor = Color(0xFF667EEA);
  static const Color secondaryColor = Color(0xFF764BA2);
  static const Color accentColor = Color(0xFF06D6A0);

  double _balance = 0;
  String _tier = 'Thành Viên';
  List<dynamic> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.getWalletData();
    if (mounted && data != null) {
      setState(() {
        _balance = (data['balance'] as num?)?.toDouble() ?? 0;
        _tier = data['tier'] ?? 'Thành Viên';
        _transactions = data['transactions'] ?? [];
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showDepositDialog() {
    final amountController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nạp Tiền', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
            const SizedBox(height: 8),
            Text('Nhập số tiền bạn muốn nạp vào ví.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
            const SizedBox(height: 20),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Số tiền (VNĐ)',
                hintText: '100000',
                prefixIcon: const Icon(Icons.attach_money, color: primaryColor),
                filled: true,
                fillColor: const Color(0xFFF0F9FF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primaryColor, width: 2)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  final amount = double.tryParse(amountController.text) ?? 0;
                  if (amount < 10000) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Số tiền tối thiểu 10.000đ'), backgroundColor: Colors.orange),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  _showQRCodeDialog(amount);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('XÁC NHẬN NẠP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCodeDialog(double amount) {
    final formattedAmount = _formatter.format(amount);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_scanner, size: 40, color: primaryColor),
              const SizedBox(height: 8),
              const Text('Quét Mã QR Để Thanh Toán', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
              const SizedBox(height: 4),
              Text('Số tiền: $formattedAmount', style: const TextStyle(fontSize: 14, color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              
              // QR Code Container
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 15),
                            itemCount: 225,
                            itemBuilder: (context, index) {
                              final isBlack = (index % 3 == 0 || index % 7 == 0 || index < 45 || index > 180 || index % 15 < 3 || index % 15 > 11);
                              return Container(color: isBlack ? primaryColor : Colors.white);
                            },
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
                            child: const Icon(Icons.sports_tennis, color: primaryColor, size: 24),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('PICKLEBALL CLUB', style: TextStyle(color: Colors.grey.shade600, fontSize: 11, letterSpacing: 1)),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F9FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildBankInfoRow('Ngân hàng', 'MB Bank'),
                    const Divider(height: 16),
                    _buildBankInfoRow('Số TK', '0123456789'),
                    const Divider(height: 16),
                    _buildBankInfoRow('Chủ TK', 'CLB PICKLEBALL'),
                    const Divider(height: 16),
                    _buildBankInfoRow('Nội dung', 'NAP ${amount.toInt()}'),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final success = await _service.deposit(amount.toInt(), 'Nạp tiền vào ví', null);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(success ? 'Yêu cầu nạp tiền đã gửi! Chờ Admin duyệt.' : 'Có lỗi xảy ra'),
                              backgroundColor: success ? Colors.green : Colors.red,
                            ),
                          );
                          if (success) _loadData();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('ĐÃ CHUYỂN KHOẢN', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              SizedBox(height: MediaQuery.of(ctx).padding.bottom + 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F9FF),
      appBar: AppBar(
        title: const Text('Ví Điện Tử', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1E3A5F)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Balance Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.account_balance_wallet, color: Colors.white, size: 22),
                              const SizedBox(width: 8),
                              Text('Số Dư', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(12)),
                                child: Text(_tier, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(_formatter.format(_balance), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(child: _buildActionButton('Nạp tiền', Icons.add_circle_outline, primaryColor, _showDepositDialog)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildActionButton('Lịch sử', Icons.history, secondaryColor, () {})),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Transactions
                    const Text('Giao Dịch Gần Đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E3A5F))),
                    const SizedBox(height: 12),

                    if (_transactions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                        child: const Center(child: Text('Chưa có giao dịch', style: TextStyle(color: Colors.grey))),
                      ),

                    ..._transactions.take(10).map((t) => _buildTransactionItem(t)).toList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(dynamic t) {
    final isDeposit = t['type'] == 'Nạp';
    final amount = (t['amount'] as num?)?.toDouble() ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDeposit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isDeposit ? Icons.arrow_downward : Icons.arrow_upward,
              color: isDeposit ? Colors.green : Colors.red,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t['description'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(t['createdDate']).toLocal()),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${isDeposit ? '+' : '-'}${_formatter.format(amount.abs())}',
            style: TextStyle(fontWeight: FontWeight.bold, color: isDeposit ? Colors.green : Colors.red, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
