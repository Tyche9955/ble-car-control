// main.dart - Xbox BLE 车控 APP 入口
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
      title: 'Xbox BLE 车控',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF0D0D0D),
        colorScheme: ColorScheme.dark(
          primary: Color(0xFF107C10),
          secondary: Color(0xFF1F1F1F),
          surface: Color(0xFF141414),
        ),
        appBarTheme: AppBarTheme(backgroundColor: Color(0xFF107C10)),
      ),
      home: ScanScreen(),
    );
  }
}
