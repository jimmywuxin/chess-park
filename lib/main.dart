import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'presentation/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const ChessParkApp());
}

class ChessParkApp extends StatelessWidget {
  const ChessParkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '象棋乐园',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B4513),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'PingFang SC',
      ),
      home: const MainScreen(),
    );
  }
}
