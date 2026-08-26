import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const RadarApp());
}

class RadarApp extends StatelessWidget {
  const RadarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RADAR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF2D6A4F),
        scaffoldBackgroundColor: const Color(0xFF0D1B13),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF52B788),
          secondary: Color(0xFF74C69D),
          surface: Color(0xFF132A1C),
        ),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}
