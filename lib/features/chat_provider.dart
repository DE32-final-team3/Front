import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/intl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
// features
import 'package:cinetalk/features/api.dart';

class ChatProvider with ChangeNotifier {
  late WebSocketChannel _notiChannel;
  final List<String> _messages = [];

  // Map to store WebSocket channels and their connection status
  final Map<String, WebSocketChannel> _channels = {};
  final Map<String, bool> _isConnected = {}; // 추가된 연결 상태 추적 맵

  List<String> _userIds = [];
  void _updateUserIds() {
    _userIds = _chatList.map((e) => e['user_id'] as String).toList();
  }

  // Map to store messages for each chat room (using user_id as key)
  final Map<String, List<Map<String, dynamic>>> _chatMessages = {};

  WebSocketChannel? getChannel(String sender, String receiver) {
    // 기존 채널이 없으면 새로운 채널 생성 및 연결
    if (_channels[receiver] == null) {
      addChannel(receiver);
      _connectWebSocketForChatRooms(sender, _userIds);
    }
    return _channels[receiver];
  }

  void addChannel(String userId) {
    _userIds.add(userId);
    print("adds userIds : $_userIds");
    if (!_chatMessages.containsKey(userId)) {
      _chatMessages[userId] = [];
    } // 채팅방 메시지 초기화
  }

  List<Map<String, dynamic>> getMessagesForChatRoom(String userId) {
    return _chatMessages[userId] ?? [];
  }

  List<Map<String, dynamic>> getMessagesForSharedMovie(String userId) {
    // Get the list of messages for the given user ID
    final messages = _chatMessages[userId] ?? [];

    // Filter messages based on the conditions
    final filteredMessages = messages.where((message) {
      return message.containsKey('poster_path') &&
          message.containsKey('movie_id');
    }).toList();

    return filteredMessages;
  }

  List<Map<String, dynamic>> _chatList = [];
  List<Map<String, dynamic>> get chatList => _chatList;

  Future<void> setChatList(String userId) async {
    try {
      final chatRooms = await fetchChatRooms(userId);
      _chatList = chatRooms;
      setTotalUnreadCount();
      notifyListeners();

      // 정렬
      _chatList
          .sort((a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));

      _updateUserIds();
      // 채팅방 목록을 통해 연결이 필요한 채널들에 대해 WebSocket 연결을 시도
      await _connectWebSocketForChatRooms(userId, _userIds);
    } catch (e) {
      print("Error setting chat rooms: $e");
    }
  }

  int _totalUnreadCount = 0;
  int get totalUnreadCount => _totalUnreadCount;

  void setTotalUnreadCount() {
    _totalUnreadCount = chatList.fold(0, (total, room) {
      return total + (room['unreadCount'] as int? ?? 0);
    });
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

  // 각 채팅방에 대해 WebSocket 연결을 관리하는 메서드
  Future<void> _connectWebSocketForChatRooms(
      String sender, List<String> userIds) async {
    String websocketIP = dotenv.env['CHAT_IP']!;

    for (var receiver in userIds) {
      // 채널이 아직 연결되지 않은 경우에만 연결
      if (_isConnected[receiver] != true) {
        try {
          print("$sender, $receiver");
          _channels[receiver] = WebSocketChannel.connect(
            Uri.parse('wss://$websocketIP/ws/$sender/$receiver'),
          );
          _isConnected[receiver] = true; // 연결 상태 갱신
          if (!_chatMessages.containsKey(receiver)) {
            _chatMessages[receiver] = [];
          }
          print("Connected to chat channel for receiver: $receiver");
          // WebSocket 메시지 스트림 리스너
          _channels[receiver]!.stream.listen((message) {
            try {
              final decodedMessage = jsonDecode(message);
              String? formattedTime;
              if (decodedMessage['timestamp'] != null) {
                final DateTime parsedTime =
                    DateTime.parse(decodedMessage['timestamp']);
                final DateTime kstTime =
                    parsedTime.add(const Duration(hours: 9));
                formattedTime = DateFormat('MM/dd HH:mm').format(kstTime);
              }

              // 메시지를 해당 채팅방에 추가
              if (decodedMessage['message'].contains('movie_id') &&
                  decodedMessage['message'].contains('poster_path')) {
                Map<String, dynamic> movie =
                    jsonDecode(decodedMessage['message']);

                _chatMessages[receiver]?.add({
                  "sender": decodedMessage['sender'],
                  "poster_path": movie['poster_path'],
                  "movie_id": movie['movie_id'].toString(),
                  "timestamp": formattedTime ?? 'Unknown time',
                });
              } else {
                _chatMessages[receiver]?.add({
                  "sender": decodedMessage['sender'],
                  "message": decodedMessage['message'],
                  "timestamp": formattedTime ?? 'Unknown time',
                });
              }
              setTotalUnreadCount();
              notifyListeners(); // 메시지가 변경되면 UI 업데이트
            } catch (e) {
              print("Error decoding message: $e");
            }
          });
        } catch (e) {
          print("Error connecting to chat channel for $receiver: $e");
        }
      } else {
        print("Already connected to chat channel for receiver: $receiver");
      }
    }
  }

  // WebSocket 연결을 시작하는 기존 메서드 (변경 없음)
  // void connect(String userId) {
  //   String websocketIP = dotenv.env['CHAT_IP']!;
  //   _channel = WebSocketChannel.connect(
  //     Uri.parse('wss://$websocketIP/ws/$userId'),
  //   );
  //   print("Connected to notify channel");

  //   _channel.stream.listen((message) {
  //     print("listen");
  //     _messages.add(message); // 메시지를 저장
  //     setChatList(userId);

  //     notifyListeners(); // 메시지가 변경되면 UI 업데이트
  //   });
  // }

  void connectNotifyChannel(String userId) {
    if (_isConnected['notify'] != true) {
      String websocketIP = dotenv.env['CHAT_IP']!;
      _notiChannel = WebSocketChannel.connect(
        Uri.parse('wss://$websocketIP/ws/$userId'),
      );
      _isConnected['notify'] = true;
      print("Connected to notify channel");

      _notiChannel.stream.listen((message) {
        print("Message received: $message");
        _messages.add(message);
        setChatList(userId);
        notifyListeners();
      });
    } else {
      print("Notify channel already connected");
    }
  }

  // WebSocket 연결 종료
  void disconnect() {
    _notiChannel.sink.close();
    _channels.forEach((key, value) {
      value.sink.close();
    });
    print("disconnect");
  }
}
