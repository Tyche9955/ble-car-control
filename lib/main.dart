// ============================================================
// main.dart — 应用入口
//
// 职责：
//   1. 初始化全局状态管理（CarManager）
//   2. 配置 MaterialApp 主题（深色风格）
//   3. 设置首页为扫描页（ScanScreen）
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'car_manager.dart';
import 'scan_screen.dart';

void main() {
  // 用 ChangeNotifierProvider 包裹整个应用，
  // 使 CarManager 的状态变化能通知所有子组件刷新
  runApp(
    ChangeNotifierProvider(
      create: (_) => CarManager(),
      child: CarApp(),
    ),
  );
}

class CarApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BLE车控',
      debugShowCheckedModeBanner: false, // 去掉右上角 DEBUG 标签

      // 全局深色主题配置
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF1A1A2E), // 页面背景：深蓝黑
        colorScheme: ColorScheme.dark(
          primary: Color(0xFFE94560),   // 主色：红色（按钮、高亮）
          secondary: Color(0xFF0F3460), // 辅色：深蓝（卡片背景）
          surface: Color(0xFF16213E),   // 表面色：导航栏、面板
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF16213E), // 顶栏背景色
        ),
      ),

      home: ScanScreen(), // 首页：BLE 设备扫描页
    );
  }
}
