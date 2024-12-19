import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomWidget {
  static void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // 다이얼로그 외부를 터치해도 닫히지 않도록 설정
      builder: (BuildContext context) {
        return Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          ),
        );
      },
    );
  }

  static Future<void> _launchMoviePage(String? movieId) async {
    Uri url = Uri.parse('https://www.themoviedb.org/movie/$movieId');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  static Widget movieCard(var movie) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // Movie poster
            movie['poster_path'] != null
                ? GestureDetector(
                    onTap: () {
                      _launchMoviePage(
                          movie['movie_id'].toString()); // 포스터 클릭 시 영화 페이지로 이동
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        'https://image.tmdb.org/t/p/w500${movie['poster_path']}',
                        width: 300,
                        height: 450,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : const Icon(Icons.movie, size: 70, color: Colors.grey),
            const SizedBox(height: 12.0),
            Text(
              movie['title'],
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
