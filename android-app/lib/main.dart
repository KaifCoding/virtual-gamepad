import 'package:flutter/material.dart';

import 'screens/connect_screen.dart';

void main() {
  runApp(const VirtualGamepadApp());
}

class VirtualGamepadApp extends StatelessWidget {
  const VirtualGamepadApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Gamepad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const ConnectScreen(),
    );
  }
}
