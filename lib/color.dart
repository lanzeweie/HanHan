import 'package:flutter/material.dart';

MaterialColor darkColor_AppBar_zhu = MaterialColor(
  0xFFE57373, // 亮模式颜色代码
  <int, Color>{
    50: Color(0xFFFFEBEE),
    100: Color(0xFFFFCDD2),
    200: Color(0xFFEF9A9A),
    300: Color(0xFFE57373),
    400: Color(0xFFEF5350),
    500: Color(0xFFF44336),
    600: Color(0xFFE53935),
    700: Color(0xFFD32F2F),
    800: Color(0xFFC62828),
    900: Color(0xFFB71C1C),
  },
);
MaterialColor lightColor_AppBar_zhu = MaterialColor(
    0xFFF6EDEE,
    <int, Color>{
        50: Color(0xFFFDF7F8),
        100: Color(0xFFFCECF0),
        200: Color(0xFFFAE4E8),
        300: Color(0xFFF8DCE0),
        400: Color(0xFFF6D4D8),
        500: Color(0xFFF4CCD0),
        600: Color(0xFFF3C4C8),
        700: Color(0xFFF1BABC),
        800: Color(0xFFEFB2B4),
        900: Color(0xFFEDAAA8),
    },
);
class AppColors {
  //全面屏手势 底栏颜色
  static Color colorConfigSystemChrome(bool isDarkMode_force, bool isDarkMode) {
    return isDarkMode_force ? Color.fromARGB(255, 34, 34, 34) : (isDarkMode ? Color.fromARGB(255, 34, 34, 34) : Color.fromARGB(255, 254, 254, 254));
  }
  //文字颜色
  static Color colorConfigText(bool isDarkMode_force, bool isDarkMode) {
    return isDarkMode_force ? Colors.white : (isDarkMode ? Colors.white : Colors.black);
  }
  //框架颜色
  static Color colorConfigKuangJia(bool isDarkMode_force, bool isDarkMode) {
    return isDarkMode_force ? Colors.black : (isDarkMode ? Colors.black : Colors.white.withOpacity(0.8));
  }
  //箭头颜色
  static Color colorConfigJianTou(bool isDarkMode_force, bool isDarkMode) {
    return isDarkMode_force ? Colors.white : (isDarkMode ? Colors.white : Colors.black);
  }
  //输入框的文字 zhu.dart 界面
  static Color colorConfigTextShuruku(bool isDarkMode_force, bool isDarkMode) {
    return isDarkMode_force ? Colors.white : (isDarkMode ? Colors.white : Colors.black);
  }
  //输入框底色 zhu.dart 界面
  static Color colorConfigShurukuKuang(bool isDarkMode_force, bool isDarkMode) {
    return isDarkMode_force ? Color.fromARGB(255, 133, 141, 143) : (isDarkMode ? Color.fromARGB(255, 133, 141, 143) : Colors.white);
  }
  //底部通知框 zhu.dart 背景
  static Color colorConfigTongzhikuang(bool isDarkMode_force, bool isDarkMode) {
    return isDarkMode_force ? Color.fromARGB(255, 84, 93, 94) : (isDarkMode ? Color.fromARGB(255, 84, 93, 94) : Color.fromARGB(255, 52, 58, 59));
  }
  //底部通知框 zhu.dart 文字
  static Color colorConfigTongzhikuangWenzi(bool isDarkMode_force, bool isDarkMode) {
    return isDarkMode_force ? Colors.white : (isDarkMode ? Colors.white : Colors.white);
  }
  //设置标题 Setconfig.dart 文字
  static Color colorConfigSettilte(bool isDarkMode_force, bool isDarkMode) {
    return isDarkMode_force ? Colors.white : (isDarkMode ? Colors.white : Color.fromARGB(255, 68, 63, 63));
  }
  //设置文本 Setconfig.dart 文字
  static Color colorConfigSettilteText(bool isDarkMode_force, bool isDarkMode) {
    return isDarkMode_force ? Color.fromARGB(255, 235, 233, 233) : (isDarkMode ? Color.fromARGB(255, 235, 233, 233) : Color.fromARGB(255, 115, 115, 115));
  }
  //图标颜色 Setconfig.dart
  static Color colorConfigIcon(bool isDarkMode_force, bool isDarkMode) {
    return isDarkMode_force ? Colors.white : (isDarkMode ? Colors.white : Color.fromARGB(255, 75, 69, 70));
  }
  // 卡片颜色 Setconfig.dart
  static Color colorConfigCard(bool isDarkMode_force, bool isDarkMode) {
    if (isDarkMode_force) {
      return Colors.grey[850]!; // 深灰色，避免使用黑色
    } else {
      return isDarkMode
          ? Colors.grey[850] ?? Colors.grey[800]! // 深灰色
          : Colors.white.withOpacity(0.9); // 更柔和的白色
    }
  }
}