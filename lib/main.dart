import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
// pages
import 'package:cinetalk/init_page/login.dart';
import 'package:cinetalk/init_page/page_list.dart';
// features
import 'package:cinetalk/features/user_provider.dart';
import 'package:cinetalk/features/movie_provider.dart';
import 'package:cinetalk/features/chat_provider.dart';
import 'package:cinetalk/features/api.dart';
import 'package:cinetalk/features/auth.dart';

void main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => MovieProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    bool isValid = await Auth.validateToken();

    Future.delayed(const Duration(seconds: 2), () async {
      if (isValid) {
        await UserApi.userInfo(context);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => PageList()),
        );
      } else {
        Auth.clearToken();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Login()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.blueAccent,
      body: Center(
        child: Text(
          'CINEMATE',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
