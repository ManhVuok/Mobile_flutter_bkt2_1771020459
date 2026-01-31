import 'package:flutter/material.dart';
import 'package:mobile/data/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:mobile/data/services/signalr_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
    _initSignalR();
  }

  Future<void> _initSignalR() async {
    final token = await const FlutterSecureStorage().read(key: 'jwt_token');
    if (token != null) {
      final signalR = SignalRService();
      await signalR.init(token);
      signalR.messageStream.listen((data) {
        if (mounted && data.length >= 2) {
             final title = data[0];
             final message = data[1];
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('$title: $message'),
                backgroundColor: Colors.blueAccent,
             ));
             _loadData(); // Reload list
        }
      });
      // We might need a specific listenToNotification if implementation differs
    }
  }

  Future<void> _loadData() async {
    final data = await _service.getNotifications();
    if (mounted) {
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    }
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'Success': return Icons.check_circle;
      case 'Warning': return Icons.warning;
      case 'Reminder': return Icons.alarm;
      default: return Icons.notifications;
    }
  }

  Color _getColor(String? type) {
    switch (type) {
      case 'Success': return Colors.green;
      case 'Warning': return Colors.orange;
      case 'Reminder': return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Thông Báo', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1a1a2e))),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1a1a2e)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text('Chưa có thông báo', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final bool isRead = n['isRead'] == true;
                      final type = n['type'] ?? 'Info';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: isRead ? null : Border.all(color: const Color(0xFF00d9ff).withOpacity(0.5)),
                        ),
                        child: ListTile(
                          onTap: () {
                            _service.markAsRead(n['id']);
                            setState(() => n['isRead'] = true);
                          },
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _getColor(type).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(_getIcon(type), color: _getColor(type), size: 20),
                          ),
                          title: Text(
                            n['message'] ?? '',
                            style: TextStyle(
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(n['createdDate']).toLocal()),
                              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                            ),
                          ),
                          trailing: !isRead
                              ? Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(color: Color(0xFF00d9ff), shape: BoxShape.circle),
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
