// ============================================================
// scan_screen.dart — BLE 设备扫描页
//
// 职责：
//   - 申请蓝牙和位置权限
//   - 展示扫描到的 BLE 设备列表（含 RSSI 信号强度）
//   - 点击设备发起连接，连接成功后跳转控制页
//   - 已连接时直接显示控制页（内嵌模式）
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'car_manager.dart';
import 'control_screen.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  /// 根据 RSSI 信号强度返回对应颜色
  ///   >= -60 dBm：绿色（信号强）
  ///   >= -75 dBm：橙色（信号中等）
  ///    < -75 dBm：红色（信号弱）
  Color rssiColor(int rssi) {
    if (rssi >= -60) return Color(0xFF4CAF50); // 绿
    if (rssi >= -75) return Color(0xFFFF9800); // 橙
    return Color(0xFFF44336);                  // 红
  }

  @override
  Widget build(BuildContext context) {
    // 监听 CarManager 状态，任何变化都会触发重建
    final car = context.watch<CarManager>();

    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Color(0xFF16213E),
        title: Row(children: [
          // 红色圆点装饰
          Container(
            width: 10, height: 10,
            decoration: BoxDecoration(
              color: Color(0xFFE94560),
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Text(
            'BLE车控',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
        ]),
      ),

      // 已连接时直接显示控制页，未连接时显示扫描页
      body: car.isConnected
          ? ControlScreen()
          : _buildScanBody(context, car),
    );
  }

  /// 构建扫描页主体（顶部信息栏 + 设备列表）
  Widget _buildScanBody(BuildContext context, CarManager car) {
    return Column(children: [
      // ── 顶部信息栏 ──────────────────────────────────────
      Container(
        color: Color(0xFF16213E),
        padding: EdgeInsets.all(16),
        child: Column(children: [
          // 状态文字 + 扫描按钮
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  car.isScanning
                      ? '扫描中...'
                      : '\${car.devices.length} 台设备',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                Text(
                  car.isScanning ? '正在搜索BLE设备' : '点击设备连接',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            )),

            // 扫描/停止按钮
            GestureDetector(
              onTap: () async {
                if (car.isScanning) {
                  car.stopScan();
                  return;
                }
                // 扫描前先申请所需权限
                await [
                  Permission.bluetooth,
                  Permission.bluetoothScan,
                  Permission.bluetoothConnect,
                  Permission.locationWhenInUse,
                ].request();
                car.startScan();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: car.isScanning ? Colors.grey : Color(0xFFE94560),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(children: [
                  // 扫描中显示加载动画
                  if (car.isScanning) ...[
                    SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 6),
                  ],
                  Text(
                    car.isScanning ? '停止' : '扫描',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ]),
              ),
            ),
          ]),

          SizedBox(height: 12),

          // 协议说明卡片
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF0F3460),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '支持协议：Nordic UART / 串口透传BLE模块',
                  style: TextStyle(
                    color: Color(0xFFE94560),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '指令: 01前 02后 03左 04右 00停 10灯 11关 20蜂',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),

      Divider(height: 1, color: Color(0xFF0F3460)),

      // ── 设备列表 ─────────────────────────────────────────
      Expanded(
        child: car.devices.isEmpty
            ? _buildEmptyState(car) // 空状态提示
            : _buildDeviceList(context, car), // 设备列表
      ),
    ]);
  }

  /// 空状态：未扫描到设备时显示的提示
  Widget _buildEmptyState(CarManager car) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bluetooth_searching,
            size: 60,
            color: Colors.grey.shade600,
          ),
          SizedBox(height: 12),
          Text(
            car.isScanning ? '扫描中...' : '未发现设备',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
          ),
        ],
      ),
    );
  }

  /// 设备列表：每行显示设备名、MAC 地址、RSSI 信号强度
  Widget _buildDeviceList(BuildContext context, CarManager car) {
    return ListView.separated(
      itemCount: car.devices.length,
      separatorBuilder: (ctx, idx) => Divider(
        height: 1,
        color: Color(0xFF0F3460),
      ),
      itemBuilder: (ctx, i) {
        final result = car.devices[i];
        // 没有设备名时显示"未知设备"
        final name = result.device.localName.isEmpty
            ? '未知设备'
            : result.device.localName;
        final signalColor = rssiColor(result.rssi);

        return InkWell(
          onTap: () async {
            // 点击设备 → 发起连接 → 成功后跳转控制页
            final ok = await car.connect(result.device);
            if (ok && ctx.mounted) {
              Navigator.push(
                ctx,
                MaterialPageRoute(builder: (_) => ControlScreen()),
              );
            }
          },
          child: Container(
            color: Color(0xFF16213E),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              // 设备图标
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: Color(0xFF0F3460),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.toys, color: Color(0xFFE94560), size: 22),
              ),
              SizedBox(width: 12),

              // 设备名 + MAC 地址
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    result.device.remoteId.str, // MAC 地址
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              )),

              // RSSI 信号强度
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    result.rssi.toString(),
                    style: TextStyle(
                      color: signalColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'dBm',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),

              SizedBox(width: 8),
              Icon(Icons.chevron_right, color: Color(0xFF3A3A5A), size: 20),
            ]),
          ),
        );
      },
    );
  }
}
