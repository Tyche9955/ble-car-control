# BLE 小车控制 APP - Xbox 版

基于 Flutter 的 Xbox 风格 BLE 小车遥控应用。

## 功能
- Xbox 手柄布局：ABXY / LT RT / LB RB / 左摇杆
- BLE 扫描连接，支持 Nordic UART / HM-10 / HC-08
- 紧急停止、HEX 自定义指令、通信日志

## Xbox 协议（6字节）
`[0xFF, 摇杆X, 摇杆Y, 按键Bitmap, LT, RT]`

| 按键 | Bitmap | 功能 |
|------|--------|------|
| A | 0x01 | 前进 |
| B | 0x02 | 后退 |
| X | 0x04 | 左转 |
| Y | 0x08 | 右转 |
| LB | 0x10 | 前灯 |
| RB | 0x20 | 后灯 |
| Start | 0x40 | 蜂鸣器 |

## 构建
```bash
flutter pub get
flutter build apk --debug
```
