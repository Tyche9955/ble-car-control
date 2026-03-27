import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'car_manager.dart';

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});
  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  bool _showLog = false;
  final _hexCtrl = TextEditingController();

  @override
  void dispose() {
    _hexCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final car = context.watch<CarManager>();
    return Scaffold(
      backgroundColor: Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Color(0xFF16213E),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size:18, color:Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              car.device != null
                ? (car.device!.localName.isEmpty ? car.device!.remoteId.str : car.device!.localName)
                : '\u5c0f\u8f66\u63a7\u5236',
              style: TextStyle(color:Colors.white, fontWeight:FontWeight.w600, fontSize:16),
            ),
            Row(children:[
              Container(width:6, height:6, decoration: BoxDecoration(color:Color(0xFF4CAF50), shape:BoxShape.circle)),
              SizedBox(width:4),
              Text(car.txChar != null ? '\u5df2\u5c31\u7eea' : '\u81ea\u52a8\u6a21\u5f0f',
                style: TextStyle(color:Color(0xFF4CAF50), fontSize:11)),
            ]),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_showLog ? Icons.gamepad : Icons.article,
              color: _showLog ? Color(0xFFE94560) : Colors.white),
            onPressed: () => setState(() => _showLog = !_showLog),
          ),
          TextButton(
            onPressed: () { car.disconnect(); Navigator.pop(context); },
            child: Text('\u65ad\u5f00', style: TextStyle(color:Color(0xFFF44336))),
          ),
        ],
      ),
      body: _showLog ? _buildLog(car) : _buildControl(car),
    );
  }

  Widget _buildControl(CarManager car) {
    return Column(children:[
      SizedBox(height:16),
      Container(
        margin: EdgeInsets.symmetric(horizontal:20),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color:Color(0xFF16213E), borderRadius:BorderRadius.circular(16)),
        child: Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
          Row(children:[
            Icon(Icons.speed, color:Color(0xFFE94560), size:18),
            SizedBox(width:8),
            Text('\u901f\u5ea6', style: TextStyle(color:Colors.white, fontWeight:FontWeight.w600)),
            Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal:12, vertical:4),
              decoration: BoxDecoration(color:Color(0xFFE94560), borderRadius:BorderRadius.circular(20)),
              child: Text(car.speed.toString() + '%',
                style: TextStyle(color:Colors.white, fontWeight:FontWeight.bold)),
            ),
          ]),
          SizedBox(height:8),
          Slider(
            value: car.speed.toDouble(),
            min: 0, max: 100, divisions: 20,
            activeColor: Color(0xFFE94560),
            inactiveColor: Colors.grey.shade800,
            onChanged: (v) => car.setSpeed(v.toInt()),
          ),
        ]),
      ),
      SizedBox(height:20),
      Center(child: Column(children:[
        _dirBtn(Direction.forward, Icons.arrow_upward, '\u524d\u8fdb', car),
        SizedBox(height:8),
        Row(mainAxisAlignment:MainAxisAlignment.center, children:[
          _dirBtn(Direction.left, Icons.turn_left, '\u5de6', car),
          SizedBox(width:8),
          _stopBtn(car),
          SizedBox(width:8),
          _dirBtn(Direction.right, Icons.turn_right, '\u53f3', car),
        ]),
        SizedBox(height:8),
        _dirBtn(Direction.backward, Icons.arrow_downward, '\u540e\u9000', car),
      ])),
      SizedBox(height:20),
      Padding(
        padding: EdgeInsets.symmetric(horizontal:20),
        child: Row(children:[
          _funcBtn(Icons.highlight, '\u706f\u5149',
            car.led == LedState.on ? Color(0xFFFFEB3B) : Colors.grey.shade700,
            () => car.toggleLed()),
          SizedBox(width:10),
          _funcBtn(Icons.volume_up, '\u8702\u54cd', Colors.grey.shade700,
            () => car.sendBuzzer()),
        ]),
      ),
      Spacer(),
      Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(color:Color(0xFF16213E), borderRadius:BorderRadius.circular(12)),
        child: Row(children:[
          Expanded(child: TextField(
            controller: _hexCtrl,
            style: TextStyle(color:Colors.white, fontFamily:'monospace'),
            decoration: InputDecoration(
              hintText: 'HEX\u6307\u4ee4\u5982: 01 64',
              hintStyle: TextStyle(color:Colors.grey),
              border: InputBorder.none,
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
              padding: EdgeInsets.symmetric(horizontal:16, vertical:8),
              decoration: BoxDecoration(color:Color(0xFFE94560), borderRadius:BorderRadius.circular(8)),
              child: Text('\u53d1\u9001', style: TextStyle(color:Colors.white, fontWeight:FontWeight.bold)),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _stopBtn(CarManager car) {
    return GestureDetector(
      onTapDown: (_) => car.stop(),
      child: Container(
        width:72, height:72,
        decoration: BoxDecoration(
          color: Color(0xFF0F3460),
          shape: BoxShape.circle,
          border: Border.all(color:Colors.grey.shade700, width:2),
        ),
        child: Icon(Icons.stop, color:Colors.white, size:36),
      ),
    );
  }

  Widget _dirBtn(Direction dir, IconData icon, String label, CarManager car) {
    return GestureDetector(
      onTapDown: (_) => car.sendDirection(dir),
      onTapUp: (_) => car.stop(),
      onTapCancel: () => car.stop(),
      child: Container(
        width:72, height:72,
        decoration: BoxDecoration(
          color: Color(0xFF0F3460),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color:Colors.grey.shade700, width:2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color:Colors.grey.shade400, size:28),
            SizedBox(height:2),
            Text(label, style: TextStyle(color:Colors.grey.shade400, fontSize:11)),
          ],
        ),
      ),
    );
  }

  Widget _funcBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical:12),
          decoration: BoxDecoration(color:Color(0xFF16213E), borderRadius:BorderRadius.circular(12)),
          child: Column(children:[
            Icon(icon, color:color, size:24),
            SizedBox(height:4),
            Text(label, style: TextStyle(color:color, fontSize:12)),
          ]),
        ),
      ),
    );
  }

  Widget _buildLog(CarManager car) {
    return Column(children:[
      Container(
        color: Color(0xFF16213E),
        padding: EdgeInsets.symmetric(horizontal:16, vertical:8),
        child: Row(children:[
          Text('\u901a\u4fe1\u65e5\u5fd7', style: TextStyle(color:Colors.white, fontWeight:FontWeight.w600)),
          Spacer(),
          GestureDetector(
            onTap: () => car.logs.clear(),
            child: Text('\u6e05\u9664', style: TextStyle(color:Color(0xFFE94560))),
          ),
        ]),
      ),
      Expanded(child: car.logs.isEmpty
        ? Center(child: Text('\u6682\u65e0\u65e5\u5fd7', style: TextStyle(color:Colors.grey)))
        : ListView.builder(
          padding: EdgeInsets.all(12),
          itemCount: car.logs.length,
          itemBuilder: (ctx, i) => Container(
            margin: EdgeInsets.only(bottom:4),
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color:Color(0xFF16213E), borderRadius:BorderRadius.circular(6)),
            child: Text(car.logs[i],
              style: TextStyle(color:Color(0xFF4CAF50), fontSize:12, fontFamily:'monospace')),
          ),
        )),
    ]);
  }
}
