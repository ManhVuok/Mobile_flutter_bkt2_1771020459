import 'package:signalr_core/signalr_core.dart';
import 'package:mobile/core/constants.dart';

class SignalRService {
  HubConnection? _hubConnection;
  
  // Singleton
  static final SignalRService _instance = SignalRService._internal();
  factory SignalRService() => _instance;
  SignalRService._internal();

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
      _onCalendarUpdate?.call();
    });
    
    _hubConnection?.on('ReceiveNotification', (arguments) {
        if(arguments != null && arguments.isNotEmpty) {
           print("SignalR: Received Notification: ${arguments[0]}");
        }
    });

    _hubConnection?.on('ReceiveMessage', (arguments) {
        if(arguments != null && arguments.length >= 2) {
           _onMessageReceived?.call(arguments[0], arguments[1]);
        }
    });

    try {
      await _hubConnection?.start();
      print("SignalR Connected");
    } catch (e) {
      print("SignalR Connection Error: $e");
    }
  }

  Function? _onCalendarUpdate;
  void listenToCalendarUpdate(Function callback) {
    _onCalendarUpdate = callback;
  }

  Function? _onMessageReceived;
  void listenToMessage(Function(String, String) callback) {
    _onMessageReceived = callback;
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
