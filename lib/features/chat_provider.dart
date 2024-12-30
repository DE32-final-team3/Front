import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
// features
import 'package:cinetalk/features/api.dart';

class ChatProvider with ChangeNotifier {
  late WebSocketChannel _channel;
  final List<String> _messages = [];
  List<Map<String, dynamic>> _chatList = [];
  int _totalUnreadCount = 0;

  List<Map<String, dynamic>> get chatList => _chatList;
  int get totalUnreadCount => _totalUnreadCount;

  void setTotalUnreadCount() {
    _totalUnreadCount = chatList.fold(0, (total, room) {
      return total + (room['unreadCount'] as int? ?? 0);
    });
  }

  Future<void> setChatList(String userId) async {
    try {
      final chatRooms = await fetchChatRooms(userId);
      _chatList = chatRooms;
      setTotalUnreadCount();
      notifyListeners();

      _chatList
          .sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
    } catch (e) {
      print("Error setting chat rooms: $e");
    }
  }

  Future<List<Map<String, dynamic>>> fetchChatRooms(String userId) async {
    try {
      final response = await UserApi.getParametersChat(
        '/api/chat_rooms/$userId/unread',
        '',
        '',
      );

      if (response?['status'] == 'success') {
        final fetchedChatRooms = response['data'] as List<dynamic>? ?? [];
        return await Future.wait(
          fetchedChatRooms.map((room) async {
            final partnerId = room['partner_id'];
            final profileImageBytes = await _fetchProfileImage(partnerId);

            return {
              "profileImage": profileImageBytes,
              "nickname": room['partner_nickname'] ?? "Unknown",
              "lastMessage": room['last_message']?['text'] ?? "No messages yet",
              "timestamp": room['last_message']?['timestamp'],
              "user_id": partnerId,
              "unreadCount": room['unread_count'] ?? 0,
            };
          }).toList(),
        );
      } else {
        throw Exception('Failed to load chat rooms: ${response?['message']}');
      }
    } catch (e) {
      print("Error fetching chat rooms: $e");
      return []; // 실패 시 빈 리스트 반환
    }
  }

  Future<Uint8List> _fetchProfileImage(String partnerId) async {
    try {
      return await UserApi.getProfile(partnerId);
    } catch (e) {
      print("Error fetching profile image for $partnerId: $e");
      return Uint8List(0);
    }
  }

  // WebSocket 연결을 시작하는 메서드
  void connect(String userId) {
    String websocketIP = dotenv.env['CHAT_IP']!;
    _channel = WebSocketChannel.connect(
      Uri.parse('wss://$websocketIP/ws/$userId'),
    );

    _channel.stream.listen((message) {
      _messages.add(message); // 메시지를 저장
      print("listen");
      setChatList(userId);

      notifyListeners(); // 메시지가 변경되면 UI 업데이트
    });
  }

  // WebSocket 연결 종료
  void disconnect() {
    _channel.sink.close();
  }
}
