import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  static Future<Map<String, dynamic>> userInfo() async {
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

      return jsonDecode(utf8.decode(response.bodyBytes));
    } catch (e) {
      print("Error: $e");
      return {};
    }
  }
}
