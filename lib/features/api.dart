import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
// features
import 'package:cinetalk/features/movie_provider.dart';
import 'package:cinetalk/features/user_provider.dart';
import 'package:cinetalk/features/auth.dart';

class UserApi {
  static const _storage = FlutterSecureStorage();

  static Future<bool> login(String email, String password) async {
    try {
      String? serverIP = dotenv.env['SERVER_IP']!;

      var url = Uri.https(
        serverIP, // 호스트 주소
        '/user/login', // 경로
      );

      var response = await http.post(
        url,
        headers: {'Content-type': 'application/x-www-form-urlencoded'},
        body: {
          'username': email,
          'password': password,
        },
        encoding: Encoding.getByName('utf-8'),
      ); // POST 요청 보내기

      var statuscode = response.statusCode;
      var body = jsonDecode(response.body);

      if (statuscode == 200) {
        await _storage.write(key: 'access_token', value: body['access_token']);
        print('로그인 성공');
        return true;
      } else {
        String errorMsg = body['message'] ?? '로그인 실패';
        print(errorMsg);
        return false;
      } // 응답의 상태 코드 반환
    } catch (e) {
      return false;
    }
  }

  static Future<void> userInfo(BuildContext context) async {
    String? token = await _storage.read(key: 'access_token');

    try {
      String? serverIP = dotenv.env['SERVER_IP']!;
      var url = Uri.https(
        serverIP,
        '/user/info',
      );

      var response = await http.post(url, headers: {
        'Authorization': 'Bearer $token',
      });

      Map<String, dynamic> user = jsonDecode(utf8.decode(response.bodyBytes));

      // provider에 user 정보 저장
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final movieProvider = Provider.of<MovieProvider>(context, listen: false);

      userProvider.setUserId(user['id']);
      userProvider.setUserEmail(user['email']);
      userProvider.setUserNickname(user['nickname']);
      userProvider.setFollowingList(user['following']);

      List<int> movieList = List<int>.from(user['movie_list']);
      userProvider.setMovieList(movieList);

      // 사용자 영화 리스트 처리
      if (user['movie_list'].isNotEmpty) {
        List<Map<String, dynamic>> movies =
            await MovieApi.fetchMovies(movieList);

        movieProvider.setMovieList(movies);
      } else {
        movieProvider.setMovieList([]); // 빈 리스트 설정
      }

      // profile image 경로가 있다면 해당 이미지를 provider에 저장
      if (user['profile'] != null && user['profile'].isNotEmpty) {
        Uint8List profileImageBytes = await UserApi.getProfile(user['id']);
        userProvider.setUserProfile(profileImageBytes);
      }

      return;
    } catch (e) {
      print("Error: $e");
      return;
    }
  }

  static Future<int> postParameters(
      String path, Map<String, String> params) async {
    String? serverIP = dotenv.env['SERVER_IP']!;

    var url = Uri.https(
      serverIP, // 호스트 주소
      path, // 경로
      params,
    );

    var response = await http.post(url);
    return response.statusCode;
  }

  static Future<int> postBody(String path, Map<String, dynamic> params) async {
    String? serverIP = dotenv.env['SERVER_IP']!;

    var url = Uri.https(
      serverIP, // 호스트 주소
      path, // 경로
    );

    var response = await http.post(
      url,
      headers: {
        'accept': 'application/json',
        'Content-Type': 'application/json'
      },
      body: jsonEncode(params),
      encoding: Encoding.getByName('utf-8'),
    ); // POST 요청 보내기
    return response.statusCode; // 응답의 상태 코드 반환
  }

