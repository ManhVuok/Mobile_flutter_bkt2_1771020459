import 'package:flutter/material.dart';
import 'package:mobile/data/services/signalr_service.dart';
import 'package:mobile/data/services/profile_service.dart';

class ChatScreen extends StatefulWidget {
  final int tournamentId; // Or MatchId? Requirement says "Chat for Tournament" but SignalR implemented MatchGroup. We can use TournamentId as MatchId for this demo or specific Match.
  // Requirement: "Phòng chat cho mỗi giải đấu". 
  // Code changes: PcmHub used "Match_id". 
  // Let's assume we chat in a "Lobby" for the Tournament. 
  // We will map TournamentId to MatchId logic just for demo (or assume id is same).
  
  const ChatScreen({super.key, required this.tournamentId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final _signalR = SignalRService();
  String _myNames = "Me";

  @override
  void initState() {
    super.initState();
    _initChat();
  }

  void _initChat() async {
    // Join Group
    await _signalR.joinGroup(widget.tournamentId);
    
    // Get My Name
    final profile = await ProfileService().getMyProfile();
    if(profile != null) {
        setState(() => _myNames = profile['fullName']);
    }

    // Listen
    _signalR.messageStream.listen((data) {
      if(mounted && data.length >= 2) {
        setState(() {
          _messages.add({'sender': data[0], 'message': data[1]});
        });
      }
    });
  }

  @override
  void dispose() {
    _signalR.leaveGroup(widget.tournamentId);
    super.dispose();
  }

  void _send() {
    if (_controller.text.isEmpty) return;
    _signalR.sendMessage(widget.tournamentId, _myNames, _controller.text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Chat Giải Đấu")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isMe = msg['sender'] == _myNames;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(msg['sender']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                        Text(msg['message']!),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(child: TextField(controller: _controller, decoration: const InputDecoration(hintText: "Nhập tin nhắn..."))),
                IconButton(icon: const Icon(Icons.send), onPressed: _send)
              ],
            ),
          )
        ],
      ),
    );
  }
}
