import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'car_manager.dart';
import 'scan_screen.dart';

void main() {
  runApp(ChangeNotifierProvider(create: (_) => CarManager(), child: CarApp()));
}

class CarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE\u8f66\u63a7',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF1A1A2E),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFFE94560),
          secondary: Color(0xFF0F3460),
          surface: Color(0xFF16213E),
        ),
        appBarTheme: AppBarTheme(backgroundColor: Color(0xFF16213E)),
      ),
      home: ScanScreen(),
    );
  }
}
