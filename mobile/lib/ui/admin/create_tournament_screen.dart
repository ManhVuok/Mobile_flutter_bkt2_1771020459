import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile/data/services/tournament_service.dart';
import 'package:mobile/ui/theme/app_theme.dart';

class CreateTournamentScreen extends StatefulWidget {
  const CreateTournamentScreen({super.key});

  @override
  State<CreateTournamentScreen> createState() => _CreateTournamentScreenState();
}

class _CreateTournamentScreenState extends State<CreateTournamentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _feeController = TextEditingController();
  final _prizeController = TextEditingController();
  
  DateTime _startDate = DateTime.now().add(const Duration(days: 7));
  DateTime _endDate = DateTime.now().add(const Duration(days: 14));
  int _format = 0; // 0: Knockout, 1: RoundRobin
  bool _isLoading = false;
  final _tournamentService = TournamentService();

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
           if (_endDate.isBefore(_startDate)) _endDate = _startDate.add(const Duration(days: 1));
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      final data = {
        'name': _nameController.text,
        'startDate': _startDate.toIso8601String(),
        'endDate': _endDate.toIso8601String(),
        'format': _format,
        'entryFee': int.parse(_feeController.text),
        'prizePool': int.parse(_prizeController.text),
      };

      final error = await _tournamentService.createTournament(data);
      
      if (mounted) {
        setState(() => _isLoading = false);
        if (error == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tạo giải đấu thành công!')));
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $error'), backgroundColor: Colors.red));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo Giải Đấu Mới')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên Giải Đấu', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Ngày Bắt Đầu', border: OutlineInputBorder()),
                        child: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'Ngày Kết Thúc', border: OutlineInputBorder()),
                        child: Text(DateFormat('dd/MM/yyyy').format(_endDate)),
                      ),
                    ),
                  ),
                ],
              ),
               const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _format,
                decoration: const InputDecoration(labelText: 'Hình Thức Thi Đấu', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Loại Trực Tiếp (Knockout)')),
                  DropdownMenuItem(value: 1, child: Text('Vòng Tròn (Round Robin)')),
                ],
                onChanged: (v) => setState(() => _format = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _feeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Lệ Phí Tham Gia (VNĐ)', border: OutlineInputBorder(), suffixText: 'đ'),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập lệ phí' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _prizeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Tổng Giải Thưởng (VNĐ)', border: OutlineInputBorder(), suffixText: 'đ'),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập giải thưởng' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('TẠO GIẢI ĐẤU', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
