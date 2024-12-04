import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
// features
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
}
