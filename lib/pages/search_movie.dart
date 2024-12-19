import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// features
import 'package:cinetalk/features/api.dart';
import 'package:cinetalk/features/custom_widget.dart';
import 'package:cinetalk/features/movie_provider.dart';

class SearchMovie extends StatefulWidget {
  const SearchMovie({super.key});

  @override
  _SearchMovieState createState() => _SearchMovieState();
}

class _SearchMovieState extends State<SearchMovie> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> searchdMovies = [];
  List<int> selectedMovies = [];

  // 검색 버튼 클릭 시 동작할 함수
  void _search() async {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      // TMDb API를 호출하여 영화 검색
      List<Map<String, dynamic>> movies =
          List<Map<String, dynamic>>.from(await MovieApi.searchMovies(query));

      setState(() {
        searchdMovies = movies; // 검색된 영화 리스트 상태 업데이트
      });
    }
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('큐레이터 생성'),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 검색창과 검색 버튼
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.center, // 버튼과 텍스트 필드를 수평 중앙 정렬
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search...',
                          border: OutlineInputBorder(),
                        ),
                        style: const TextStyle(fontSize: 16),
                        onSubmitted: (_) {
                          _search(); //_search();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 50, // 정사각형 크기
                      height: 50, // 정사각형 크기
                      child: ElevatedButton(
                        onPressed: () {
                          // 검색 버튼 클릭 시 동작
                          _search();
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                          padding: EdgeInsets.zero, // 패딩 제거
                          side: const BorderSide(
                            color: Colors.blue, // 테두리 색상
                            width: 2, // 테두리 두께
                          ),
                        ),
                        child: const Icon(Icons.search),
                      ),
                    ),
                  ],
                ),
              ),
              // 결과를 띄워줄 공간
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  color: Colors.grey[200],
                  child: searchdMovies.isEmpty
                      ? const Center(
                          child: Text(
                            '영화를 검색해주세요',
                            style: TextStyle(fontSize: 16),
                          ),
                        )
                      : ListView.builder(
                          itemCount: searchdMovies.length,
                          itemBuilder: (context, index) {
                            var movie = searchdMovies[index];
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: CustomWidget.searchCard(movie),
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 16.0,
            left: 16.0,
            child: Consumer<MovieProvider>(
              builder: (context, movieProvider, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    FloatingActionButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: Text('선택한 영화 목록'),
                              content: SingleChildScrollView(
                                child: ListBody(
                                  children:
                                      movieProvider.movieList.map((movie) {
                                    return CustomWidget.miniCard(movie);
                                  }).toList(),
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: Text('Close'),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                      child: Icon(Icons.list),
                    ),
                    Positioned(
                      top: 5,
                      right: 5,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.red,
                        child: Text(
                          movieProvider.movieList.length.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Positioned(
              bottom: 16.0,
              right: 16.0,
              child: Consumer<MovieProvider>(
                builder: (context, movieProvider, child) {
                  return FloatingActionButton(
                    onPressed: movieProvider.movieList.length != 10
                        ? null
                        : () {
                            // Your save logic here
                          },
                    child: Icon(Icons.save),
                    backgroundColor: movieProvider.movieList.length != 10
                        ? Colors.grey
                        : Colors.blue,
                  );
                },
              )),
        ],
      ),
    );
  }
}
