import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'car_manager.dart';
import 'control_screen.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({super.key});

  Color rssiColor(int r) {
    if (r >= -60) return Color(0xFF4CAF50);
    if (r >= -75) return Color(0xFFFF9800);
    return Color(0xFFF44336);
  }

  @override
  Widget build(BuildContext context) {
    final car = context.watch<CarManager>();
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Color(0xFF16213E),
        title: Row(children:[
          Container(width:10, height:10, decoration: BoxDecoration(color:Color(0xFFE94560), shape:BoxShape.circle)),
          SizedBox(width:8),
          Text('BLE\u8f66\u63a7', style: TextStyle(color:Colors.white, fontWeight:FontWeight.w600, fontSize:18)),
        ]),
      ),
      body: car.isConnected
        ? ControlScreen()
        : Column(children:[
            Container(
              color: Color(0xFF16213E),
              padding: EdgeInsets.all(16),
              child: Column(children:[
                Row(children:[
                  Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
                    Text(car.isScanning ? '\u626b\u63cf\u4e2d...' : car.devices.length.toString() + ' \u53f0\u8bbe\u5907',
                      style: TextStyle(color:Colors.white, fontWeight:FontWeight.w500, fontSize:15)),
                    Text(car.isScanning ? '\u6b63\u5728\u641c\u7d22\u8bbe\u5907' : '\u70b9\u51fb\u8fde\u63a5\u8bbe\u5907',
                      style: TextStyle(color:Colors.grey, fontSize:12)),
                  ])),
                  GestureDetector(
                    onTap: () async {
                      if (car.isScanning) { car.stopScan(); return; }
                      await [Permission.bluetooth, Permission.bluetoothScan, Permission.bluetoothConnect, Permission.locationWhenInUse].request();
                      car.startScan();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal:20, vertical:10),
                      decoration: BoxDecoration(
                        color: car.isScanning ? Colors.grey : Color(0xFFE94560),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(children:[
                        if (car.isScanning)
                          SizedBox(width:16, height:16, child: CircularProgressIndicator(strokeWidth:2, color:Colors.white)),
                        if (car.isScanning) SizedBox(width:6),
                        Text(car.isScanning ? '\u505c\u6b62' : '\u626b\u63cf', style: TextStyle(color:Colors.white, fontWeight:FontWeight.bold)),
                      ]),
                    ),
                  ),
                ]),
                SizedBox(height:12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(color:Color(0xFF0F3460), borderRadius:BorderRadius.circular(10)),
                  child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
                    Text('\u652f\u6301\u534f\u8bae\uff1aNordic UART / \u4e32\u53e3\u900f\u4f20BLE\u6a21\u5757',
                      style: TextStyle(color:Color(0xFFE94560), fontWeight:FontWeight.w600, fontSize:13)),
                    SizedBox(height:4),
                    Text('\u6307\u4ee4: 01\u524d 02\u540e 03\u5de6 04\u53f3 00\u505c 10\u706f 11\u5173 20\u8702',
                      style: TextStyle(color:Colors.white70, fontSize:12, fontFamily:'monospace')),
                  ]),
                ),
              ]),
            ),
            Divider(height:1, color:Color(0xFF0F3460)),
            Expanded(child: car.devices.isEmpty
              ? Center(child: Column(mainAxisAlignment:MainAxisAlignment.center, children:[
                  Icon(Icons.bluetooth_searching, size:60, color:Colors.grey.shade600),
                  SizedBox(height:12),
                  Text(car.isScanning ? '\u626b\u63cf\u4e2d...' : '\u672a\u53d1\u73b0\u8bbe\u5907',
                    style: TextStyle(color:Colors.grey.shade500, fontSize:15)),
                ]))
              : ListView.separated(
                itemCount: car.devices.length,
                separatorBuilder: (ctx, idx) => Divider(height:1, color:Color(0xFF0F3460)),
                itemBuilder: (ctx, i) {
                  final r = car.devices[i];
                  final name = r.device.localName.isEmpty ? '\u672a\u77e5\u8bbe\u5907' : r.device.localName;
                  final rc = rssiColor(r.rssi);
                  return InkWell(
                    onTap: () async {
                      final ok = await car.connect(r.device);
                      if (ok && ctx.mounted) Navigator.push(ctx, MaterialPageRoute(builder:(_)=>ControlScreen()));
                    },
                    child: Container(
                      color: Color(0xFF16213E),
                      padding: EdgeInsets.symmetric(horizontal:16, vertical:14),
                      child: Row(children:[
                        Container(width:40, height:40,
                          decoration: BoxDecoration(color:Color(0xFF0F3460), borderRadius:BorderRadius.circular(10)),
                          child: Icon(Icons.toys, color:Color(0xFFE94560), size:22)),
                        SizedBox(width:12),
                        Expanded(child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
                          Text(name, style: TextStyle(color:Colors.white, fontWeight:FontWeight.w600, fontSize:15)),
                          SizedBox(height:2),
                          Text(r.device.remoteId.str, style: TextStyle(color:Color(0xFF6B7280), fontSize:11, fontFamily:'monospace')),
                        ])),
                        Column(crossAxisAlignment:CrossAxisAlignment.end, children:[
                          Text(r.rssi.toString(), style: TextStyle(color:rc, fontWeight:FontWeight.bold, fontSize:16)),
                          Text('dBm', style: TextStyle(color:Colors.grey.shade600, fontSize:10)),
                        ]),
                        SizedBox(width:8),
                        Icon(Icons.chevron_right, color:Color(0xFF3A3A5A), size:20),
                      ]),
                    ),
                  );
                },
              )),
          ]),
    );
  }
}
