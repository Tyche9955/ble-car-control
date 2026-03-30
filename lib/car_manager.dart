// ============================================================
// car_manager.dart — 核心业务逻辑层
//
// 职责：
//   - 管理 BLE 扫描、连接、断开
//   - 自动发现 UART 特征值（Nordic UART / HM-10）
//   - 封装所有指令发送（方向、速度、灯光、蜂鸣）
//   - 维护通信日志
//   - 继承 ChangeNotifier，状态变化时通知 UI 刷新
//
// 指令协议（2字节）：[命令码, 速度]
//   0x00 = 停止    0x01 = 前进    0x02 = 后退
//   0x03 = 左转    0x04 = 右转
//   0x10 = 开灯    0x11 = 关灯    0x20 = 蜂鸣
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// 小车运动方向枚举
enum Direction { stop, forward, backward, left, right }

/// 车灯状态枚举
enum LedState { off, on }

/// CarManager — 小车状态管理器
///
/// 使用 Provider 模式，所有 UI 组件通过 context.watch<CarManager>()
/// 订阅状态变化，无需手动 setState。
class CarManager extends ChangeNotifier {
  // ── 状态字段 ──────────────────────────────────────────────

  bool isScanning = false;      // 是否正在扫描
  bool isConnected = false;     // 是否已连接设备
  BluetoothDevice? device;      // 当前连接的蓝牙设备
  BluetoothCharacteristic? txChar; // 发送特征值（手机 → 小车）
  BluetoothCharacteristic? rxChar; // 接收特征值（小车 → 手机）
  List<ScanResult> devices = [];   // 扫描到的设备列表
  Direction direction = Direction.stop; // 当前运动方向
  int speed = 50;               // 当前速度（0–100）
  LedState led = LedState.off;  // 当前灯光状态
  List<String> logs = [];       // 通信日志（最多保留100条）

  // ── 日志 ──────────────────────────────────────────────────

  /// 添加一条带时间戳的日志，插入到列表头部（最新在上）
  void addLog(String msg) {
    final time = DateTime.now().toString().substring(11, 19); // HH:mm:ss
    logs.insert(0, '[$time] $msg');
    if (logs.length > 100) logs.removeLast(); // 超过100条时删除最旧的
    notifyListeners();
  }

  // ── 扫描 ──────────────────────────────────────────────────

  /// 开始 BLE 扫描，持续 10 秒
  ///
  /// 扫描结果实时更新到 [devices] 列表，UI 会自动刷新。
  Future<void> startScan() async {
    devices.clear();
    isScanning = true;
    notifyListeners();
    addLog('开始扫描...');

    try {
      // 启动扫描，设置超时时间
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 10));

      // 监听扫描结果流，每次有新设备都更新列表
      FlutterBluePlus.scanResults.listen((results) {
        devices = results;
        notifyListeners();
      });

