import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ProviderHanAll.dart';

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
  // 背景色
  static Color colorBackgroundcolor(BuildContext context) {
    final provider = Provider.of<ProviderHANHANALL>(context, listen: false);
    return provider.isDarkMode ? Color.fromARGB(255, 20, 17, 24) : Color.fromARGB(255, 242, 239, 239);
  }
  //全面屏手势 底栏颜色
  static Color colorConfigSystemChrome(BuildContext context) {
    final provider = Provider.of<ProviderHANHANALL>(context, listen: false);
    return provider.isDarkMode ? Color.fromARGB(255, 34, 34, 34) : Color.fromARGB(255, 254, 254, 254);
  }
  //文字颜色
  static Color colorConfigText(BuildContext context) {
    final provider = Provider.of<ProviderHANHANALL>(context, listen: true);
    return provider.isDarkMode ? Colors.white : Colors.black;
  }
  //框架颜色
  static Color colorConfigKuangJia(BuildContext context) {
    final provider = Provider.of<ProviderHANHANALL>(context, listen: false);
    
    // 判断是否启用框架强制色
    if (provider.isForceFrameColor ?? false) {
      return AppColors.commandApiElement(context, hueShift: 10, saturationBoost: 1);
    }
    
    return provider.isDarkMode ? Colors.black : Colors.white.withOpacity(0.8);
  }
  //箭头颜色
  static Color colorConfigJianTou(BuildContext context) {
    final provider = Provider.of<ProviderHANHANALL>(context, listen: false);
    return provider.isDarkMode ? Colors.white : Colors.black;
  }
  //输入框的文字 zhu.dart 界面
  static Color colorConfigTextShuruku(bool isDarkMode_force, bool isDarkMode) {
    return isDarkMode_force || isDarkMode ? Colors.white : Colors.black;
  }
  //输入框底色 zhu.dart 界面
  static Color colorConfigShurukuKuang(bool isDarkMode_force, bool isDarkMode) {
    return isDarkMode_force || isDarkMode ? Color.fromARGB(255, 133, 141, 143) : Colors.white;
  }
  //底部通知框 zhu.dart 背景
  static Color colorConfigTongzhikuang(bool isDarkMode_force, bool isDarkMode) {
    return isDarkMode_force || isDarkMode ? Color.fromARGB(255, 84, 93, 94) : Color.fromARGB(255, 52, 58, 59);
  }
  //底部通知框 zhu.dart 文字
  static Color colorConfigTongzhikuangWenzi(bool isDarkMode_force, bool isDarkMode) {
    return Colors.white;
  }
  //设置标题 Setconfig.dart 文字
  static Color colorConfigSettilte(bool isDarkMode_force, bool isDarkMode) {
    return isDarkMode_force || isDarkMode ? Colors.white : Color.fromARGB(255, 68, 63, 63);
  }
  //设置文本 Setconfig.dart 文字
  static Color colorConfigSettilteText(bool isDarkMode_force, bool isDarkMode) {
    return isDarkMode_force || isDarkMode ? Color.fromARGB(255, 235, 233, 233) : Color.fromARGB(255, 115, 115, 115);
  }
  //图标颜色 Setconfig.dart
  static Color colorConfigIcon(bool isDarkMode_force, bool isDarkMode) {
    return isDarkMode_force || isDarkMode ? Colors.white : Color.fromARGB(255, 75, 69, 70);
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
  // zhu.dart 卡片的边框颜色
  static Color colorConfigCardBorder(BuildContext context) {
    final provider = Provider.of<ProviderHANHANALL>(context, listen: false);
    
    // 判断当前是否为深色模式（强制深色模式优先）
    final bool isDarkMode = provider.isDarkModeForce || provider.isDarkMode;
    
    // 根据边框强制色开关状态返回不同的颜色
    if (provider.isForceBorderColor ?? false) {
      // 如果开启了边框强制色，返回动态颜色
      return isDarkMode 
          ? AppColors.commandApiElement(context, hueShift: 10, saturationBoost: 1)        // 深色模式：动态边框
          : AppColors.commandApiElement(context, hueShift: 10, saturationBoost: 1) ?? AppColors.commandApiElement(context, hueShift: 10, saturationBoost: 1)!;  // 浅色模式：动态边框
    } else {
      // 如果关闭了边框强制色，返回固定颜色
      return isDarkMode 
          ? const Color.fromARGB(255, 149, 147, 147)        // 深色模式：固定灰色边框
          : const Color.fromARGB(255, 214, 205, 205) ?? const Color.fromARGB(255, 231, 229, 229)!;  // 浅色模式：淡灰色边框
    }
  }

  // 设置界面 _buildSwitchGroups 底色
  static Color colorConfigSwitchGroupBackground(BuildContext context) {
    final provider = Provider.of<ProviderHANHANALL>(context, listen: false);
    final bool isDarkMode = provider.isDarkModeForce || provider.isDarkMode;
    
    return isDarkMode 
        ? Color.fromARGB(255, 41, 41, 42).withOpacity(0.6)  // 深色模式下的底色
        : Color.fromARGB(255, 255, 255, 255).withOpacity(0.7);  // 浅色模式下的底色
  }

  // 统一子元素颜色配置
  static Color? _subElementColor;
  
  static Future<void> initColor() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('subElementColor')) {
      _subElementColor = Color(prefs.getInt('subElementColor')!);
    }
  }

  static Color sliderActiveColor(BuildContext context) {
    final provider = Provider.of<ProviderHANHANALL>(context, listen: false);
    return provider.subElementColor ?? (provider.isDarkModeForce 
      ? Colors.blue[300]! 
      : (provider.isDarkMode ? Colors.blue[200]! : Colors.blueAccent));
  }

  static Color sliderInactiveColor(BuildContext context) {
    final provider = Provider.of<ProviderHANHANALL>(context, listen: false);
    return (provider.subElementColor ?? (provider.isDarkModeForce 
      ? Colors.grey[600]! 
      : (provider.isDarkMode ? Colors.grey[500]! : Colors.grey[300]!))).withOpacity(0.5);
  }

  static Color sliderThumbColor(BuildContext context) {
    final provider = Provider.of<ProviderHANHANALL>(context, listen: false);
    return provider.subElementColor?.withOpacity(0.8) ?? (provider.isDarkModeForce 
      ? Colors.white 
      : (provider.isDarkMode ? Colors.white : Colors.blue[800]!));
  }

  static Future<void> updateSubElementColor(Color color) async {
    _subElementColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('subElementColor', color.value);
  }

  // 统一子元素颜色，并且可选带参数微调颜色
  static Color commandApiElement(BuildContext context, { 
    double hueShift = 0, 
    double saturationBoost = 0 
  }) {
    final provider = Provider.of<ProviderHANHANALL>(context, listen: false);
    final base = provider.subElementColor ?? _defaultColor(provider);
    
    // 提取RGB通道
    final r = (base.value >> 16) & 0xFF;
    final g = (base.value >> 8) & 0xFF;
    final b = base.value & 0xFF;

    // RGB转HSL
    final hsl = () {
      final rd = r / 255, gd = g / 255, bd = b / 255;
      final cmax = [rd, gd, bd].reduce((a, b) => a > b ? a : b);
      final cmin = [rd, gd, bd].reduce((a, b) => a < b ? a : b);
      final delta = cmax - cmin;
      
      double h = 0, s = delta == 0 ? 0 : delta / (1 - (2 * (cmax + cmin)/2 - 1).abs());
      if (delta > 0) {
        if (cmax == rd) h = ((gd - bd) / delta) % 6;
        else if (cmax == gd) h = (bd - rd) / delta + 2;
        else h = (rd - gd) / delta + 4;
        h = (h * 60 + 360) % 360; // 转换为0-360°
      }
      return [h, s.clamp(0, 1), (cmax + cmin)/2];
    }();

    // 调整色相和饱和度
    final newHue = (hsl[0] + hueShift) % 360;
    final newSat = (hsl[1] + saturationBoost).clamp(0, 1);

    // HSL转RGB
    final c = (1 - (2 * hsl[2] - 1).abs()) * newSat;
    final x = c * (1 - ((newHue / 60) % 2 - 1).abs());
    final m = hsl[2] - c / 2;
    
    final (rNew, gNew, bNew) = newHue < 60  ? (c, x, 0) : 
      newHue < 120 ? (x, c, 0) :
      newHue < 180 ? (0, c, x) :
      newHue < 240 ? (0, x, c) :
      newHue < 300 ? (x, 0, c) : (c, 0, x);

    return Color.fromARGB(255, 
      ((rNew + m) * 255).round().clamp(0, 255),
      ((gNew + m) * 255).round().clamp(0, 255),
      ((bNew + m) * 255).round().clamp(0, 255)
    );
  }

  static Color _defaultColor(ProviderHANHANALL p) => p.isDarkModeForce 
    ? Colors.teal[300]! 
    : p.isDarkMode ? Colors.teal[200]! : Colors.teal;


  // 对话框文字颜色
  static Color dialogTextColor(BuildContext context) {
    final provider = Provider.of<ProviderHANHANALL>(context, listen: false);
    return provider.isDarkModeForce ? Colors.white70 
      : (provider.isDarkMode ? Colors.white70 : Colors.black87);
  }
  // 第一次启动的界面文字颜色 底部
  static const Color onboarding = Color.fromARGB(255, 117, 224, 181);  // 主蓝
  static const Color onboardingLight = Color.fromARGB(255, 184, 232, 213); // 浅蓝（用于非活跃点）
}
