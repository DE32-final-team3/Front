import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cinetalk/features/api.dart';

class ChatProvider with ChangeNotifier {
  List<Map<String, dynamic>> chatList = [];
  bool isLoading = true;

  Future<void> fetchChatRooms(String userId) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await UserApi.getParametersChat(
        '/api/chat_rooms/$userId/unread',
        '',
        '',
      );

      if (response?['status'] == 'success') {
        final fetchedChatRooms = response['data'] as List<dynamic>? ?? [];
        chatList = await Future.wait(
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

        chatList.sort(
            (a, b) => (b['timestamp'] ?? 0).compareTo(a['timestamp'] ?? 0));
      } else {
        throw Exception('Failed to load chat rooms: ${response?['message']}');
      }
    } catch (e) {
      print("Error fetching chat rooms: $e");
    } finally {
      isLoading = false;
      notifyListeners();
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
}
