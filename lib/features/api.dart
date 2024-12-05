import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
// features
import 'package:cinetalk/features/user_provider.dart';
import 'package:cinetalk/features/auth.dart';

class UserApi {
  static const _storage = FlutterSecureStorage();

  static Future<bool> login(String email, String password) async {
    try {
      String? serverIP = dotenv.env['SERVER_IP']!;

      var url = Uri.http(
        serverIP, // 호스트 주소
        '/api/user/login', // 경로
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
      var url = Uri.http(
        serverIP,
        '/api/user/validate',
      );

      var response = await http.post(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept-Charset': 'utf-8',
      });

      Map<String, dynamic> user = jsonDecode(utf8.decode(response.bodyBytes));

      // provider에 user 정보 저장
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      userProvider.setUserId(user['id']);
      userProvider.setUserEmail(user['email']);
      userProvider.setUserNickname(user['nickname']);

      // profile image 경로가 있다면 해당 이미지를 provider에 저장
      if (user['profile'] != null && user['profile'].isNotEmpty) {
        Uint8List profileImageBytes = await UserApi.getProfile(user['id']);

        File profileImage =
            File('${(await getTemporaryDirectory()).path}/profile_image.png')
              ..writeAsBytesSync(profileImageBytes);

        userProvider.setUserProfile(profileImage);
      }

      return;
    } catch (e) {
      print("Error: $e");
      return;
    }
  }

  static Future<int> postParameters(String param, String value) async {
    String? serverIP = dotenv.env['SERVER_IP']!;

    var url = Uri.http(
      serverIP, // 호스트 주소
      '/api/user/$param', // 경로
      {param: value},
    );

    var response = await http.post(url);
    return response.statusCode;
  }

  static Future<int> postBody(Map<String, dynamic> params) async {
    String? serverIP = dotenv.env['SERVER_IP']!;

    var url = Uri.http(
      serverIP, // 호스트 주소
      '/api/user/create', // 경로
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
  static Future<int> update(String param, String value) async {
    String? serverIP = dotenv.env['SERVER_IP']!;
    String? token = await Auth.getToken();

    var url = Uri.http(serverIP, '/api/user/update');
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

    var url = Uri.http(
      serverIP, // 호스트 주소
      '/api/user/profile/get', // 경로
      {"id": id},
    );

    var response = await http.get(url);
    return response.bodyBytes;
  }

  static Future<void> setProfile(
      String id, File imageFile, BuildContext context) async {
    String? serverIP = dotenv.env['SERVER_IP']!;

    var url = Uri.http(
      serverIP,
      '/api/user/profile/upload',
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

      File profileImage =
          File('${(await getTemporaryDirectory()).path}/profile_image.png')
            ..writeAsBytesSync(profileImageBytes);
      return;
      // await getProfile(id); // 성공 시 응답 데이터를 반환
    } else {
      throw Exception(
        '이미지 업로드 실패: ${response.statusCode}',
      );
    }
  }
}
