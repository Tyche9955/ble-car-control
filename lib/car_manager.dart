import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum Direction { stop, forward, backward, left, right }
enum LedState { off, on }

class CarManager extends ChangeNotifier {
  bool isScanning = false;
  bool isConnected = false;
  BluetoothDevice? device;
  BluetoothCharacteristic? txChar;
  BluetoothCharacteristic? rxChar;
  List<ScanResult> devices = [];
  Direction direction = Direction.stop;
  int speed = 50;
  LedState led = LedState.off;
  List<String> logs = [];

  void addLog(String msg) {
    final t = DateTime.now().toString().substring(11, 19);
    logs.insert(0, '[' + t + '] ' + msg);
    if (logs.length > 100) logs.removeLast();
    notifyListeners();
  }

  Future<void> startScan() async {
    devices.clear();
    isScanning = true;
    notifyListeners();
    addLog('\u5f00\u59cb\u626b\u63cf...');
    try {
      await FlutterBluePlus.startScan(timeout: Duration(seconds: 10));
      FlutterBluePlus.scanResults.listen((r) {
        devices = r;
        notifyListeners();
      });
      await Future.delayed(Duration(seconds: 10));
    } catch (e) {
      addLog('\u626b\u63cf\u5931\u8d25');
    }
    isScanning = false;
    addLog('\u626b\u63cf\u5b8c\u6210\uff0c\u53d1\u73b0 ' + devices.length.toString() + ' \u53f0\u8bbe\u5907');
    notifyListeners();
  }

  void stopScan() {
    try { FlutterBluePlus.stopScan(); } catch (_) {}
    isScanning = false;
    addLog('\u626b\u63cf\u5df2\u505c\u6b62');
    notifyListeners();
  }

  Future<bool> connect(BluetoothDevice d) async {
    try {
      addLog('\u8fde\u63a5\u4e2d...');
      await d.connect(timeout: Duration(seconds: 15));
      device = d;
      isConnected = true;
      addLog('\u8fde\u63a5\u6210\u529f\uff01');
      _discoverServices(d);
      d.connectionState.listen((s) {
        if (s == BluetoothConnectionState.disconnected) {
          isConnected = false;
          txChar = null;
          rxChar = null;
          direction = Direction.stop;
          led = LedState.off;
          addLog('\u8fde\u63a5\u5df2\u65ad\u5f00');
          notifyListeners();
        }
      });
      notifyListeners();
      return true;
    } catch (e) {
      addLog('\u8fde\u63a5\u5931\u8d25');
      notifyListeners();
      return false;
    }
  }

  Future<void> _discoverServices(BluetoothDevice d) async {
    try {
      final svcs = await d.discoverServices();
      for (final svc in svcs) {
        for (final c in svc.characteristics) {
          final u = c.uuid.toString().toLowerCase();
          if (u.contains('6e400002') || u.contains('ffe1')) {
            txChar = c;
            addLog('TX\u7279\u5f81: ' + c.uuid.toString());
          }
          if (u.contains('6e400003') || u.contains('ffe2')) {
            rxChar = c;
            await c.setNotifyValue(true);
            c.onValueReceived.listen((data) {
              final hex = data.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
              addLog('RX: ' + hex);
            });
            addLog('RX\u7279\u5f81: ' + c.uuid.toString());
          }
        }
      }
      if (txChar == null) addLog('\u672a\u627e\u5230UART\uff0c\u81ea\u52a8\u6a21\u5f0f');
      notifyListeners();
    } catch (e) {
      addLog('\u670d\u52a1\u53d1\u73b0\u5931\u8d25');
    }
  }

  Future<void> disconnect() async {
    if (device != null) {
      try { await device!.disconnect(); } catch (_) {}
    }
    isConnected = false;
    txChar = null;
    rxChar = null;
    direction = Direction.stop;
    led = LedState.off;
    addLog('\u5df2\u65ad\u5f00');
    notifyListeners();
  }

  Future<void> sendCommand(List<int> data) async {
    if (txChar == null) { addLog('\u672a\u914d\u7f6e\u53d1\u9001\u7279\u5f81'); return; }
    try {
      await txChar!.write(data);
      final hex = data.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
      addLog('TX: ' + hex);
    } catch (e) { addLog('\u53d1\u9001\u5931\u8d25'); }
  }

  Future<void> sendDirection(Direction dir) async {
    direction = dir;
    notifyListeners();
    int cmd = 0x00;
    if (dir == Direction.forward) { cmd = 0x01; }
    else if (dir == Direction.backward) { cmd = 0x02; }
    else if (dir == Direction.left) { cmd = 0x03; }
    else if (dir == Direction.right) { cmd = 0x04; }
    await sendCommand([cmd, speed]);
  }

  void stop() => sendDirection(Direction.stop);

  void setSpeed(int s) {
    speed = s.clamp(0, 100);
    notifyListeners();
    if (direction != Direction.stop && isConnected) sendDirection(direction);
  }

  void toggleLed() {
    if (led == LedState.off) {
      led = LedState.on;
      sendCommand([0x10]);
    } else {
      led = LedState.off;
      sendCommand([0x11]);
    }
    notifyListeners();
  }

  void sendBuzzer() => sendCommand([0x20]);

  void sendCustom(String hexInput) {
    try {
      final h = hexInput.replaceAll(' ', '');
      final data = <int>[];
      for (int i = 0; i < h.length; i += 2) {
        if (i + 2 <= h.length) {
          data.add(int.parse(h.substring(i, i + 2), radix: 16));
        }
      }
      sendCommand(data);
    } catch (_) { addLog('HEX\u683c\u5f0f\u9519\u8bef'); }
  }
}
