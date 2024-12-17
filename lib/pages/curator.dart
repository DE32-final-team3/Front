import 'package:flutter/material.dart';
// features
import 'package:cinetalk/features/api.dart';

class Curator extends StatefulWidget {
  const Curator({super.key});

  @override
  _CuratorState createState() => _CuratorState();
}

class _CuratorState extends State<Curator> {
  List<dynamic>? movieList;

  @override
  void initState() {
    super.initState();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
    try {
      List<dynamic> movies = await MovieApi.fetchMovies([
        316029,
        616670,
        567646,
        122906,
        84111,
        424694,
        313369,
        198277,
        257211,
        20342
      ]);
      setState(() {
        movieList = movies;
      });
    } catch (e) {
      print("Error fetching movies: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Curator'),
      ),
      body: movieList == null
          ? const Center(child: CircularProgressIndicator()) // 로딩 인디케이터
          : ListView.builder(
              itemCount: movieList!.length,
              padding: const EdgeInsets.all(8.0), // 리스트 전체의 패딩
              itemBuilder: (context, index) {
                var movie = movieList![index];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8.0), // 각 카드 사이의 간격
                  child: Card(
                    elevation: 4.0, // 카드 그림자 효과
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0), // 카드의 모서리를 둥글게
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12.0), // 카드 내부 패딩
                      title: Text(
                        movie['title'] ?? 'No title',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ), // 영화 제목
                      leading: movie['poster_path'] != null
                          ? ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(8.0), // 이미지 모서리 둥글게
                              child: Image.network(
                                'https://image.tmdb.org/t/p/w500${movie['poster_path']}',
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Icon(Icons.image,
                              size: 70, color: Colors.grey), // 포스터가 없으면 아이콘
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 버튼 클릭 시 처리할 코드 (추가 동작 구현 가능)
          _loadMovies(); // 새로고침 예시
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
