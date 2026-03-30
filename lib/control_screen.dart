// ============================================================
// control_screen.dart — 小车控制页
//
// 功能：速度滑块、方向控制（按下发送，松手停止）、灯光、蜂鸣、HEX指令、日志查看
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'car_manager.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});
  @override State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  bool _showLog = false; // 是否显示日志页
  final _hexCtrl = TextEditingController();

  @override void dispose() { _hexCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final car = context.watch<CarManager>();
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Color(0xFF16213E),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题：设备名或MAC地址
            Text(
              car.device != null
                ? (car.device!.localName.isEmpty ? car.device!.remoteId.str : car.device!.localName)
                : '小车控制',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
            ),
            // 状态指示
            Row(children: [
              Container(width: 6, height: 6, decoration: BoxDecoration(color: Color(0xFF4CAF50), shape: BoxShape.circle)),
              SizedBox(width: 4),
              Text(car.txChar != null ? '已就绪' : '自动模式', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 11)),
            ]),
          ],
        ),
        actions: [
          // 切换控制页/日志页
          IconButton(
            icon: Icon(_showLog ? Icons.gamepad : Icons.article, color: _showLog ? Color(0xFFE94560) : Colors.white),
            onPressed: () => setState(() => _showLog = !_showLog),
          ),
          // 断开连接
          TextButton(
            onPressed: () { car.disconnect(); Navigator.pop(context); },
            child: Text('断开', style: TextStyle(color: Color(0xFFF44336))),
          ),
        ],
      ),
      body: _showLog ? _buildLog(car) : _buildControl(car),
    );
  }

  // ========== 控制页 ==========
  Widget _buildControl(CarManager car) {
    return Column(children: [
      SizedBox(height: 16),
      // 速度滑块
      Container(
        margin: EdgeInsets.symmetric(horizontal: 20),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: Color(0xFF16213E), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(Icons.speed, color: Color(0xFFE94560), size: 18),
              SizedBox(width: 8),
              Text('速度', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: Color(0xFFE94560), borderRadius: BorderRadius.circular(20)),
                child: Text('${car.speed}%', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ]),
            SizedBox(height: 8),
            Slider(
              value: car.speed.toDouble(), min: 0, max: 100, divisions: 20,
              activeColor: Color(0xFFE94560), inactiveColor: Colors.grey.shade800,
              onChanged: (v) => car.setSpeed(v.toInt()),
            ),
          ],
        ),
      ),
      SizedBox(height: 20),
      // 方向控制十字键盘
      Center(child: Column(children: [
        _dirBtn(Direction.forward, Icons.arrow_upward, '前进', car),
        SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _dirBtn(Direction.left, Icons.turn_left, '左', car),
          SizedBox(width: 8),
          _stopBtn(car),
          SizedBox(width: 8),
          _dirBtn(Direction.right, Icons.turn_right, '右', car),
        ]),
        SizedBox(height: 8),
        _dirBtn(Direction.backward, Icons.arrow_downward, '后退', car),
      ])),
      SizedBox(height: 20),
      // 功能按钮：灯光 + 蜂鸣
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          _funcBtn(Icons.highlight, '灯光', car.led == LedState.on ? Color(0xFFFFEB3B) : Colors.grey.shade700, () => car.toggleLed()),
          SizedBox(width: 10),
          _funcBtn(Icons.volume_up, '蜂鸣', Colors.grey.shade700, () => car.sendBuzzer()),
        ]),
      ),
      Spacer(),
      // HEX自定义指令输入
      Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(color: Color(0xFF16213E), borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Expanded(child: TextField(
            controller: _hexCtrl,
            style: TextStyle(color: Colors.white, fontFamily: 'monospace'),
            decoration: InputDecoration(hintText: 'HEX指令如: 01 64', hintStyle: TextStyle(color: Colors.grey), border: InputBorder.none),
          )),
          GestureDetector(
            onTap: () { if (_hexCtrl.text.isNotEmpty) { car.sendCustom(_hexCtrl.text); _hexCtrl.clear(); } },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: Color(0xFFE94560), borderRadius: BorderRadius.circular(8)),
              child: Text('发送', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    ]);
  }

  // ========== 按钮组件 ==========
  Widget _stopBtn(CarManager car) {
    return GestureDetector(
      onTapDown: (_) => car.stop(), // 按下停止
      child: Container(
        width: 72, height: 72,
        decoration: BoxDecoration(color: Color(0xFF0F3460), shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade700, width: 2)),
        child: Icon(Icons.stop, color: Colors.white, size: 36),
      ),
    );
  }

  Widget _dirBtn(Direction dir, IconData icon, String label, CarManager car) {
    return GestureDetector(
      onTapDown: (_) => car.sendDirection(dir), // 按下开始运动
      onTapUp: (_) => car.stop(),               // 松开停止
      onTapCancel: () => car.stop(),            // 取消停止
      child: Container(
        width: 72, height: 72,
        decoration: BoxDecoration(color: Color(0xFF0F3460), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade700, width: 2)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.grey.shade400, size: 28),
          SizedBox(height: 2),
          Text(label, style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _funcBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: Color(0xFF16213E), borderRadius: BorderRadius.circular(12)),
          child: Column(children: [Icon(icon, color: color, size: 24), SizedBox(height: 4), Text(label, style: TextStyle(color: color, fontSize: 12))]),
        ),
      ),
    );
  }

  // ========== 日志页 ==========
  Widget _buildLog(CarManager car) {
    return Column(children: [
      Container(
        color: Color(0xFF16213E),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Text('通信日志', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          Spacer(),
          GestureDetector(
            onTap: () { car.logs.clear(); car.notifyListeners(); },
            child: Text('清除', style: TextStyle(color: Color(0xFFE94560))),
          ),
        ]),
      ),
      Expanded(
        child: car.logs.isEmpty
          ? Center(child: Text('暂无日志', style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: EdgeInsets.all(12),
              itemCount: car.logs.length,
              itemBuilder: (ctx, i) => Container(
                margin: EdgeInsets.only(bottom: 4),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(color: Color(0xFF16213E), borderRadius: BorderRadius.circular(6)),
                child: Text(car.logs[i], style: TextStyle(color: Color(0xFF4CAF50), fontSize: 12, fontFamily: 'monospace')),
              ),
            ),
      ),
    ]);
  }
}
