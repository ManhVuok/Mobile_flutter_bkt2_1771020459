import 'package:signalr_core/signalr_core.dart';
import 'package:mobile/core/constants.dart';
import 'dart:async';

class SignalRService {
  HubConnection? _hubConnection;
  
  // Singleton
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

  // Streams
  final _calendarUpdateController = StreamController<void>.broadcast();
  Stream<void> get calendarUpdateStream => _calendarUpdateController.stream;

  final _messageController = StreamController<List<String>>.broadcast();
  Stream<List<String>> get messageStream => _messageController.stream;

  final _notificationController = StreamController<String>.broadcast();
  Stream<String> get notificationStream => _notificationController.stream;

  Future<void> init(String token) async {
    if (_hubConnection?.state == HubConnectionState.connected) return;

    final hubUrl = '${AppConstants.apiUrl.replaceAll('/api', '')}/pcmHub';
    
    _hubConnection = HubConnectionBuilder()
        .withUrl(hubUrl, HttpConnectionOptions(
          accessTokenFactory: () async => token,
          logging: (level, message) => print(message),
        ))
        .withAutomaticReconnect()
        .build();

    _hubConnection?.on('UpdateCalendar', (arguments) {
      print("SignalR: Received UpdateCalendar");
      _calendarUpdateController.add(null);
    });
    
    _hubConnection?.on('ReceiveNotification', (arguments) {
        if(arguments != null && arguments.isNotEmpty) {
           final msg = arguments[0].toString();
           print("SignalR: Received Notification: $msg");
           _notificationController.add(msg);
        }
    });

    _hubConnection?.on('ReceiveMessage', (arguments) {
        if(arguments != null && arguments.length >= 2) {
           _messageController.add([arguments[0].toString(), arguments[1].toString()]);
        }
    });

    try {
      await _hubConnection?.start();
      print("SignalR Connected");
    } catch (e) {
      print("SignalR Connection Error: $e");
    }
  }

  Future<void> joinGroup(int matchId) async {
    await _hubConnection?.invoke('JoinMatchGroup', args: [matchId]);
  }
  
  Future<void> leaveGroup(int matchId) async {
    await _hubConnection?.invoke('LeaveMatchGroup', args: [matchId]);
  }

  Future<void> sendMessage(int matchId, String sender, String message) async {
    await _hubConnection?.invoke('SendMessage', args: [matchId, sender, message]);
  }
}
