import 'package:flutter/material.dart';
import 'package:mobile/data/services/notification_service.dart';
import 'package:intl/intl.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _service = NotificationService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _service.getNotifications();
    if(mounted) {
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thông báo")),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.separated(
            itemCount: _notifications.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final n = _notifications[index];
              return ListTile(
                leading: Icon(
                  n['type'] == 'Success' ? Icons.check_circle : Icons.info,
                  color: n['type'] == 'Success' ? Colors.green : Colors.blue
                ),
                title: Text(n['message'], style: TextStyle(fontWeight: n['isRead'] ? FontWeight.normal : FontWeight.bold)),
                subtitle: Text(DateFormat('dd/MM HH:mm').format(DateTime.parse(n['createdDate']).toLocal())),
                onTap: () {
                   _service.markAsRead(n['id']);
                   setState(() {
                     n['isRead'] = true;
                   });
                },
              );
            },
        ),
    );
  }
}