  // update user information
  static Future<int> update(String path, String param, dynamic value) async {
    String? serverIP = dotenv.env['SERVER_IP']!;
    String? token = await Auth.getToken();

    var url = Uri.https(serverIP, '/user/update$path');
    var response = await http.put(
      url,
      headers: {
        'accept': 'application/json',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({param: value}),
    );
    return response.statusCode;
  }

  static Future<Uint8List> getProfile(String id) async {
    String? serverIP = dotenv.env['SERVER_IP']!;

    var url = Uri.https(
      serverIP, // 호스트 주소
      '/user/profile/get', // 경로
      {"id": id},
    );

    var response = await http.get(url);
    return response.bodyBytes;
  }

  static Future<Uint8List> setProfile(
      String id, File imageFile, BuildContext context) async {
    String? serverIP = dotenv.env['SERVER_IP']!;

    var url = Uri.https(
      serverIP,
      '/user/profile/upload',
      {"id": id},
    );

    // multipart/form-data 요청 생성
    var request = http.MultipartRequest('POST', url);

    final mimeType = lookupMimeType(imageFile.path);
    final extension = mimeType?.split('/')[1];

    var file = await http.MultipartFile.fromPath('file', imageFile.path,
        contentType: MediaType('image', extension!));

    request.files.add(file);

    var response = await request.send();

    // 응답 처리
    if (response.statusCode == 200) {
      Uint8List profileImageBytes = await UserApi.getProfile(id);
      return profileImageBytes;
    } else {
      throw Exception(
        '이미지 업로드 실패: ${response.statusCode}',
      );
    }
  }

  static Future<dynamic> getParameters(
      String path, String param, String value) async {
    String? serverIP = dotenv.env['SERVER_IP']!;

    var url = Uri.https(
      serverIP, // 호스트 주소
      path, // 경로
      {param: value},
    );

    var response = await http.get(url, headers: {
      'accept': 'application/json',
    });

    try {
      if (response.statusCode == 200) {
        // 응답이 성공적인 경우
        print("response success");
        var data = jsonDecode(utf8.decode(response.bodyBytes));
        // 'movies' 키에 해당하는 데이터를 List<Map<String, dynamic>> 형태로 반환
        return data; // 반환되는 데이터 구조에 맞게 수정
      } else {
        // 응답이 실패한 경우
        throw Exception(
            'Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // 예외 처리
      print('HTTP Request failed: $e');
      return null; // 예외 발생 시 null 반환
    }
  }

  static Future<http.Response> postBodyChat(
      String path, Map<String, dynamic> params) async {
    String? chatIP = dotenv.env['CHAT_IP']!;

    var url = Uri.https(
      chatIP, // CHAT_IP로 구성
      path, // 경로
    );

    try {
      var response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(params),
        encoding: Encoding.getByName('utf-8'),
      );

      return response; // 전체 Response 객체 반환
    } catch (e) {
      print('Error in postBodyChat: $e');
      // 실패 시 500 상태 코드와 에러 메시지로 응답 생성
      return http.Response(
          '{"status": "error", "message": "Internal error"}', 500);
    }
  }

  static Future<dynamic> getParametersChat(
      String path, String param, String value) async {
    String? chatIP = dotenv.env['CHAT_IP']!;

    // URL 구성: 명시적으로 포트 8000 추가
    var url = Uri.https(
      '$chatIP', // CHAT_IP와 포트를 결합
      path.startsWith('/') ? path.substring(1) : path, // 경로 앞 슬래시 제거
      {param: value}, // 쿼리 파라미터
    );

    try {
      var response = await http.get(url, headers: {
        'accept': 'application/json',
      });

      if (response.statusCode == 200) {
        print("Response success from CHAT_IP");
        var data = jsonDecode(utf8.decode(response.bodyBytes));
        return data; // 성공적으로 데이터를 반환
      } else {
        throw Exception(
            'Failed to load data from CHAT_IP. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('HTTP Request failed on CHAT_IP: $e');
      return null; // 예외 발생 시 null 반환
    }
  }

  static Future<Map<String, dynamic>> getFollowInfo(String id) async {
    String? serverIP = dotenv.env['SERVER_IP']!;

    var url = Uri.https(
      serverIP, // 호스트 주소
      '/user/follow/info', // 경로
      {"follow_id": id},
    );

    var response = await http.get(url);
    Map<String, dynamic> user = jsonDecode(utf8.decode(response.bodyBytes));
    return user;
  }
}

class MovieApi {
  static Future<dynamic> fetchMovies(List<int> movieIds) async {
    String serverIP = dotenv.env['SERVER_IP']!;

    // 쿼리 파라미터 준비
    Map<String, List<String>> queryParams = {
      'movie_ids': movieIds.map((id) => id.toString()).toList(),
    };
    var url = Uri.https(
      serverIP,
      "/movie/list",
      queryParams,
    );

    try {
      // HTTP GET 요청
      var response = await http.get(url, headers: {
        'accept': 'application/json',
      });

      if (response.statusCode == 200) {
        // 응답이 성공적인 경우
        print("response success");
        var data = jsonDecode(utf8.decode(response.bodyBytes));
        // 'movies' 키에 해당하는 데이터를 List<Map<String, dynamic>> 형태로 반환
        //print(data['movies']);
        return data['movies']
            .cast<Map<String, dynamic>>(); // 반환되는 데이터 구조에 맞게 수정
      } else {
        // 응답이 실패한 경우
        throw Exception(
            'Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      // 예외 처리
      print('HTTP Request failed: $e');
      return null; // 예외 발생 시 null 반환
    }
  }

  static Future<List<dynamic>> searchMovies(String query) async {
    String serverIP = dotenv.env['SERVER_IP']!;

    var url = Uri.https(
        serverIP, // 호스트 주소
        '/tmdb/search', // 경로
        {
          'q': query, // 쿼리 매개변수
          'limit': '10', // 한 번에 가져올 영화 수
          'page': '1', // 페이지 번호
        });

    try {
      final response = await http.get(url, headers: {
        'Accept': 'application/json;charset=UTF-8',
      });

      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        final Map<String, dynamic> data = jsonDecode(decodedBody);
        return data['results']; // 검색된 영화 리스트 업데이트
      } else {
        throw Exception('Failed to load movies');
      }
    } catch (e) {
      print('Error: $e');
    }
    return [];
  }

  static Future<void> saveMovies(List<Map<String, dynamic>> movies) async {
    String? serverIP = dotenv.env['SERVER_IP']!;

    var url = Uri.https(
      serverIP,
      '/movie/save',
    );

    for (var movie in movies) {
      var response = await http.post(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(movie),
        encoding: Encoding.getByName('utf-8'),
      );

      if (response.statusCode == 200) {
        print('영화 저장 성공');
      } else {
        print('영화 저장 실패');
      }
    }
  }
}
