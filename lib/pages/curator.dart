import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// features
import 'package:cinetalk/features/api.dart';
import 'package:cinetalk/features/user_provider.dart';
import 'package:cinetalk/features/custom_wigdet.dart';

class Curator extends StatefulWidget {
  const Curator({super.key});

  @override
  _CuratorState createState() => _CuratorState();
}

class _CuratorState extends State<Curator> {
  List<dynamic>? movieList;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadMovies(); // didChangeDependencies()에서 호출
  }

  Future<void> _loadMovies() async {
    //List<int> movieIds = Provider.of<UserProvider>(context).movieList;
    try {
      List<dynamic> movies = await MovieApi.fetchMovies(
          Provider.of<UserProvider>(context).movieList);
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
      body: Consumer<UserProvider>(
        builder: (context, UserProvider, child) {
          // movieList가 null일 경우 문구 표시
          if (movieList == null) {
            return const Center(
              child: Text(
                "영화 리스트를 생성해주세요",
                style: const TextStyle(fontSize: 20),
              ),
            );
          }

          return ListView.builder(
            itemCount: movieList!.length,
            padding: const EdgeInsets.all(8.0),
            itemBuilder: (context, index) {
              var movie = movieList![index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: CustomWigdet.movieCard(movie),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _loadMovies(); // 새로고침 예시
        },
        child: const Icon(Icons.edit),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
