// ============================================================
// car_manager.dart — 核心业务逻辑（Xbox 协议版）
//
// 数据包格式（6字节）：[0xFF, stickX, stickY, 按键Bitmap, LT, RT]
//
// 按键 Bitmap：
//   0x01=A(前进)  0x02=B(后退)  0x04=X(左)  0x08=Y(右)
//   0x10=LB(前灯) 0x20=RB(后灯) 0x40=Start(蜂鸣)
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

/// Xbox 按键枚举
enum XboxButton { a, b, x, y, lb, rb, start, select }

/// 扳机枚举
enum Trigger { lt, rt }

class CarManager extends ChangeNotifier {
  bool isScanning = false;
  bool isConnected = false;
  BluetoothDevice? device;
  BluetoothCharacteristic? txChar;
  BluetoothCharacteristic? rxChar;
  List<ScanResult> devices = [];
  List<String> logs = [];

  /// 摇杆 X 轴：-100~100（负=左，正=右）
  int stickX = 0;

  /// 摇杆 Y 轴：-100~100（负=上，正=下）
  int stickY = 0;

  /// 按键 Bitmap
  int buttonBitmap = 0;

  /// LT（左扳机）
  int lt = 0;

  /// RT（右扳机）
  int rt = 0;

  /// 前灯状态
  bool frontLight = false;

  /// 后灯状态
  bool rearLight = false;

  // ── 日志 ────────────────────────────────────────────────
  void addLog(String msg) {
    final t = DateTime.now().toString().substring(11, 19);
    logs.insert(0, '[\] ');
    if (logs.length > 100) logs.removeLast();
    notifyListeners();
  }