      // 等待扫描完成
      await Future.delayed(Duration(seconds: 10));
    } catch (e) {
      addLog('扫描失败');
    }

    isScanning = false;
    addLog('扫描完成，发现 \${devices.length} 台设备');
    notifyListeners();
  }

  /// 手动停止扫描
  void stopScan() {
    try { FlutterBluePlus.stopScan(); } catch (_) {}
    isScanning = false;
    addLog('扫描已停止');
    notifyListeners();
  }

  // ── 连接 ──────────────────────────────────────────────────

  /// 连接指定蓝牙设备
  ///
  /// 连接成功后自动调用 [_discoverServices] 发现 UART 特征值。
  /// 同时监听连接状态，断开时自动重置所有状态。
  ///
  /// 返回 true 表示连接成功，false 表示失败。
  Future<bool> connect(BluetoothDevice d) async {
    try {
      addLog('连接中...');
      await d.connect(timeout: Duration(seconds: 15));

      device = d;
      isConnected = true;
      addLog('连接成功！');

      // 连接成功后异步发现服务（不阻塞 UI）
      _discoverServices(d);

      // 监听连接状态变化，设备断开时自动清理状态
      d.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          isConnected = false;
          txChar = null;
          rxChar = null;
          direction = Direction.stop;
          led = LedState.off;
          addLog('连接已断开');
          notifyListeners();
        }
      });

      notifyListeners();
      return true;
    } catch (e) {
      addLog('连接失败');
      notifyListeners();
      return false;
    }
  }

  /// 发现 GATT 服务，自动识别 UART 特征值
  ///
  /// 支持两种常见协议：
  ///   - Nordic UART：TX=6E400002, RX=6E400003
  ///   - HM-10/HC-08：TX=FFE1, RX=FFE2
  ///
  /// 找到 RX 特征后自动开启 Notify，接收小车回传数据。
  Future<void> _discoverServices(BluetoothDevice d) async {
    try {
      final services = await d.discoverServices();

      for (final service in services) {
        for (final characteristic in service.characteristics) {
          final uuid = characteristic.uuid.toString().toLowerCase();

          // 识别发送特征（手机 → 小车）
          if (uuid.contains('6e400002') || uuid.contains('ffe1')) {
            txChar = characteristic;
            addLog('TX特征: \${characteristic.uuid}');
          }

          // 识别接收特征（小车 → 手机），并开启通知
          if (uuid.contains('6e400003') || uuid.contains('ffe2')) {
            rxChar = characteristic;
            await characteristic.setNotifyValue(true); // 开启 Notify

            // 监听小车回传数据，转为 HEX 字符串显示在日志
            characteristic.onValueReceived.listen((data) {
              final hex = data
                  .map((b) => b.toRadixString(16).padLeft(2, '0'))
                  .join(' ');
              addLog('RX: \$hex');
            });

            addLog('RX特征: \${characteristic.uuid}');
          }
        }
      }

      if (txChar == null) addLog('未找到UART特征，自动模式');
      notifyListeners();
    } catch (e) {
      addLog('服务发现失败');
    }
  }

  /// 主动断开连接，重置所有状态
  Future<void> disconnect() async {
    if (device != null) {
      try { await device!.disconnect(); } catch (_) {}
    }
    isConnected = false;
    txChar = null;
    rxChar = null;
    direction = Direction.stop;
    led = LedState.off;
    addLog('已断开');
    notifyListeners();
  }

  // ── 指令发送 ──────────────────────────────────────────────

  /// 发送原始字节数组到小车
  ///
  /// 通过 [txChar] 写入数据，同时记录到日志。
  Future<void> sendCommand(List<int> data) async {
    if (txChar == null) {
      addLog('未配置发送特征');
      return;
    }
    try {
      await txChar!.write(data);
      // 将发送的字节转为大写 HEX 字符串记录日志
      final hex = data
          .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
          .join(' ');
      addLog('TX: \$hex');
    } catch (e) {
      addLog('发送失败');
    }
  }

  /// 发送方向指令
  ///
  /// 格式：[命令码, 速度]，例如前进50%速度 = [0x01, 50]
  Future<void> sendDirection(Direction dir) async {
    direction = dir;
    notifyListeners();

    // 将枚举映射为命令码
    int cmd;
    switch (dir) {
      case Direction.forward:  cmd = 0x01; break;
      case Direction.backward: cmd = 0x02; break;
      case Direction.left:     cmd = 0x03; break;
      case Direction.right:    cmd = 0x04; break;
      default:                 cmd = 0x00; // stop
    }

    await sendCommand([cmd, speed]);
  }

  /// 停止小车（发送停止指令）
  void stop() => sendDirection(Direction.stop);

  /// 设置速度并立即生效（如果正在运动中）
  ///
  /// [s] 范围 0–100，超出范围自动截断。
  void setSpeed(int s) {
    speed = s.clamp(0, 100);
    notifyListeners();
    // 如果当前正在运动，立即用新速度重发方向指令
    if (direction != Direction.stop && isConnected) {
      sendDirection(direction);
    }
  }

  /// 切换灯光状态（开 ↔ 关）
  void toggleLed() {
    if (led == LedState.off) {
      led = LedState.on;
      sendCommand([0x10]); // 开灯指令
    } else {
      led = LedState.off;
      sendCommand([0x11]); // 关灯指令
    }
    notifyListeners();
  }

  /// 触发蜂鸣器
  void sendBuzzer() => sendCommand([0x20]);

  /// 发送自定义 HEX 指令
  ///
  /// [hexInput] 格式：空格分隔的十六进制字符串，如 "01 64" 或 "0164"
  void sendCustom(String hexInput) {
    try {
      final hex = hexInput.replaceAll(' ', ''); // 去掉空格
      final data = <int>[];
      // 每两个字符解析为一个字节
      for (int i = 0; i + 2 <= hex.length; i += 2) {
        data.add(int.parse(hex.substring(i, i + 2), radix: 16));
      }
      sendCommand(data);
    } catch (_) {
      addLog('HEX格式错误');
    }
  }
}
