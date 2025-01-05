import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// pages
import 'package:cinetalk/pages/search_movie.dart';
// features
import 'package:cinetalk/features/movie_provider.dart';
import 'package:cinetalk/features/custom_widget.dart';

class Curator extends StatefulWidget {
  const Curator({super.key});

  @override
  _CuratorState createState() => _CuratorState();
}

class _CuratorState extends State<Curator> {
  List<dynamic>? movieList;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Curator'),
      ),
      body: Consumer<MovieProvider>(
        builder: (context, movieProvider, child) {
          // MovieProvider에서 영화 리스트 가져오기
          List<Map<String, dynamic>> movieList =
              List.from(movieProvider.movieList);
          // movieList가 null일 경우 문구 표시
          if (movieList.isEmpty) {
            return const Center(
              child: Text(
                "영화 리스트를 생성해주세요",
                style: const TextStyle(fontSize: 20),
              ),
            );
          }

          return ListView.builder(
            itemCount: movieList.length,
            padding: const EdgeInsets.all(4.0),
            itemBuilder: (context, index) {
              var movie = movieList[index];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: CustomWidget.movieCard(movie),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SearchMovie()),
          );
        },
        child: const Icon(Icons.edit),
        backgroundColor: Colors.blue,
      ),
    );
  }
}
