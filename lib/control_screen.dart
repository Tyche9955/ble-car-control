// ============================================================
// control_screen.dart - Xbox 风格控制页
//
// Xbox 布局（从上到下，从左到右）：
//
//   [LT]              [RT]              <- 扳机（顶部）
//   [LB]              [RB]              <- 肩键
//
//   [左摇杆]     [Y]
//              [X]  [A]  [B]            <- ABXY 菱形
//           [View][Menu]               <- 视图/菜单
//
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'car_manager.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});
  @override State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  bool _showLog = false;
  final _hexCtrl = TextEditingController();

  @override void dispose() { _hexCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final car = context.watch<CarManager>();
    return Scaffold(
      backgroundColor: Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: Color(0xFF107C10),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              car.device != null
                  ? (car.device!.localName.isEmpty ? car.device!.remoteId.str : car.device!.localName)
                  : 'Xbox 车控',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
            ),
            Row(children: [
              Container(width: 6, height: 6,
                decoration: BoxDecoration(color: Color(0xFF107C10), shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1)),
              ),
              SizedBox(width: 4),
              Text(car.txChar != null ? '已就绪' : '自动模式',
                style: TextStyle(color: Colors.white70, fontSize: 11)),
            ]),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showLog ? Icons.gamepad : Icons.article,
              color: _showLog ? Colors.white : Colors.white70),
            onPressed: () => setState(() => _showLog = !_showLog),
          ),
          IconButton(
            icon: Icon(Icons.power_settings_new, color: Colors.red.shade300),
            tooltip: '紧急停止',
            onPressed: () {
              context.read<CarManager>().emergencyStop();
              setState(() {});
            },
          ),
          TextButton(
            onPressed: () { car.disconnect(); Navigator.pop(context); },
            child: Text('断开', style: TextStyle(color: Colors.red.shade300)),
          ),
        ],
      ),
      body: _showLog ? _buildLog(car) : _buildXboxBody(car),
    );
  }

  // ========================================================
  // Xbox 主体
  // ========================================================
  Widget _buildXboxBody(CarManager car) {
    return Column(children: [
      // 扳机键区（LT / RT）
      Padding(
        padding: EdgeInsets.fromLTRB(24, 10, 24, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildTrigger('LT', car.lt,
              () => car.updateTrigger(Trigger.lt, 100),
              () => car.updateTrigger(Trigger.lt, 0), car.frontLight),
            _buildStatusHub(car),
            _buildTrigger('RT', car.rt,
              () => car.updateTrigger(Trigger.rt, 100),
              () => car.updateTrigger(Trigger.rt, 0), car.rearLight),
          ],
        ),
      ),

      // 肩键 + 主控制区
      Expanded(
        child: Stack(children: [
          // LB（左肩键）
          Positioned(left: 16, top: 6,
            child: _buildBumper('LB',
              car.buttonBitmap & 0x10 != 0,
              () { car.buttonPress(XboxButton.lb); setState(() {}); },
              () { car.buttonRelease(XboxButton.lb); setState(() {}); })),

          // RB（右肩键）
          Positioned(right: 16, top: 6,
            child: _buildBumper('RB',
              car.buttonBitmap & 0x20 != 0,
              () { car.buttonPress(XboxButton.rb); setState(() {}); },
              () { car.buttonRelease(XboxButton.rb); setState(() {}); })),

          // 主控制区（居中）
          Center(child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLeftStick(car),
              SizedBox(width: 50),
              _buildRightArea(car),
            ],
          )),
        ]),
      ),

      // 底部 HEX 输入
      _buildBottomBar(car),
    ]);
  }

  // ========================================================
  // 左摇杆（LS）- 十字方向 + 圆形底座
  // ========================================================
  Widget _buildLeftStick(CarManager car) {
    return Column(children: [
      Container(
        width: 130, height: 130,
        decoration: BoxDecoration(
          color: Color(0xFF1C1C1C),
          shape: BoxShape.circle,
          border: Border.all(color: Color(0xFF2E2E2E), width: 3),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: Offset(0, 4))],
        ),
        child: Stack(alignment: Alignment.center, children: [
          // 十字方向指示（固定灰色）
          Positioned(top: 8, child: Icon(Icons.arrow_drop_up, color: Color(0xFF3A3A3A), size: 36)),
          Positioned(bottom: 8, child: Icon(Icons.arrow_drop_down, color: Color(0xFF3A3A3A), size: 36)),
          Positioned(left: 8, child: Icon(Icons.arrow_left, color: Color(0xFF3A3A3A), size: 28)),
          Positioned(right: 8, child: Icon(Icons.arrow_right, color: Color(0xFF3A3A3A), size: 28)),

          // 左摇杆小球（跟随 stickX/Y 移动）
          AnimatedContainer(
            duration: Duration(milliseconds: 60),
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: Color(0xFF3A3A3A),
              shape: BoxShape.circle,
              border: Border.all(color: Color(0xFF555555), width: 2),
            ),
            transform: Matrix4.translationValues(
              (car.stickX / 100 * 30).toDouble(),
              (car.stickY / 100 * 30).toDouble(),
              0,
            ),
          ),
        ]),
      ),
      SizedBox(height: 8),
      Text('LS', style: TextStyle(color: Color(0xFF555555), fontSize: 11, fontWeight: FontWeight.bold)),
    ]);
  }

  // ========================================================
  // 右区：ABXY 菱形 + 中央键
  //
  //   Xbox ABXY 菱形标准布局（俯视图）：
  //            Y (上-黄色)
  //        X (左-蓝色)   A (右-绿色)
  //            B (下-红色)
  // ========================================================
  Widget _buildRightArea(CarManager car) {
    return Column(children: [
      // ABXY 按钮区（160x160 容器）
      Container(
        width: 160, height: 160,
        child: Stack(alignment: Alignment.center, children: [
          // Y - 上（黄色）
          Positioned(top: 0,
            child: _buildAbxyBtn('Y', XboxButton.y,
              car.buttonBitmap & 0x08 != 0, car)),

          // X - 左（蓝色）
          Positioned(left: 0,
            child: _buildAbxyBtn('X', XboxButton.x,
              car.buttonBitmap & 0x04 != 0, car)),

          // A - 右（绿色，Xbox A 键为绿色）
          Positioned(right: 0,
            child: _buildAbxyBtn('A', XboxButton.a,
              car.buttonBitmap & 0x01 != 0, car)),

          // B - 下（红色）
          Positioned(bottom: 0,
            child: _buildAbxyBtn('B', XboxButton.b,
              car.buttonBitmap & 0x02 != 0, car)),

          // 中央：View + Menu
          Column(mainAxisSize: MainAxisSize.min, children: [
            _buildCenterBtn(Icons.developer_board, Colors.grey,
              () => setState(() => _showLog = !_showLog)),
            SizedBox(height: 6),
            _buildCenterBtn(Icons.menu, Colors.grey,
              () { car.buttonPress(XboxButton.start); }),
          ]),
        ]),
      ),
      SizedBox(height: 4),
      Text('ABXY / Start', style: TextStyle(color: Color(0xFF555555), fontSize: 11)),
    ]);
  }

  /// ABXY 单个按钮
  /// Xbox 标准配色：A=绿 B=红 X=蓝 Y=黄
  Widget _buildAbxyBtn(String label, XboxButton btn, bool isPressed, CarManager car) {
    Color borderColor;
    Color bgColor;
    Color textColor;

    switch (label) {
      case 'A':
        borderColor = Color(0xFF107C10);
        bgColor = isPressed ? Color(0xFF107C10) : Color(0xFF1A1A1A);
        textColor = isPressed ? Colors.white : Color(0xFF107C10);
        break;
      case 'B':
        borderColor = Color(0xFFE81123);
        bgColor = isPressed ? Color(0xFFE81123) : Color(0xFF1A1A1A);
        textColor = isPressed ? Colors.white : Color(0xFFE81123);
        break;
      case 'X':
        borderColor = Color(0xFF0078D4);
        bgColor = isPressed ? Color(0xFF0078D4) : Color(0xFF1A1A1A);
        textColor = isPressed ? Colors.white : Color(0xFF0078D4);
        break;
      case 'Y':
        borderColor = Color(0xFFFFB900);
        bgColor = isPressed ? Color(0xFFFFB900) : Color(0xFF1A1A1A);
        textColor = isPressed ? Colors.black : Color(0xFFFFB900);
        break;
      default:
        borderColor = Colors.grey;
        bgColor = Color(0xFF1A1A1A);
        textColor = Colors.grey;
    }

    return GestureDetector(
      onTapDown: (_) { car.buttonPress(btn); setState(() {}); },
      onTapUp: (_) { car.buttonRelease(btn); setState(() {}); },
      onTapCancel: () { car.buttonRelease(btn); setState(() {}); },
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 2.5),
          boxShadow: isPressed ? [] : [BoxShadow(color: borderColor.withOpacity(0.3), blurRadius: 6)],
        ),
        child: Center(child: Text(label,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18))),
      ),
    );
  }

  /// 中央小按钮（View / Menu）
  Widget _buildCenterBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Color(0xFF3A3A3A)),
        ),
        child: Icon(icon, color: color, size: 16),
      ),
    );
  }

  // ========================================================
  // 扳机键（LT / RT）
  // ========================================================
  Widget _buildTrigger(String label, int value, VoidCallback onDown, VoidCallback onUp, bool lightOn) {
    final isPressed = value >= 50;
    return Column(children: [
      GestureDetector(
        onTapDown: (_) => onDown(),
        onTapUp: (_) => onUp(),
        onTapCancel: onUp,
        child: Container(
          width: 58, height: 58,
          decoration: BoxDecoration(
            color: isPressed ? Color(0xFF107C10) : Color(0xFF1C1C1C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPressed ? Color(0xFF107C10) : Color(0xFF2E2E2E), width: 2),
            boxShadow: isPressed ? [BoxShadow(color: Color(0xFF107C10).withOpacity(0.4), blurRadius: 8)] : [],
          ),
          child: Center(child: Text(label,
            style: TextStyle(
              color: isPressed ? Colors.white : Color(0xFF666666),
              fontWeight: FontWeight.bold, fontSize: 16))),
        ),
      ),
      // 灯指示点
      if (lightOn)
        Container(
          margin: EdgeInsets.only(top: 4), width: 6, height: 6,
          decoration: BoxDecoration(
            color: Color(0xFFFFB900), shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Color(0xFFFFB900).withOpacity(0.8), blurRadius: 4)],
          ),
        ),
    ]);
  }

  // ========================================================
  // 肩键（LB / RB）
  // ========================================================
  Widget _buildBumper(String label, bool isPressed, VoidCallback onDown, VoidCallback onUp) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      child: Container(
        width: 56, height: 28,
        decoration: BoxDecoration(
          color: isPressed ? Color(0xFF107C10) : Color(0xFF1C1C1C),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isPressed ? Color(0xFF107C10) : Color(0xFF2E2D2E), width: 2),
        ),
        child: Center(child: Text(label,
          style: TextStyle(
            color: isPressed ? Colors.white : Color(0xFF555555),
            fontWeight: FontWeight.bold, fontSize: 13))),
      ),
    );
  }

  // ========================================================
  // 中央状态指示器
  // ========================================================
  Widget _buildStatusHub(CarManager car) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Color(0xFF1C1C1C),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF2E2E2E)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.highlight, size: 14,
          color: car.frontLight ? Color(0xFFFFB900) : Color(0xFF3A3A3A)),
        SizedBox(width: 8),
        Text(
          '${car.stickX.abs() > car.stickY.abs() ? car.stickX : car.stickY}',
          style: TextStyle(color: Color(0xFF107C10), fontWeight: FontWeight.bold, fontSize: 13)),
        SizedBox(width: 8),
        Icon(Icons.lightbulb_outline, size: 14,
          color: car.rearLight ? Color(0xFFE81123) : Color(0xFF3A3A3A)),
      ]),
    );
  }

  // ========================================================
  // 底部 HEX 输入
  // ========================================================
  Widget _buildBottomBar(CarManager car) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        color: Color(0xFF141414),
        border: Border(top: BorderSide(color: Color(0xFF1F1F1F))),
      ),
      child: Row(children: [
        Expanded(child: TextField(
          controller: _hexCtrl,
          style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
          decoration: InputDecoration(
            hintText: 'HEX指令如: FF 64 00 00 00 00',
            hintStyle: TextStyle(color: Color(0xFF444444), fontSize: 12),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 10),
          ),
        )),
        GestureDetector(
          onTap: () {
            if (_hexCtrl.text.isNotEmpty) {
              car.sendCustom(_hexCtrl.text);
              _hexCtrl.clear();
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFF107C10),
              borderRadius: BorderRadius.circular(8)),
            child: Text('发送', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ),
      ]),
    );
  }

  // ========================================================
  // 日志页
  // ========================================================
  Widget _buildLog(CarManager car) {
    return Column(children: [
      Container(
        color: Color(0xFF1F1F1F),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(children: [
          Text('通信日志', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          Spacer(),
          GestureDetector(
            onTap: () { car.logs.clear(); car.notifyListeners(); },
            child: Text('清除', style: TextStyle(color: Color(0xFF107C10))),
          ),
        ]),
      ),
      Expanded(child: car.logs.isEmpty
        ? Center(child: Text('暂无日志', style: TextStyle(color: Colors.grey)))
        : ListView.builder(
          padding: EdgeInsets.all(12),
          itemCount: car.logs.length,
          itemBuilder: (ctx, i) => Container(
            margin: EdgeInsets.only(bottom: 4),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(6)),
            child: Text(car.logs[i],
              style: TextStyle(color: Color(0xFF107C10), fontSize: 12, fontFamily: 'monospace')),
          ),
        )),
    ]);
  }
}
