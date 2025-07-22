import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_screen.dart';

void main() {
  runApp(const ChatGameApp());
}

class ChatGameApp extends StatelessWidget {
  const ChatGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat Game',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const LobbyScreen(),
    );
  }
}

class LobbyScreen extends StatefulWidget {
  const LobbyScreen({super.key});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  List<Map<String, dynamic>> lobbies = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchLobbies();
  }

  Future<void> fetchLobbies() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.4:8000/lobbies'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final List<dynamic> lobbyData = decoded['lobbies'];
        setState(() {
          lobbies = lobbyData.cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load lobbies');
      }
    } catch (e) {
      print('Error fetching lobbies: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _createLobby() async {
    final newLobbyName = 'New Lobby ${lobbies.length + 1}';
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.4:8000/create_lobby'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "lobby_id": newLobbyName,
          "max_humans": 10,
          "is_public": true
        }),
      );

      if (response.statusCode == 200) {
        await fetchLobbies(); // Refresh the lobby list
      } else {
        print('Failed to create lobby: ${response.body}');
      }
    } catch (e) {
      print('Error creating lobby: $e');
    }
  }

  void _joinLobby(String lobbyName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(lobbyName: lobbyName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat Game Lobbies'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : lobbies.isEmpty
              ? const Center(child: Text('No lobbies found'))
              : ListView.builder(
                  itemCount: lobbies.length,
                  itemBuilder: (context, index) {
                    final lobby = lobbies[index];
                    return ListTile(
                      title: Text(lobby['lobby_id'] ?? 'Unnamed Lobby'),
                      subtitle: Text('Participants: ${lobby['participants'] ?? 0}'),
                      trailing: ElevatedButton(
                        onPressed: () => _joinLobby(lobby['lobby_id']),
                        child: const Text('Join'),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createLobby,
        child: const Icon(Icons.add),
      ),
    );
  }
}
