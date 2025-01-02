import 'dart:convert';
import 'dart:typed_data';
import 'package:cinetalk/features/chat_provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:provider/provider.dart';
// features
import 'package:cinetalk/features/api.dart';
import 'package:cinetalk/features/custom_widget.dart';

class ChatRoom extends StatefulWidget {
  final String user1;
  final String user2;
  final String user2Nickname;

  const ChatRoom({
    required this.user1,
    required this.user2,
    required this.user2Nickname,
    super.key,
  });

  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final _controller = TextEditingController();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> searchedMovies = [];
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  late WebSocketChannel _channel;
  final List<Map<String, dynamic>> _sharedMovies = [];
  Uint8List? _user2ProfileImage;

  @override
  void initState() {
    super.initState();
    _fetchUser2ProfileImage();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _connectWebSocket();
  }

  Future<void> _fetchUser2ProfileImage() async {
    try {
      final profileImage = await UserApi.getProfile(widget.user2);
      setState(() {
        _user2ProfileImage = profileImage;
      });
    } catch (e) {
      print("Error fetching profile image for ${widget.user2}: $e");
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _connectWebSocket() {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final channel = chatProvider.getChannel(widget.user1, widget.user2);
    print("channel: ${channel.hashCode}");

    if (channel == null) {
      return;
    }

    _channel = channel;
    _scrollToBottom();
  }

  void _sendMessage() {
    if (_controller.text.isNotEmpty) {
      final message = _controller.text;
      _controller.clear();

      try {
        _channel.sink.add(message);
        _focusNode.requestFocus();
      } catch (_) {}
    }
  }

  void _shareMovie(Map<String, dynamic> movie) {
    try {
      Map<String, dynamic> message = {
        'movie_id': movie['id'].toString(),
        'poster_path': 'https://image.tmdb.org/t/p/w500${movie['poster_path']}'
      };
      _channel.sink.add(jsonEncode(message));
      _focusNode.requestFocus();
      _scrollToBottom();
    } catch (_) {}
  }

  Future<void> _updateOffset() async {
    try {
      final users = [widget.user1, widget.user2]..sort();
      final topic = "${users[0]}-${users[1]}";

      final response = await UserApi.postBodyChat(
        "/api/chat_rooms/update_offset",
        {"user_id": widget.user1, "topic": topic},
      );

      if (response.statusCode != 200 ||
          jsonDecode(response.body)['status'] != 'success') {}
    } catch (_) {}
  }

// 검색 버튼 클릭 시 동작할 함수
  void _search(setState) async {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      // TMDb API를 호출하여 영화 검색
      List<Map<String, dynamic>> movies =
          List<Map<String, dynamic>>.from(await MovieApi.searchMovies(query));
      setState(() {
        searchedMovies = movies; // 검색된 영화 리스트 상태 업데이트
      });

      // 검색된 영화가 없을 경우 Snackbar 띄우기
      if (searchedMovies.isEmpty) {
        _searchController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('일치하는 영화가 없습니다. 다시 검색해주세요.'),
            behavior: SnackBarBehavior.floating, // 화면 위에 표시
            //margin: EdgeInsets.only(bottom: 50), // 하단 여백을 추가
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _searchMovie() {
    _searchController.clear();
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0), // 모서리 둥글게
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9, // 화면 너비의 90%
                height: MediaQuery.of(context).size.height * 0.8, // 화면 높이의 80%
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '영화 공유하기',
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            Navigator.of(context).pop(); // 닫기
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Enter movie name',
                        border: OutlineInputBorder(),
                        suffixIcon: IconButton(
                            onPressed: () {
                              _search(setState); // _search 함수에 setState 전달
                            },
                            icon: const Icon(Icons.search)),
                      ),
                      onSubmitted: (_) => _search(setState),
                    ),
                    const SizedBox(height: 16.0),
                    Expanded(
                      child: Container(
                        color: Colors.grey[200],
                        child: searchedMovies.isEmpty
                            ? const Center(
                                child: Text(
                                  '영화를 검색해주세요',
                                  style: TextStyle(fontSize: 16),
                                ),
                              )
                            : ListView.builder(
                                itemCount: searchedMovies.length,
                                itemBuilder: (context, index) {
                                  var movie = searchedMovies[index];
                                  return GestureDetector(
                                    onTap: () {
                                      // AlertDialog 띄우기
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: Text('채팅방에 공유하기'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  _shareMovie(movie);
                                                  Navigator.of(context).pop();
                                                  Navigator.of(context).pop();
                                                },
                                                child: const Text('확인'),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: Container(
                                        child: CustomWidget.searchCard(movie),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _updateOffset().whenComplete(() {
      _controller.dispose();
      _searchController.dispose();
      _focusNode.dispose();
      _scrollController.dispose();
      super.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (didPop, result) async {
        await _updateOffset();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.user2Nickname,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true, // AppBar 제목을 가운데 정렬
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              await _updateOffset();
              Navigator.of(context).pop(true);
            },
          ),
          actions: [
            Builder(
              builder: (BuildContext context) {
                return IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () {
                    // 사이드바 열기
                    Scaffold.of(context).openEndDrawer();
                  },
                );
              },
            ),
          ],
        ),
        endDrawer: Drawer(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.blue,
                ),
                child: Container(
                  alignment: Alignment.center,
                  height: 100, // 세로 길이 지정
                  child: Text(
                    '공유 영화 목록',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // ListView.builder를 Expanded로 감싸지 않음
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    List<Map<String, dynamic>> sharedMovies =
                        chatProvider.getMessagesForSharedMovie(widget.user2);
                    return ListView.builder(
                      itemCount: sharedMovies.length,
                      itemBuilder: (context, index) {
                        final movie = sharedMovies[index];
                        return ListTile(
                          onTap: () {
                            CustomWidget.launchMoviePage(movie['movie_id']);
                          },
                          title: Image.network(
                            movie['poster_path']!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Text('Image not available');
                            },
                          ),
                          subtitle: Text(movie['timestamp'] ?? 'Unknown'),
                        );
                      },
                    );
                  },
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: Icon(Icons.exit_to_app),
                  ),
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 193, 178, 227),
        body: Column(
          children: [
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  List<Map<String, dynamic>> messages =
                      chatProvider.getMessagesForChatRoom(widget.user2);

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollToBottom();
                    }
                  });
                  return ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      bool isUser = message['sender'] == widget.user1;

                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isUser && _user2ProfileImage != null) ...[
                                GestureDetector(
                                  onTap: () => CustomWidget.showUserProfile(
                                      widget.user2, context),
                                  child: CircleAvatar(
                                    backgroundImage:
                                        MemoryImage(_user2ProfileImage!),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              Column(
                                crossAxisAlignment: isUser
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isUser
                                          ? Colors.blue
                                          : const Color.fromARGB(
                                              255, 255, 255, 255),
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    padding: const EdgeInsets.all(10),
                                    child: message.containsKey('poster_path') &&
                                            message.containsKey('movie_id')
                                        ? GestureDetector(
                                            onTap: () {
                                              // 클릭 이벤트 처리
                                              CustomWidget.launchMoviePage(
                                                  message['movie_id']);
                                            },
                                            child: Image.network(
                                              message['poster_path']!,
                                              width: 120,
                                              height: 200,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return const Text(
                                                    'Image not available');
                                              },
                                            ),
                                          )
                                        : Text(
                                            message['message']!,
                                            style: TextStyle(
                                              color: isUser
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      message['timestamp'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(onPressed: _searchMovie, icon: Icon(Icons.upload)),
                  const SizedBox(width: 4.0),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      decoration: const InputDecoration(
                          hintText: 'Enter message',
                          border: OutlineInputBorder()),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_sharp),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
