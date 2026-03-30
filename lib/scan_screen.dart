// scan_screen.dart - Xbox BLE 车控 扫描页
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'car_manager.dart';
import 'control_screen.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  Color rssiColor(int rssi) {
    if (rssi >= -60) return Color(0xFF107C10);
    if (rssi >= -75) return Color(0xFFFFB900);
    return Color(0xFFE81123);
  }

  @override
  Widget build(BuildContext context) {
    final car = context.watch<CarManager>();
    return Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Color(0xFF107C10),
        title: Row(children: [
          Container(width:12, height:12,
            decoration: BoxDecoration(color:Color(0xFF107C10), shape:BoxShape.circle,
              border: Border.all(color:Colors.white, width:2))),
          SizedBox(width:10),
          Text('Xbox BLE 车控', style: TextStyle(color:Colors.white, fontWeight:FontWeight.w600, fontSize:18)),
        ]),
      ),
      body: car.isConnected ? ControlScreen() : _buildBody(context, car),
    );
  }

  Widget _buildBody(BuildContext context, CarManager car) {
    return Column(children: [
      Container(
        color: Color(0xFF1F1F1F),
        padding: EdgeInsets.all(16),
        child: Column(children: [
          Row(children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(car.isScanning ? '扫描中...' : '${car.devices.length} 台设备',
                  style: TextStyle(color:Colors.white, fontWeight:FontWeight.w500, fontSize:15)),
                Text(car.isScanning ? '正在搜索BLE设备' : '点击设备连接',
                  style: TextStyle(color:Colors.grey, fontSize:12)),
              ],
            )),
            GestureDetector(
              onTap: () async {
                if (car.isScanning) { car.stopScan(); return; }
                await [
                  Permission.bluetooth,
                  Permission.bluetoothScan,
                  Permission.bluetoothConnect,
                  Permission.locationWhenInUse,
                ].request();
                car.startScan();
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal:22, vertical:10),
                decoration: BoxDecoration(
                  color: car.isScanning ? Colors.grey : Color(0xFF107C10),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(children: [
                  if (car.isScanning) ...[
                    SizedBox(width:14, height:14,
                      child: CircularProgressIndicator(strokeWidth:2, color:Colors.white)),
                    SizedBox(width:6),
                  ],
                  Text(car.isScanning ? '停止' : '扫描',
                    style: TextStyle(color:Colors.white, fontWeight:FontWeight.bold)),
                ]),
              ),
            ),
          ]),
          SizedBox(height:12),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('支持：Nordic UART / HM-10 / HC-08 BLE模块',
                  style: TextStyle(color:Color(0xFF107C10), fontWeight:FontWeight.w600, fontSize:13)),
                SizedBox(height:4),
                Text('Xbox协议: [0xFF, 摇杆X, 摇杆Y, 按键Bitmap, LT, RT]',
                  style: TextStyle(color:Colors.white70, fontSize:12, fontFamily:'monospace')),
              ],
            ),
          ),
        ]),
      ),
      Divider(height:1, color:Color(0xFF2D2D2D)),
      Expanded(
        child: car.devices.isEmpty
          ? Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gamepad, size:60, color:Colors.grey.shade700),
                SizedBox(height:12),
                Text(car.isScanning ? '扫描中...' : '未发现设备',
                  style: TextStyle(color:Colors.grey.shade500, fontSize:15)),
              ],
            ))
          : ListView.separated(
            itemCount: car.devices.length,
            separatorBuilder: (ctx, idx) => Divider(height:1, color:Color(0xFF2D2D2D)),
            itemBuilder: (ctx, i) {
              final r = car.devices[i];
              final name = r.device.localName.isEmpty ? '未知设备' : r.device.localName;
              final rc = rssiColor(r.rssi);
              return InkWell(
                onTap: () async {
                  final ok = await car.connect(r.device);
                  if (ok && ctx.mounted) {
                    Navigator.push(ctx, MaterialPageRoute(builder: (_) => ControlScreen()));
                  }
                },
                child: Container(
                  color: Color(0xFF1F1F1F),
                  padding: EdgeInsets.symmetric(horizontal:16, vertical:14),
                  child: Row(children: [
                    Container(
                      width: 42, height: 42,
                      decoration: BoxDecoration(
                        color: Color(0xFF107C10).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Color(0xFF107C10).withOpacity(0.3)),
                      ),
                      child: Icon(Icons.gamepad, color: Color(0xFF107C10), size: 24),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(color:Colors.white, fontWeight:FontWeight.w600, fontSize:15)),
                          SizedBox(height: 2),
                          Text(r.device.remoteId.str,
                            style: TextStyle(color:Color(0xFF6B7280), fontSize:11, fontFamily:'monospace')),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(r.rssi.toString(),
                          style: TextStyle(color:rc, fontWeight:FontWeight.bold, fontSize:16)),
                        Text('dBm', style: TextStyle(color:Colors.grey.shade600, fontSize:10)),
                      ],
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.chevron_right, color: Color(0xFF3A3A5A), size: 20),
                  ]),
                ),
              );
            },
          ),
      ),
    ]);
  }
}
