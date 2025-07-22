import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

class ChatScreen extends StatefulWidget {
  final String lobbyName;

  const ChatScreen({super.key, required this.lobbyName});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late WebSocketChannel channel;
  final TextEditingController controller = TextEditingController();
  final List<String> messages = [];
  final String userId = Uuid().v4(); // random user ID

  @override
  void initState() {
    super.initState();
    final wsUrl = Uri.parse('ws://192.168.1.4:8000/ws/${widget.lobbyName}/$userId');
    channel = WebSocketChannel.connect(wsUrl);

    channel.stream.listen((msg) {
      setState(() {
        messages.add(msg);
      });
    });
    // print('Connecting to $wsUrl'); // inside initState

  }

  void _sendMessage() {
    if (controller.text.trim().isEmpty) return;
    channel.sink.add(controller.text.trim());
    controller.clear();
    // print('Sending: ${controller.text.trim()}'); // inside _sendMessage

  }

  @override
  void dispose() {
    channel.sink.close();
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lobbyName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(messages[index]),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: const InputDecoration(
                      hintText: 'Type your message...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