  // ── 扫描 ────────────────────────────────────────────────
  Future<void> startScan() async {
    devices.clear();
    isScanning = true;
    notifyListeners();
    addLog('开始扫描...');
    try {
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 10));
      FlutterBluePlus.scanResults.listen((r) { devices = r; notifyListeners(); });
      await Future.delayed(Duration(seconds: 10));
    } catch (e) { addLog('扫描失败'); }
    isScanning = false;
    addLog('扫描完成，发现 \ 台设备');
    notifyListeners();
  }

  void stopScan() {
    try { FlutterBluePlus.stopScan(); } catch (_) {}
    isScanning = false;
    addLog('扫描已停止');
    notifyListeners();
  }

  // ── 连接 ────────────────────────────────────────────────
  Future<bool> connect(BluetoothDevice d) async {
    try {
      addLog('连接中...');
      await d.connect(timeout: Duration(seconds: 15));
      device = d;
      isConnected = true;
      addLog('连接成功！');
      _discoverServices(d);
      d.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          isConnected = false; txChar = null; rxChar = null;
          _resetAll(); addLog('连接已断开'); notifyListeners();
        }
      });
      notifyListeners();
      return true;
    } catch (e) { addLog('连接失败'); notifyListeners(); return false; }
  }

  Future<void> _discoverServices(BluetoothDevice d) async {
    try {
      final svcs = await d.discoverServices();
      for (final svc in svcs) {
        for (final c in svc.characteristics) {
          final u = c.uuid.toString().toLowerCase();
          if (u.contains('6e400002') || u.contains('ffe1')) {
            txChar = c; addLog('TX: ');
          }
          if (u.contains('6e400003') || u.contains('ffe2')) {
            rxChar = c;
            await c.setNotifyValue(true);
            c.onValueReceived.listen((data) {
              final hex = data.map((b) => b.toRadixString(16).padLeft(2,'0')).join(' ');
              addLog('RX: ');
            });
            addLog('RX: ');
          }
        }
      }
      if (txChar == null) addLog('未找到UART特征，自动模式');
      notifyListeners();
    } catch (e) { addLog('服务发现失败'); }
  }

  Future<void> disconnect() async {
    if (device != null) { try { await device!.disconnect(); } catch (_) {} }
    isConnected = false; txChar = null; rxChar = null;
    _resetAll(); addLog('已断开'); notifyListeners();
  }

  void _resetAll() {
    stickX = 0; stickY = 0; buttonBitmap = 0;
    lt = 0; rt = 0; frontLight = false; rearLight = false;
  }

  // ── Xbox 指令发送 ───────────────────────────────────────

  /// 发送 Xbox 数据包（6字节）
  /// 格式：[0xFF, stickX_offset, stickY_offset, buttons, lt, rt]
  /// stickX/Y 范围 -100~100，发送时 +100 转为 0~200
  Future<void> _sendPacket() async {
    if (txChar == null) return;
    final data = [
      0xFF,
      (stickX + 100).clamp(0, 200),
      (stickY + 100).clamp(0, 200),
      buttonBitmap,
      lt.clamp(0, 100),
      rt.clamp(0, 100),
    ];
    try {
      await txChar!.write(data);
      final hex = data.map((b) => b.toRadixString(16).padLeft(2,'0').toUpperCase()).join(' ');
      addLog('TX: ');
    } catch (e) { addLog('发送失败'); }
  }

  /// 更新摇杆
  void updateStick({int? x, int? y}) {
    if (x != null) stickX = x.clamp(-100, 100);
    if (y != null) stickY = y.clamp(-100, 100);
    _sendPacket(); notifyListeners();
  }

  /// 停止摇杆
  void resetStick() { stickX = 0; stickY = 0; _sendPacket(); notifyListeners(); }

  /// 方向键辅助：dx=-1左/0中/1右，dy=-1上/0中/1下
  void setDirection(int dx, int dy) {
    if (dx == 0 && dy == 0) {
      stickX = 0; stickY = 0;
    } else {
      stickX = dx * 80; // 80% 幅度
      stickY = dy * 80;
    }
    _sendPacket(); notifyListeners();
  }

  /// 按键按下
  void buttonPress(XboxButton btn) {
    buttonBitmap |= _bit(btn);
    switch (btn) {
      case XboxButton.a: setDirection(0, -1); break; // 上
      case XboxButton.b: setDirection(0, 1);  break; // 下
      case XboxButton.x: setDirection(-1, 0);  break; // 左
      case XboxButton.y: setDirection(1, 0);   break; // 右
      case XboxButton.lb:
        frontLight = !frontLight;
        addLog(frontLight ? '前灯开启' : '前灯关闭'); break;
      case XboxButton.rb:
        rearLight = !rearLight;
        addLog(rearLight ? '后灯开启' : '后灯关闭'); break;
      case XboxButton.start:
        addLog('蜂鸣器触发'); break;
    }
    _sendPacket(); notifyListeners();
  }

  /// 按键释放
  void buttonRelease(XboxButton btn) {
    buttonBitmap &= ~_bit(btn);
    if (btn == XboxButton.a || btn == XboxButton.b ||
        btn == XboxButton.x || btn == XboxButton.y) {
      // 检查是否还有方向键按住
      int remaining = buttonBitmap & 0x0F;
      if (remaining == 0) { stickX = 0; stickY = 0; }
      else {
        if (remaining & 0x01 != 0) setDirection(0, -1);
        else if (remaining & 0x02 != 0) setDirection(0, 1);
        else if (remaining & 0x04 != 0) setDirection(-1, 0);
        else if (remaining & 0x08 != 0) setDirection(1, 0);
        return;
      }
    }
    _sendPacket(); notifyListeners();
  }

  /// 扳机变化
  void updateTrigger(Trigger t, int value) {
    value = value.clamp(0, 100);
    if (t == Trigger.lt) {
      lt = value;
      if (value >= 50 && !frontLight) { frontLight = true; addLog('前灯开启'); }
      else if (value < 50 && frontLight) { frontLight = false; addLog('前灯关闭'); }
    } else {
      rt = value;
      if (value >= 50 && !rearLight) { rearLight = true; addLog('后灯开启'); }
      else if (value < 50 && rearLight) { rearLight = false; addLog('后灯关闭'); }
    }
    _sendPacket(); notifyListeners();
  }

  /// 紧急停止
  void emergencyStop() {
    stickX = 0; stickY = 0; buttonBitmap = 0;
    lt = 0; rt = 0; frontLight = false; rearLight = false;
    _sendPacket(); addLog('## 紧急停止 ##'); notifyListeners();
  }

  /// 自定义 HEX 指令
  void sendCustom(String hexInput) {
    try {
      final hex = hexInput.replaceAll(' ', '');
      final data = <int>[];
      for (int i = 0; i + 2 <= hex.length; i += 2)
        data.add(int.parse(hex.substring(i, i + 2), radix: 16));
      if (txChar != null) {
        txChar!.write(data);
        final logHex = data.map((b) => b.toRadixString(16).padLeft(2,'0').toUpperCase()).join(' ');
        addLog('TX: ');
      }
    } catch (_) { addLog('HEX格式错误'); }
  }

  int _bit(XboxButton btn) {
    switch (btn) {
      case XboxButton.a:      return 0x01;
      case XboxButton.b:       return 0x02;
      case XboxButton.x:       return 0x04;
      case XboxButton.y:       return 0x08;
      case XboxButton.lb:      return 0x10;
      case XboxButton.rb:      return 0x20;
      case XboxButton.start:   return 0x40;
      case XboxButton.select:  return 0x80;
    }
  }
}
