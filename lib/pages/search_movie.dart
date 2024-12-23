import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// features
import 'package:cinetalk/features/api.dart';
import 'package:cinetalk/features/custom_widget.dart';
import 'package:cinetalk/features/user_provider.dart';
import 'package:cinetalk/features/movie_provider.dart';

class SearchMovie extends StatefulWidget {
  const SearchMovie({super.key});

  @override
  _SearchMovieState createState() => _SearchMovieState();
}

class _SearchMovieState extends State<SearchMovie> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> searchdMovies = [];
  List<Map<String, dynamic>> selectedMovies = [];

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

      // 검색된 영화가 없을 경우 Snackbar 띄우기
      if (searchdMovies.isEmpty) {
        _searchController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('일치하는 영화가 없습니다. 다시 검색해주세요.'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    }
  }

  // 선택한 영화를 selectedMovies 리스트에 추가 또는 제거
  void _toggleSelectedMovie(Map<String, dynamic> movie) {
    setState(() {
      if (selectedMovies.contains(movie)) {
        selectedMovies.remove(movie); // 선택된 카드라면 제거
      } else {
        selectedMovies.add(movie); // 선택되지 않은 카드라면 추가
      }
    });
  }

  void _removeMovie(Map<String, dynamic> movie) {
    setState(() {
      selectedMovies.remove(movie); // 선택된 카드 제거
    });
  }

  List<Map<String, dynamic>> formatMovies(
      List<Map<String, dynamic>> selectedMovies) {
    List<Map<String, dynamic>> formattedMovies = []; // 새로운 리스트 생성

    for (var movie in selectedMovies) {
      Map<String, dynamic> formatMovie = {}; // 매번 새로운 Map 생성

      formatMovie['cast'] = movie['cast'] ?? [];
      formatMovie['genres'] = movie['genre_ids'] ?? movie['genres'];
      formatMovie['director'] = movie['director'] ?? [];
      formatMovie['movie_id'] = movie['id'] ?? movie['movie_id'];
      formatMovie['original_language'] = movie['original_language'] ?? '';
      formatMovie['original_title'] = movie['original_title'] ?? '';
      formatMovie['overview'] = movie['overview'] ?? '';
      formatMovie['poster_path'] = movie['poster_path'] ?? '';
      formatMovie['release_date'] = movie['release_date'] ?? '';
      formatMovie['title'] = movie['title'];

      // 포맷된 영화 추가
      formattedMovies.add(formatMovie);
    }

    return formattedMovies; // 포맷된 영화 리스트 반환
  }

  @override
  Widget build(BuildContext context) {
    final movieProvider = Provider.of<MovieProvider>(context);

    // provider.movieList를 selectedMovies에 복사
    if (selectedMovies.isEmpty) {
      selectedMovies = List<Map<String, dynamic>>.from(movieProvider.movieList);
    }

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
                            bool isSelected = selectedMovies.contains(movie);
                            return GestureDetector(
                              onTap: () {
                                _toggleSelectedMovie(movie);
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
                                child: Container(
                                  color: isSelected
                                      ? Colors.blueAccent.withOpacity(0.2)
                                      : Colors.white,
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
                              title: const Text('선택한 영화 목록'),
                              content: SizedBox(
                                width: double.maxFinite, // Dialog의 내용이 꽉 차도록 설정
                                child: StatefulBuilder(
                                  builder: (context, setState) {
                                    return ListView.builder(
                                      shrinkWrap: true, // Dialog의 크기에 맞게 조정
                                      itemCount: selectedMovies.length,
                                      itemBuilder: (context, index) {
                                        var movie = selectedMovies[index];
                                        return GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _removeMovie(movie);
                                            });
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4.0),
                                            child:
                                                CustomWidget.selectCard(movie),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                              actions: <Widget>[
                                TextButton(
                                  child: const Text('Close'),
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
                    if (selectedMovies.isNotEmpty) // 리스트가 비어있지 않을 경우에만 표시
                      Positioned(
                        right: -6.0,
                        top: -6.0,
                        child: CircleAvatar(
                          radius: 12, // 크기 조정
                          backgroundColor: Colors.red,
                          child: Text(
                            selectedMovies.length.toString(),
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
              child: Consumer<UserProvider>(
                builder: (context, userProvider, child) {
                  return FloatingActionButton(
                    onPressed: selectedMovies.length != 10
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('10개의 영화를 선택해주세요.'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        : () async {
                            List<Map<String, dynamic>> formattedMovies =
                                formatMovies(selectedMovies);
                            await MovieApi.saveMovies(formattedMovies);
                            List<int> movieIds = formattedMovies
                                .map((movie) => movie['movie_id'] as int)
                                .toList();
                            await UserApi.update(
                                "/movies", "movie_list", movieIds);
                            movieProvider.setMovieList(formattedMovies);
                            Navigator.pop(context);
                          },
                    backgroundColor:
                        selectedMovies.length != 10 ? Colors.grey : Colors.blue,
                    child: Icon(Icons.save),
                  );
                },
              )),
        ],
      ),
    );
  }
}
