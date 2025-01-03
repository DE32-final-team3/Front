import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
// features
import 'package:cinetalk/features/api.dart';
import 'package:cinetalk/features/user_provider.dart';

class CustomWidget {
  static Future<void> launchMoviePage(String? movieId) async {
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
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            // Movie poster
            movie['poster_path'] != null
                ? GestureDetector(
                    onTap: () {
                      launchMoviePage(
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
            const SizedBox(height: 8.0),
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

  static Widget searchCard(var movie) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // 포스터 이미지
            movie['poster_path'] != null
                ? GestureDetector(
                    onTap: () {
                      launchMoviePage(
                          movie['id'].toString()); // 포스터 클릭 시 영화 페이지로 이동
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        'https://image.tmdb.org/t/p/w500${movie['poster_path']}',
                        width: 100,
                        height: 150,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                : const Icon(Icons.movie, size: 70, color: Colors.grey),
            const SizedBox(width: 12.0),

            // 텍스트 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          movie['title'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),

                  // 줄거리 (길면 자르기)
                  Text(
                    movie['overview'] ?? '줄거리 없음',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(fontSize: 12.0, color: Colors.black54),
                  ),
                  const SizedBox(height: 8.0),

                  // 감독 및 배우 정보
                  Text(
                    '감독: ${movie['director']['name']}',
                    style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '출연진: ${movie['cast'].map((actor) => actor['name']).join(', ')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget selectCard(var movie) {
    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: //Text(movie.toString()),
            Row(
          children: [
            // Movie poster
            movie['poster_path'] != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      'https://image.tmdb.org/t/p/w500${movie['poster_path']}',
                      width: 50,
                      height: 75,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(Icons.movie, size: 70, color: Colors.grey),
            const SizedBox(width: 16.0),
            Column(
              children: [
                Text(
                  movie['title'],
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> showUserProfile(String userId, context) async {
    try {
      // Fetch user info and movies
      final response = await UserApi.getFollowInfo(userId);

      if (!response.containsKey('movie_list') ||
          !response.containsKey('nickname')) {
        throw Exception("Failed to fetch user info.");
      }

      final movieIds = response['movie_list'] as List<dynamic>;
      final nickname = response['nickname'] as String;

      // Fetch profile image separately
      Uint8List? profileImage = await UserApi.getProfile(userId);

      // Fetch movie details if available
      List<Map<String, dynamic>> movies = [];
      if (movieIds.isNotEmpty) {
        movies = await MovieApi.fetchMovies(movieIds.cast<int>()) ?? [];
      }

      Map<String, dynamic> user = {
        "id": userId,
        "nickname": nickname,
        "profile": profileImage,
      };

      final userProvider = Provider.of<UserProvider>(context, listen: false);

      showDialog(
          context: context,
          builder: (context) {
            final isFollowing = userProvider.following.contains(user['id']);

            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: Icon(
                          isFollowing ? Icons.favorite : Icons.favorite_outline,
                          color: Colors.red,
                          size: 30,
                        ),
                        onPressed: () async {
                          if (isFollowing) {
                            await UserApi.unfollow(
                              "/user/follow/delete",
                              {
                                "id": userProvider.id,
                                "following_id": user['id'],
                              },
                            );
                            userProvider.unfollow(user['id']);
                          } else {
                            await UserApi.postParameters(
                              "/user/follow",
                              {
                                "id": userProvider.id,
                                "following_id": user['id'],
                              },
                            );
                            userProvider.follow(user['id']);
                          }
                        },
                      )
                    ],
                  ),
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: user['profile'] != null
                        ? MemoryImage(user['profile'])
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user['nickname'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (movies.isNotEmpty)
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.4,
                      width: MediaQuery.of(context).size.width * 0.6,
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount:
                              (MediaQuery.of(context).size.width / 150).floor(),
                          crossAxisSpacing: 8.0,
                          mainAxisSpacing: 8.0,
                          childAspectRatio: 0.7,
                        ),
                        itemCount: movies.length,
                        itemBuilder: (context, index) {
                          final movie = movies[index];
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8.0),
                            child: GestureDetector(
                              onTap: () {
                                Uri url = Uri.parse(
                                    'https://www.themoviedb.org/movie/${movie['movie_id']}');
                                launchUrl(url);
                              },
                              child: movie['poster_path'] != null
                                  ? Image.network(
                                      'https://image.tmdb.org/t/p/w500${movie['poster_path']}',
                                      width: 100,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    )
                                  : const Icon(
                                      Icons.movie,
                                      size: 100,
                                      color: Colors.grey,
                                    ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    const Text("No movies found."),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            );
          });
    } catch (e) {
      print("Error fetching profile for user $userId: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to fetch profile for user $userId")),
      );
    }
  }
}
